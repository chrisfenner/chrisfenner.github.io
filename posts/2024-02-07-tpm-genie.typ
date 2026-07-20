The purpose of a system is what it does (#link(<foot:posiwid>, "1")).
The purpose of BitLocker is to generate articles about interposer
attacks.

#image("/images/2024-02-07-tpm-genie.png", width: 60%, height: 60%) <fig:interpose>

#emph[Disclaimer: I work on TPM at
  #link("https://trustedcomputinggroup.org/")[Trusted Computing Group]. As
  always, the views expressed in this blog are my own.]

Every year or so, we see another version
(#link(<foot:genie>, "2")
#link(<foot:trammell>, "3")
#link(<foot:riverloop>, "4")
#link(<foot:dolos>, "5")
#link(<foot:stacksmashing>, "6"))
of a paper called "I Hacked BitLocker in 25 Seconds With This Soldering
Iron and the Power of Friendship".

And every year, I assume a conversation like this occurs in Redmond:

#quote(block: true)[
  "Should we fix BitLocker to deal with this issue?"
]

#quote(block: true)[
  "No, we (picked our threat model 20 years ago|are too afraid of the
  code|sacked the people responsible for that so the execs could get
  bigger bonuses last year)."
]

Invariably, the telephone game that is tech journalism and social media
pollutes the conversation, and people end up asking "why does the TPM
suck so much?" (Answer: It's not the TPM that sucks in this situation).

Security is about solving threat models, not extra credit. People (e.g.,
I) have asked the BitLocker team to update their threat model in the
past. They haven't so far. They probably won't this year, or next time
this topic hits my feed. So I am going to assume that BitLocker will
never change. But here is how a full-disk encryption system like
BitLocker could use the TPM properly. If Microsoft wants to hire an
intern to finally fix BitLocker's threat model some summer, that would
be cool too.

= The Problem
<the-problem>
See the #link(<fig:interpose>)[diagram at the top of the post].

The naive implementation of a system that uses the TPM to unseal a disk
encryption key causes the disk encryption key to appear in-the-clear on
the TPM bus (typically,
#link("https://en.wikipedia.org/wiki/Low_Pin_Count")[LPC] or
#link("https://en.wikipedia.org/wiki/Serial_Peripheral_Interface")[SPI]).
It's not hard to read the 1s and 0s on these wires and convert them back
into data. And nobody assumed that it would be. The TPM may as well be
shouting the BitLocker key back to the CPU.

So, all these papers about breaking BitLocker are really about parsing
LPC or SPI framed TPM commands. There isn't, like, cryptography or
anything happening here.

= The Solution
<the-solution>
So, how can a full-disk encryption product protect itself from
sophisticated attackers with access to a Raspberry Pi?

In terms of applied crypto toolboxes and the threat model, we would say
that we want the host and the TPM to perform some sort of
#link("https://en.wikipedia.org/wiki/Key_exchange")[key establishment]
and then use that key to protect the secrets that have to traverse the
bus.

Since this particular threat model includes a passive interposer who can
read the bus but not modify/drop commands/responses, any type of key
establishment would help here. Let's say that we use
#link("https://en.wikipedia.org/wiki/Key_encapsulation_mechanism")[Key Encapsulation]
as our key-agreement mechanism.

TPM supports TPM-specific RSA and ECC KEMs, designed to allow use of a
restricted decryption key for this use-case, though without using the
term "KEM" as that wasn't popular until NIST's PQC competition despite
being apparently coined in
#link("https://eprint.iacr.org/2001/108.pdf")[2001].

#image("/images/2024-02-07-tpm-genie-solution.png", width: 60%, height: 60%)

= The Work
<the-work>
+ Create a `restricted` ECDH `decrypt` key in the TPM during boot (do
  not use RSA unless you aren't in a hurry to boot).
+ Perform the encapsulation to create an additional encrypt session for
  the unseal command.
+ Decrypt the encrypted response parameter using the key you
  encapsulated in (2).

= The Future
<the-future>
Interested in #strong[active] interposers? Now you're thinking with
interposers. You need some way for the host and the TPM to mutually
authenticate. Check out what my colleagues and I are working on:
#link("https://www.osfc.io/2022/talks/protecting-tpm-commands-from-active-interposers/")

// TODO: Make "real" footnotes work with Typst HTML output.

1: #link("https://en.wikipedia.org/wiki/The_purpose_of_a_system_is_what_it_does") <foot:posiwid>

2: #link("https://research.nccgroup.com/2018/03/09/tpm-genie-interposer-attacks-against-the-trusted-platform-module-serial-bus/") <foot:genie>

3: #link("https://conference.hitb.org/hitbsecconf2019ams/materials/D1T1%20-%20Toctou%20Attacks%20Against%20Secure%20Boot%20-%20Trammell%20Hudson%20&%20Peter%20Bosch.pdf") <foot:trammell>

4: #link("https://riverloopsecurity.com/blog/2021/01/ieee-paine-tpm-lpc-bus-implant/") <foot:riverloop>

5: #link("https://dolosgroup.io/blog/2021/7/9/from-stolen-laptop-to-inside-the-company-network") <foot:dolos>

6: #link("https://www.tomshardware.com/pc-components/cpus/youtuber-breaks-bitlocker-encryption-in-less-than-43-seconds-with-sub-dollar10-raspberry-pi-pico") <foot:stacksmashing>
