---
title:  "TPM Carte Blanche-resistant Boot Attestation"
description: "Some tips for verifiers"
permalink: /tcb-attestation
---

![tcb-demo](/images/2021-10-25-tcb-attestation.svg)

<!--more-->

As I mentioned [last week](/tpm-carte-blanche), your TCB is important and
without a good one, your capabilities are quite limited when it comes to
attestation.

So, all right, we now live in a world where we know bugs like
[TPM Carte Blanche](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-42299)
exist, and we can never go back to the world where it doesn't. (Actually, we've
been living in that world since
[2014](https://en.wikipedia.org/wiki/Surface_Pro_3).) So what do we do now?

The best thing to do is probably to find a hardware
[Root of Trust for Measurement](https://www.ieee802.org/1/files/public/docs2004/af-congdon-tcg-overview-1104.pdf).
Your CPU vendor may have some ideas, but a non-exhaustive list probably doesn't
leave out
[Boot Guard](https://www.ieee802.org/1/files/public/docs2004/af-congdon-tcg-overview-1104.pdf)
or [Platform Secure Boot](https://www.amd.com/en/technologies/pro-security).

What about the millions of devices out there in the world today that don't have
a hardware RTM? Well, it turns out TPM 2.0 has some uncommonly-used features
that can come in handy here.

TPM 2.0 has a feature called audit sessions, which you can read about in Part
1 of [the TPM 2.0 specification](https://trustedcomputinggroup.org/resource/tpm-library-specification/).
Audit sessions serve two purposes:

* An audit session with a session key (set up by "salting" or "binding" the
session) causes the TPM to use that key to calculate an HMAC over its response.
* An audit session digest can be explicitly attested by an Attestation Key for
consumption by remote verifiers, using a command called
`TPM2_GetSessionAuditDigest`.

When you set up an audit session, it gets initialized with an "empty digest"
(a buffer of all `0x00` bytes the size of the session hash algorithm like a
PCR). Each time you send a command in the audit session, the session is
extended:

$$commandParameterHash = hash(\hspace{0.5em}commandCode\hspace{0.5em}\| \hspace{0.5em}names\hspace{0.5em} \| \hspace{0.5em}commandParams\hspace{0.5em})$$

where $$commandCode$$ is the command code constant associated with the command,
$$names$$ is the concatenation of all authorized TPM Names (TPM object
unique identifiers; hash of public area or primary seed handle value) used in
the command, and $$commandParams$$ is the concatenation of all the command
parameters.

$$responseParamHash = hash(\hspace{0.5em}responseCode\hspace{0.5em} \| \hspace{0.5em}commandCode\hspace{0.5em} \| \hspace{0.5em}responseParams\hspace{0.5em})$$

where $$responseCode$$ is a `TPM_RC` value and $$responseParams$$ is the
concatenation of all the response parameters.

$$digest_{new} = hash(\hspace{0.5em}digest_{old}\hspace{0.5em} \| \hspace{0.5em}commandParameterHash\hspace{0.5em} \| \hspace{0.5em}responseParameterHash\hspace{0.5em})$$

These formulas can be combined into higher-layer logic that lets a verifier
plug in expected command/response invocations, like in
[this example](https://github.com/chrisfenner/tcb-attestation/blob/ebec77fcfa8531a256f67bd77e2cc5447e07112d/attestation_test.go#L242-L262):

```go
audit := tpm2.NewAudit(tpm2.TPMAlgSHA256)
getCapCmd := tpm2.GetCapabilityCommand{
	Capability:    tpm2.TPMCapPCRs,
	Property:      0,
	PropertyCount: 1,
}
getCapRsp := tpm2.GetCapabilityResponse{
	MoreData: false,
	CapabilityData: tpm2.TPMSCapabilityData{
		Capability: tpm2.TPMCapPCRs,
		Data: tpm2.TPMUCapabilities{
			AssignedPCR: &quote.Attested.Quote.PCRSelect,
		},
	},
}
if err := audit.Extend(&getCapCmd, &getCapRsp); err != nil {
	return err
}
if !bytes.Equal(auditAttest.Attested.SessionAudit.SessionDigest.Buffer, audit.Digest()) {
	return fmt.Errorf("invalid audit digest")
}
```

In the above example, a test verifier checks to make sure that the audited
session proves that the caller called `TPM2_GetCapability(TPM_CAP_PCRS)` and
got back the same set of PCR banks they quoted with `TPM2_Quote` (see
[this](https://github.com/chrisfenner/tcb-attestation/blob/main/attestation_test.go#L212-L225)
part of the same test).

This allows the verifier to establish the following web of trust:

1. The AK is trusted because the caller provided
[an AK certificate](https://github.com/google/security-research/blob/master/pocs/bios/tpm-carte-blanche/writeup.md#appendix-b-reverse-engineering-aik-service).
2. The two things signed by the AK, the PCR quote and session audit digest,
are trusted because the AK is trusted in (1)
3. The `TPML_PCR_SELECTION` quoted in the PCR quote is trusted because the
signed audit log digest trusted in (2) is the digest of the well-known
`TPM2_GetCapability` command with the TPM returning the same PCR selection in
response.
4. The preimage PCR values are trusted because the quote is trusted in (2).
5. The boot log is trusted because when replayed it results in the preimage
PCR values trusted in (4).

Attesting a PCR quote, **along with a reliable signal that there are no other
active PCR banks on the system**, helps defend against BIOS bugs where some of
the PCR banks are left uncapped, by allowing the verifier to either mandate
that every event in the boot log is measured into every PCR bank, or (more
simply) that the device is configured correctly and only using a single PCR
bank (i.e., SHA256). Because there's not actually a good reason to have
some of the software measuring into the SHA1 bank and other software
measuring into the SHA256 bank.

This still leaves open other types of BIOS bugs, for instance a bug where the
SHA384 PCR bank is just never extended even if it is the only active bank.
(BIOS writers: please just us `TPM2_PCR_Event` to make the TPM do all the
hashing and automagically populate every PCR.)

For a more complete example of this type of PCR attestation, please see
[https://github.com/chrisfenner/tcb-attestation](https://github.com/chrisfenner/tcb-attestation).

For more information, see last week's [blog post](/tpm-carte-blanche) about TPM
Carte Blanche.

*Opinions expressed here are my own and do not represent the official positions
of any employer(s) of mine, past or present*
