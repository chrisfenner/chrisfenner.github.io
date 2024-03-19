---
title:  "Attesting to the TPM's Firmware"
permalink: /attesting-tpm-firmware
---

![a buggy and a fixed TPM](/images/2024-03-18-attestable-tpm.drawio.svg)

[Murphy's Law](https://en.wikipedia.org/wiki/Murphy%27s_law) says: Anything that can go wrong will go wrong.
Unfortunately, TPMs fall into the category of "anything."

<!--more-->

You can usually tell embedded security people apart from not-embedded security people, because the not-embedded
security people will say things like "this is secure because the hardware does it for us" and the embedded
security people will adopt this vacant, dead expression in their eyes when the not-embedded security people
say things like that. Don't get me wrong: the isolation of "doing it in hardware" is **great**, but it doesn't
change the fact that a person had to implement it in the hardware, and people occasionally make mistakes
(just like they do when they implement things in software).
Hardware security vendors work *very very hard* to avoid these mistakes, but "don't ever make any mistakes"
is not a very good strategy for the same reason that people buy fire alarms even though they typically don't
plan on burning down their houses.

Attestation is the continual process of fixing mistakes wherever they are found, and then checking your work.
This is the superpower of a complex system with a hardware root-of-trust (such as a TPM)! Measure whatever you booted
into the root-of-trust (e.g., TPM PCRs) before you boot it, and then get the root-of-trust to provide proof
of those measurements (e.g., TPM PCR quotes). When you roll out an update to part of your system, the updated
software's measurements will be evident in the proof that you got from the root-of-trust.

![TCB and the boot sequence](/images/2024-03-18-measurement-chain.drawio.svg)

What can't be attested? The Trusted Computing Base (TCB) itself. Elements of the TCB (i.e., the Roots of Trust)
must be implicitly trusted because they are not measured (what else would measure them?) This is because of the
definition of the Trusted Computing Base:

**Trusted Computing Base (TCB)**: *The set of components of a system that must be assumed to be trustworthy because there is no way to check them.* [^TCB]

There's about 60K lines of code in the [TPM Reference Implementation](https://github.com/trustedcomputinggroup/tpm).
On top of this, TPM implementations have several subsystems that all contribute to the trustworthiness of a TPM,
for example:

* Clock
* NV (non-volatile memory)
* Cryptographic key generation and operations
* Vendor-specific functionality

TPM vendors usually get it right, but occasionally, mistakes get made [^ROCA] [^TPMfail] [^EK].
When a bug is identified inside the TCB, it should be fixed [^9225]. Since the TCB has to be
assumed to be trustworthy, you have to ask it nicely to update itself and hope it's not trying
to trick you. When your TCB is a Root of Trust inside a lot of remote machines (e.g., a datacenter),
it's hard to have this hope. One attacker on one of the machines might intercept your request,
respond with "OK" (perhaps asserting the identity of the root-of-trust, using secrets it
exflitrated out of it), and then... not update the Root of Trust. As represented in the drawing
at the top of this post, both a buggy and fixed TPM have a valid EK cert. How do we check?

So, we decided to shrink the TCB of the TPM down to just its boot loader:

![TPM TCB](/images/2024-03-18-tpm-tcb.drawio.svg)

The job of the TPM's boot loader is to validate, measure, and start up the TPM's application firmware.
The job of the TPM's application firmware is to do all the things you ask your TPM to do after that.

Note that there is no requirement that a TPM be organized in this particular way. It might have a big
monolithic firmware, or several small firmware bits; the boot loader may be one stage or several. The
key idea here is that the TCB of the TPM should be as small as possible, and be the minimal set of TPM
implementation parts that allow verifying and launching the rest of the TPM.

The latest version of the TPM 2.0 specification, [1.83](https://trustedcomputinggroup.org/resource/tpm-library-specification/), introduces a feature called "Firmware-Limited Objects" that allows us to
shrink the TCB of the TPM in this way.

A TPM implementing Firmware-Limited Objects offers some new hierarchies for use with `TPM2_CreatePrimary`.
If you create an EK using `TPM_RH_ENDORSEMENT` you will get the same EK regardless of TPM firmware
version. This is why updating your TPM doesn't destroy your EK cert. However, now (on TPMs that implement
Firmware-Limited Objects!) you can create a key based on the new `TPM_RH_FW_ENDORSEMENT`, which will *change*
if the TPM's firmware changes (but otherwise stay the same if you don't change the TPM's firmware).
If the TPM provides a Firmware Endorsement Key certificate, it can
include the firmware version in the cert, and the whole (cert + key) will change between different
firmware versions. With the Firmware EK cert, you can attest the TPM after you update it by simply
challenging the EK associated with the firmware version you rolled out.
If this all sounds kind of familiar, it's because it's just
[DICE](https://trustedcomputinggroup.org/work-groups/dice-architectures/) (although the TPM spec
does not require the TPM to use DICE *per se* to implement the firmware-limited hierarchy feature).

If you're not familiar with DICE, that means the TPM will do something like this:

![TPM TCB](/images/2024-03-18-tpm-dice.drawio.svg)

The TPM's boot loader measures the to-be-launched TPM application firmware (e.g., by hash),
then mixes that hash with a secret that it keeps (*BL Secret*) that the application firmware
never gets access to. The resulting derived secret is called the *FW Secret*, and it is mixed
into Primary Keys generated in `TPM_RH_FW_*` hierarchies. This gives us the following nice properties:

* Each firmware version on a given TPM gets a fresh *FW Secret* that no other firmware on that TPM (or any other TPM) has
* Each firmware's *FM Secret* is stable if the firmware is not changed

This shrinks the TPM's TCB to effectively just the TPM's boot loader and the hardware itself: the rest of
the TPM's firmware is measured and can be attested by using firmware-limited keys. Therefore, on
such a TPM, we can recover (remotely and at scale) from ~any conceivable bug in the TPM's application firmware.

What if you want to seal data to the TPM's firmware, and unseal your data later (potentially from
an even newer firmware)? Check out the `TPM_RH_SVN_*` hierarchies in 1.83.

[^TCB]: There are several conflicting definitions of "Trusted Computing Base" in the literature. The other ones tend to predate the invention of hardware Roots of Trust and are not very useful in a discussion of modern systems. I am not taking feedback on this correct opinion at this time.
[^ROCA]: <https://en.wikipedia.org/wiki/ROCA_vulnerability>
[^TPMfail]: <https://tpm.fail>
[^EK]: <https://seclists.org/fulldisclosure/2018/Jan/12>
[^9225]: <https://datatracker.ietf.org/doc/html/rfc9225>