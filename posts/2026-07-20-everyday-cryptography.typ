Cryptographers (and Applied Cryptographers) love to define beautiful, robust, complete protocols that solve interesting problems.
And if you get enough Cryptographers (or Applied Cryptographers) into the room, they are gonna define protocols that solve _a lot_ of interesting problems.

And if we're lucky, at least some of those interesting problems will matter to the security of a system someday.

Unfortunately, any cryptographic protocol that solves sufficiently many sufficiently interesting problems will be impossible for mere mortals to use safely.
It will be the #link("https://uxdesign.cc/intro-to-ux-the-norman-door-61f8120b6086")[Norman Door] of cryptographic protocols.

= KEMs <kems>

A nice example of an easy-to-use cryptographic interface is the #link("https://csrc.nist.gov/pubs/sp/800/227/final")[KEM], or Key Encapsulation Mechanism.

#image("/images/2026-07-20-kem.png", alt: "KEM Diagram from FIPS 203", width: 60%, height: 60%)

My favorite diagram of a KEM is from #link("https://csrc.nist.gov/pubs/fips/203/final")[FIPS 203], above.
We can also express the KEM interface as code:

```py
def kem_keygen(seed: bytes, parms: ParameterSet) -> tuple[PublicKey, PrivateKey]:
  # Use eldritch algebra to expand the given random seed into an actual keypair.
  ...
  return (public_key, private_key)

def kem_encaps(pub: PublicKey) -> tuple[SharedSecret, Ciphertext]:
  # Generate a random shared secret and the ciphertext that encapsulates it.
  # Optionally, a test-only "derandomized" version of this function might exist,
  # e.g., for Wycheproof test cases.
  ...
  return (ss, ct)

def kem_decaps(priv: PrivateKey, ct: Ciphertext) -> SharedSecret:
  # Decapsulate the ciphertext to get the shared secret inside.
  ...
  return ss
```

As a prospective user of this interface, it's easy enough for me to tell that I'm supposed to use `kem_keygen` to generate my key, and then I can use the public key with `kem_encaps` and the private key with `kem_decaps`.
Inspecting the inputs to these functions, I'm faced with the following questions:
- What kind of `seed` do I need?
- Which `parms` should I use?
- What should I do with my `SharedSecret`?

For a given algorithm (e.g., #link("https://csrc.nist.gov/pubs/fips/203/final")[ML-KEM]) the first two are questions with few answers. ML-KEM, for example, takes a 64-byte seed `d || z` and there are 3 parameter sets targeting different security strengths.

The third question is not supposed to be answered by your KEM, but by your symmetric crypto primitive (not pictured).

Note that I don't have to choose any inputs to `kem_encaps` or `kem_decaps`.
Those functions only take things that were provided to me by the other functions.
For folks familiar with RSA encryption or IES, it might be a bit of a culture shock that you don't get to decide *what* gets encrypted.
But this is liberating. You don't have to worry about what happens if you encrypt a low-entropy value because you don't get to pick the value at all.
Instead, you are given a `SharedSecret` to plug into your authenticated encryption primitive of choice.

Also note that every input and output is of a type with some bounded maximum size (e.g., the maximum size of `PublicKey` for ML-KEM is 1568).

Seems pretty easy. Let's look at a less-nice situation: modern digital signatures.

= Signatures <signatures>

The big snake pit you have to jump over when trying to use a modern digital signature is *pre-hashing*.

#quote(
  block: true,
  attribution: link("https://keymaterial.net/2026/05/13/so-you-want-to-deploy-fn-dsa")[Sophie Schmieg],
)[
  Prehashing is a very strange topic. Half of the cryptographic community insists that it’s absolutely essential, while the other half has never heard of it. Usually the half that has never heard of it is theoretical cryptographers.
]

For even more wisdom: see Sophie's excellent write-up #link("https://keymaterial.net/2024/11/05/hashml-dsa-considered-harmful/")["HashML-DSA considered harmful"].

