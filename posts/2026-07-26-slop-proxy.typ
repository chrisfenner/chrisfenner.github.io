#import "../post.typ": fancy

== Do I look like someone who doesn't know how to generate my own slop?

LLMs are useful tools that are transforming the way we work in many professions.
For example, they are extremely useful in the field of software development.
Lots of toilsome boilerplate code can be automated away by LLMs.
I've used them a few times to speed up prototyping or one-off tooling projects.
As a lover of tools and automation and non-haver of infinite time: *great*.

But there is a dark temptation here that must be resisted: the urge to forget all accountability for one's work and just directly send LLM outputs to teammates, counting on them to curate and fix work products you haven't even proofread.
I call this behavior being a *Slop Proxy*.

#image("/images/2026-07-26-slop-proxy.drawio.svg")

*Don't do this* to your co-workers.
It communicates to them one or both of the following:
- You think your teammates are slopthirsty morons who desperately, _desperately_ need more slop -- they can't get enough, but they just can't figure out how to write a prompt.
- You think your job is just to copy and paste slop and slop-responses until the project achieves slop equilibrium, where everyone is either happy with the slop or tired of writing your prompts for you.

#image("/images/2026-07-26-officespace-agents.png", width: 300pt)

I am begging you, please recognize and respect the priceless light of human consciousness in yourself and in your teammates.
They are probably capable of generating slop when they need it, and your job is almost definitely not to be an unthinking clipboard.

Am I arguing that one should never use an LLM to generate outputs?
Nope. Absolutely not.
#strike[Chatbots] #fancy[Agentic Workflows] are useful tools for generating output *that you then review before sending, just like if you wrote it yourself*.

A mindset I've found valuable in my own work is that my job is _not_ to generate (code | docs | decks | meetings).
My job is to generate or contribute to meaningful _outcomes_ for my organization.
These outcomes often require generating the _right_ (code | docs | decks | meetings).
2000 brand-new lines of C++ doesn't itself solve my team's problems.
And certainly neither does a meeting that soaks up an hour of 20 people's workday.
It's the thoughtful deployment and maintenance of well-considered, well-understood code that solves my team's problems.
And my code, docs, decks, and meetings are all created in pursuit of that.

== In other words, work requires _intentionality_.

Here are some practices I've found useful for my own approach to LLM-generated work products:
- Be willing to try new things and sink a little time and energy into experimentation and learning to use LLMs properly.
- Always review the outputs before sending them to another person.
  Remember, they are going to have even less context than you.
  You are the best person to do this work.
- Be upfront about LLM usage.
  This saves people time guessing where the em-dashes and clunky catchphrases came from, and helps your team reproduce your success (or avoid your failure) later.
- Actively be accountable for the work product.
  You were already implicitly accountable before, so this doesn't change much, but your co-workers will respect the good faith.
- Use "small commits"-style incrementalism in your development workflow:
  it is much easier to have the LLM generate "simple, readable, maybe overly verbose and repetitive" code, refine and test that, then use the LLM (or your own brain) a few more times to optimize and refactor it iteratively.
  In my experience this works way better than "here is my goal, please one-shot it for me".
- If you don't have time to de-slop the outputs, consider just sending your teammates the *prompt itself* instead of the *result of the prompt*.
  That way, your actual intellectual contribution (e.g., "here is how I would go about searching for the answer based on x, y, z facts I already know") is clear and not muddied by GPT particles and unnecessary fluff.
