---
title:  "TPM Carte Blanche"
description: "The true TCB of self-measured BIOS"
permalink: /tpm-carte-blanche
---

![tcb-demo](/images/2021-10-18-tcb.webp)

<!--more-->

I like to tinker with the
[TPM](https://trustedcomputinggroup.org/resource/tpm-library-specification/)
in my spare time. It's like a great big box of security legos, or like a
dryer, punk-er form of Minecraft. It's pretty fun.

In 2017 I had the privilege of working on mitigations for an issue called
[ROCA](https://en.wikipedia.org/wiki/ROCA_vulnerability). From then on, I've
been fascinated by the idea of the
[Trusted Computing Base](https://en.wikipedia.org/wiki/Trusted_computing_base).

I believe that [Murphy's Law](https://en.wikipedia.org/wiki/Murphy%27s_law)
applies equally to code as it does to which way buttered toast will fall, or
whether two intersecting clues in the New York Times crossword will be unusual
names of minor celebrities from the 1970's. The meaning of the TCB isn't so
much "your system is safe because of this smart stuff in this box" as it is
"your system is utterly booched ~~if~~ when we find any important mistakes in this
box".

Also, the amount of mistakes we know about in any given box is a monotonically
increasing function of time. Nobody says "good news, we've discovered some
unexpectedly correct behavior in your kernel."

I recently came into the possession of a Surface Pro 3, which is a machine that
I happen to know shipped with TPMs affected by ROCA. I thought "ah, this is my chance
to apply my superficial understanding of finite-field arithmetic to learn some
more about this bug and how it was discovered." So, I installed Linux on it,
`ssh`ed in, and installed some TPM tools. My go-to "hello world" TPM tool is
[`gotpm`](https://github.com/google/go-tpm-tools) and reading the
[PCRs](https://docs.microsoft.com/en-us/windows/security/information-protection/tpm/switch-pcr-banks-on-tpm-2-0-devices)
is a pretty basic TPM activity that lets you know you're talking to a TPM.

So, when I was greeted with these PCRs, I knew that obviously I had made a
mistake, and I was talking to some simulated, shim TPM or something:

```
0: 0000000000000000000000000000000000000000000000000000000000000000
1: 0000000000000000000000000000000000000000000000000000000000000000
2: 0000000000000000000000000000000000000000000000000000000000000000
3: 0000000000000000000000000000000000000000000000000000000000000000
4: 0000000000000000000000000000000000000000000000000000000000000000
5: 0000000000000000000000000000000000000000000000000000000000000000
6: 0000000000000000000000000000000000000000000000000000000000000000
7: 0000000000000000000000000000000000000000000000000000000000000000
8: 0000000000000000000000000000000000000000000000000000000000000000
9: 0000000000000000000000000000000000000000000000000000000000000000
10: 52dafc83858586083a5b09d80f4c75e77180691ee717d30bc07194713d5884b3
11: 0000000000000000000000000000000000000000000000000000000000000000
12: 0000000000000000000000000000000000000000000000000000000000000000
13: 0000000000000000000000000000000000000000000000000000000000000000
14: 0000000000000000000000000000000000000000000000000000000000000000
15: 0000000000000000000000000000000000000000000000000000000000000000
16: 0000000000000000000000000000000000000000000000000000000000000000
17: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
18: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
19: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
20: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
21: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22: ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
23: 0000000000000000000000000000000000000000000000000000000000000000
```

Except I wasn't. This was my real TPM. For a sense of which of these rows of
nonsense are supposed to not all be 0's or f's, see the SHA1 bank:

```
0: 3dcaea25dc86554d94b94aa5bc8f735a49212af8
1: b2a83b0ebf2f8374299a5b2bdfc31ea955ad7236
2: b2a83b0ebf2f8374299a5b2bdfc31ea955ad7236
3: b2a83b0ebf2f8374299a5b2bdfc31ea955ad7236
4: 27b2c869333dbe59c520294ffb652964da78b7ce
5: fe1b29141dcded019fe3423df304b5676c6c58d6
6: b2a83b0ebf2f8374299a5b2bdfc31ea955ad7236
7: 03e7b21f363721d4a04a550602c0742291f735b4
8: c7e3ff980c58cd67bc554519847b585de6b9bd33
9: 6167364dca8c424a2f5b1a9b3df5f121ddcfab4b
10: e13d0ffa292ef1e530005679978a0c5aae8967d3
11: 0000000000000000000000000000000000000000
12: 0000000000000000000000000000000000000000
13: 0000000000000000000000000000000000000000
14: 0000000000000000000000000000000000000000
15: 0000000000000000000000000000000000000000
16: 0000000000000000000000000000000000000000
17: ffffffffffffffffffffffffffffffffffffffff
18: ffffffffffffffffffffffffffffffffffffffff
19: ffffffffffffffffffffffffffffffffffffffff
20: ffffffffffffffffffffffffffffffffffffffff
21: ffffffffffffffffffffffffffffffffffffffff
22: ffffffffffffffffffffffffffffffffffffffff
23: 0000000000000000000000000000000000000000
```

This is pretty bad, because a bank of empty PCRs means an ~~attacker~~ researcher
can just boot up a custom OS that doesn't make any measurements, and use
[simple tools](https://github.com/google/security-research/tree/master/pocs/bios/tpm-carte-blanche/cmd/dhatool)
to extend whatever they want into those PCRs and attest them honestly (from the
TPM's point of view).

So, what prevents this happening normally, on all of the computers all of the
time? Well, theoretically your [BIOS](https://en.wikipedia.org/wiki/BIOS) has
a well-behaved, immutable initial boot block that always makes proper
measurements into the TPM, and whenever it fails to make proper measurements
into the TPM it creates a small wormhole and sucks itself and your
[BitLocker](https://docs.microsoft.com/en-us/windows/security/information-protection/bitlocker/bitlocker-overview)
key into the [Negative Zone](https://en.wikipedia.org/wiki/Negative_Zone) or,
like, North Dakota, or something.

It turns out the code in your initial boot block is more or less like code you
might find elsewhere in your computer, and you should not assume it's better
just because it's more important.

I have three takeaways from working on this project:

1. Building a [measured](https://firmwaresecurity.com/tag/measured-boot/)
and/or
[verified aka Secure](https://superuser.com/questions/1360485/what-is-the-difference-between-secure-boot-and-verified-boot/1361267)
boot attestation system without considering the TCB is like building an ice
sculpture on top of a dumpster full of matches. Like, chock full, to the brim
of matches. And it's in Oklahoma in July. Your plans are neat and also doomed.
2. People who build security frameworks should prefer simplicity over elegance
and flexibility. It's easier not to notice one of the PCR banks hasn't been
[capped](https://trustedcomputinggroup.org/wp-content/uploads/PC-ClientSpecific_Platform_Profile_for_TPM_2p0_Systems_v21.pdf)
by the firmware when there are N banks of them (one per hash algorithm) and all
the software running on the system can interact with whichever bank suits its
delicate, not-crypto-agile preferences. If there were only ever one bank of PCR
active at a time, it would be harder to miss a bug like this. (Note I didn't
say it would be impossible.)
3. The best place for TCB is in the immutable
[ROM](https://en.wikipedia.org/wiki/Read-only_memory) of something that's very
hard to probe, swap, or tamper. Code in ROM should measure/verify "mutable"
code (and by "mutable" I really mean "your threat model shouldn't assume your
adversary can't afford
[one of these](https://www.dediprog.com/category/spi-flash-solution)"). This
step should be as simple as possible, with respect for the fact that if it's
broken you may need to throw away hardware. TCG
[DICE](https://trustedcomputinggroup.org/resource/dice-attestation-architecture/)
is an example of up-and-coming new hotness in this area.

Microsoft's [advisory](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42299)
was published on 2021-10-18.

For more information, see the full writeup at
[google/security-research](https://github.com/google/security-research/blob/master/pocs/bios/tpm-carte-blanche/writeup.md).

*Opinions expressed here are my own and do not represent the official positions
of any employer(s) of mine, past or present*