The prehashing question becomes additional variety (in the #link("https://en.wikipedia.org/wiki/Variety_(cybernetics)")[cybernetics sense]) that must be handled be additional variety at the interface level.

We can create `pure` and `prehash` variants of the `sign` and `verify` functions.

```py
def dsa_keygen(seed: bytes, parms: ParameterSet) -> tuple[PublicKey, PrivateKey]:
  # Use eldritch algebra to expand the given random seed into an actual keypair.
  ...
  return (pub, priv)

def dsa_sign_pure(priv: PrivateKey, ctx: bytes, msg: bytes) -> Signature:
  # Computes the pure signature over the context and message using the key.
  # Optionally, a test-only "derandomized" version of this function might exist,
  # e.g., for Wycheproof test cases.
  ...
  return sig

def dsa_sign_prehash(priv: PrivateKey, ctx: bytes, hash_alg: HashAlgorithm, hash: bytes) -> Signature:
  # Computes the prehash signature over the context and hash using the key.
  # Optionally, a test-only "derandomized" version of this function might exist,
  # e.g., for Wycheproof test cases.
  ...
  return sig

def dsa_verify_pure(pub: PublicKey, ctx: bytes, msg: bytes, sig: Signature) -> bool:
  # Verifies the pure signature over the context and message using the key.
  ...
  return ok

def dsa_verify_prehash(pub: PublicKey, ctx: bytes, hash_alg: HashAlgorithm, hash: bytes, sig: Signature) -> bool:
  # Verifies the prehash signature over the context and hash using the key.
  ...
  return ok
```

I almost forgot about the "External Mu" trick (e.g., #link("https://csrc.nist.gov/pubs/fips/204/final")[FIPS 204], Algorithm 7, Line 6) which is equivalent to pure signing, but allows computing the fixed-length message representative hash (which includes ctx) before passing it to the signer, which helps with the problem below. Let's add it...

```python
def dsa_sign_pure_mu(priv: PrivateKey, mu: bytes) -> Signature:
  # Computes the signature over the mu value using the key.
  ...
  return sig

def dsa_verify_pure_mu(priv: PrivateKey, mu: bytes, sig: Signature) -> bool:
  # Verifies the signature over the mu value using the key.
  ...
  return sig
```

Unlike the KEM case, the inputs these functions are _not_ fixed-length.
`msg` might be 100 bytes or 100 gigabytes.
This creates obvious problems for embedded cryptographic interfaces, like hardware tokens or TPMs, which tend to have limits on the maximum size of requests or responses.
Pre-hashing was supposed to help with this, but since HashML-DSA and HashSLH-DSA are different algorithms to ML-DSA and SLH-DSA, it doesn't help much, since embedded crypto people understand that we will be asked to support the same protocols as everybody else, and "just totally modify your protocol to use a different cryptographic algorithm" is not a great answer.

So, we have to implement start/update/finish APIs (like those used for hashing):

```python
def dsa_sign_pure_start(priv: PrivateKey, ctx: bytes) -> SignatureSequence:
  # Starts a signature with the given key and context.
  ...
  return seq

def dsa_sign_pure_update(seq: SignatureSequence, data: bytes):
  # Adds the given data into the signature.
  ...

def dsa_sign_pure_complete(seq: SignatureSequence) -> Signature:
  # Finishes producing the signature.
  ...
  return sig

def dsa_verify_pure_start(pub: PublicKey, ctx: bytes) -> VerifySequence:
  # Starts verifying a signature with the given key and context.
  ...
  return seq

def dsa_verify_pure_update(seq: VerifySequence, data: bytes):
  # Adds the given data into the signature.
  ...

def dsa_verify_pure_complete(seq: VerifySequence, sig: Signature) -> bool:
  # Finishes checking the signature.
  ...
  return ok
```

Yikes. So unlike for KEMs, where we had 3 APIs and 2 input decisions, we have 13 APIs and the following 5 decisions:
- (Same as KEM) What kind of `seed` do I need?
- (Same as KEM) Which `parms` should I use?
- Should I use pure or prehash?
- (If using prehash) Which hash algorithm should I use?
- What do I put into `ctx`?

All this variety was introduced on purpose in order to provide some (real or perceived) security benefit:
- Pure signatures allow the security of the signature not to depend on the collision resistance of the chosen hash algorithm (second preimage resistance is still required, though)
- The `ctx` (context string) pulls domain separation (e.g., if one key signs two different types of messages) into the signature itself (instead of in the higher-level protocol that uses the signature)

Why are KEMs so simple and signatures so complex?
One reason is that the Key Encapsulation Mechanism has a really nice _indirection_ in the `SharedSecret`.
It isn't the KEM's business what you do with that secret.
Do some symmetric crypto with it.
It doesn't care.
Your actual data that you want to encrypt is none of your KEM's business.

Modern digital signatures are comparatively micro-managers.
The actual data that you want to sign is *still* your signature's business.

== Making Signatures More Usable <making-signatures-more-usable>

What could help here?
I'm a software engineer so I am obligated to suggest: maybe another indirection?

Imagine if signatures were defined over fixed-size *message representatives*:

```py
def dsa_keygen(seed: bytes, parms: ParameterSet) -> tuple[PublicKey, PrivateKey]:
  # Use eldritch algebra to expand the given random seed into an actual keypair.
  ...
  return (pub, priv)

def dsa_sign_mrep(priv: PrivateKey, mrep: MessageRepresentative) -> Signature:
  # Computes the signature over the message representative using the key.
  # Optionally, a test-only "derandomized" version of this function might exist,
  # e.g., for Wycheproof test cases.
  ...
  return sig

def dsa_verify_mrep(pub: PublicKey, mrep: MessageRepresentative, sig: Signature) -> bool:
  # Verifies the signature over the message representative using the key.
  ...
  return ok
```

The actual length of the `MessageRepresentative` would depend on the signing primitive (e.g., 64 bytes for ML-DSA, 32 bytes for ECDSA-P256, 256 bytes for RSA-2048).

A *separate* cryptographic protocol could define what to feed into a XOF (such as SHAKE256) to compute `mrep`:
- Incorporating a unique prefix that identifies the `mrep` scheme itself
- Incorporating an optional context string
- Incorporating a public key hash (to provide e.g., #link("https://eprint.iacr.org/2020/1525.pdf")[Beyond Unforgeability] properties on signatures that weren't designed with those properties in mind)
- Incorporating randomness for hedging (against e.g., side-channel risks)

= General Principles <general-principles>

Signatures won't be re-designed based on a random blog post from some crank on the internet (well, not this crank at least).
But hopefully the above discussion on signatures helps illustrate some principles that can be followed in the design of cryptographic interfaces of all levels (from primitives fo higher-level protocols:

== Protocols should be opinionated

Do not provide unnecessary knobs to the user.
Users will turn them and find ways to harm themselves.
How do you know if a knob is necessary?
- *Necessary*: Two different realistic threat models justify the two different values.
- *Unnecessary*: It would be fun to be able to change this value.

== Protocols should have one job

Follow the #link("https://en.wikipedia.org/wiki/Single-responsibility_principle")[Single Responsibility Principle].
A protocol doesn't need to do everything. Make composable systems of small, single-purpose protocols (e.g., KEM + Authenticated Encryption).

== Protocols should be known-answer-testable

Cryptographic protocols are easy to get wrong (or worse, slightly wrong).
Make it easy to test an implementation using test vectors (these inputs -> those outputs).

== Protocols should be upgradeable

No matter how carefully a protocol is designed, it will need to be updated later.
Whether because of a serious flaw or just a new optimization or use case, you will need to be able to change things.
Think about what will happen when two parties that support different versions of the protocol try to talk to each other.
