# Chapter 1 — SOLID Principles don't cut it anymore
> How many times have you done a code review where you or your partner said "This code is not applying Liskov Substitution"?

> How many times have you been coding and though: "Oh I need to follow the Open/Close principle here" ?

> How many times have you been coding and though: "Hm.. i am not sure I should apply Dependency Inversion here" ?

> How many times have you done a code review where the main discussion was if a class was doing too much or not?

For years SOLID was the vocabulary I reached for whenever I had to justify a design. It sounded like a method: five letters, learn them, apply them, get good code. But somewhere along the way I noticed I could *recite* SOLID without it ever changing a single decision I made at the keyboard. When I tried to use it forward — to *generate* a design rather than grade one — it gave me nothing actionable. "Single responsibility" never told me where to draw the line; "open/closed" never told me which axis would vary.

What I was left with was a set of words for *naming things that had already gone wrong*. SOLID stopped being something I could act on and became something I could point at — after the fact. That is a real and useful thing for a vocabulary to be. It is just not a way to reason about the code, and I had been treating it as one.

This chapter is me working out why, and focusing on SOLID as it's actually practiced in industry — cargo-culted, dogmatic, `IFoo`-per-class — not the principles charitably interpreted by their authors. 

Strip away the theory and what the industry actually settled on is a small, fixed architecture — a project skeleton you just follow:

- an interface for every class — `IFoo` beside every `Foo`;
- a DI container to wire them;
- those interfaces injected through the constructor.

It is really just **D** and **I** turned into plumbing; **O** and **L** survive only as the *excuse* for the interface seam (you *could* swap the implementation, any one *would* substitute), never as something you actually do. Principles meant to guide judgement became *boilerplate* you set up once and stop thinking about — which is the problem in miniature: **a template you apply by reflex is the opposite of reasoning about a design**.

## The online sentiment

The unease I felt has already been expressed; here is what others have argued, with sources, so you can follow each thread yourself.

### General

- "Principles" is the wrong word — they're contextual patterns or properties, not universal rules ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction); [North, *Why Every Element of SOLID Is Wrong*](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).
- Applied rigidly, SOLID produces over-abstracted, hard-to-navigate codebases — proliferation of tiny classes and interfaces ([Khoo, *Challenging the Gospel*](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7); [Mortenson, *SOLID — 25 Years Later*](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Open to vast amounts of interpretation and misinterpretation; the original definitions aren't operationally precise ([Marston, *Not-so-SOLID OO Principles*](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- No concrete problem/solution demonstrations — show the bug, the fix, the side effects ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- Second-order principles at best — they point in a direction, they don't define a goal ([Mortenson](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Rooted in late-90s OO assumptions; the framing feels dated ([nocomplexity, *Rise and Fall of SOLID*](https://nocomplexity.com/solid-programming/); [Dunn, *Is SOLID Still Relevant?*](https://dunnhq.com/posts/2021/solid-relevance/)).

### Per principle

#### S — Single Responsibility
- Undefined in practice; "one reason to change" drifted to "one actor" with no operational test ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)). (The idea this gropes toward — [Cohesion](../chapter2/axiom-06-cohesion.md) — is given a sharper, testable shape in Chapter 2.)
- Applied rigidly, produces overly granular classes for theoretical purity ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).

#### O — Open/Closed
- Requires predicting the future — which axis of variation will matter next ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Inheritance-for-extension caused the 90s "inheritance overdose" we're still recovering from ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).
- Arguably redundant — already implied by LSP ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/); [Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).

#### L — Liskov Substitution
- Routinely misread as a *structural* rule (same interface ⇒ substitutable) when it's a *behavioral* contract ([Henney](https://www.slideshare.net/Kevlin/solid-deconstruction); [Oldwood, *KISSing SOLID Goodbye*](https://accu.org/journals/overload/22/122/oldwood_1957/)). (Behavioral contract is exactly what [honest, total signatures](../chapter2/axiom-05-honest-total-signatures.md) make visible.)

#### I — Interface Segregation
- Cargo-culted into "one interface per class, even with a single implementation" ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Arguably collapses into SRP — not a separate idea ([North](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).

#### D — Dependency Inversion
- Routinely conflated with DI / DI frameworks; the principle ≠ the mechanism ([NDepend, *In Defense of SOLID*, noting the confusion](https://blog.ndepend.com/defense-solid-principles/)).
- Arguably reduces to SRP + LSP — Henney argues it isn't a separate principle ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/)).
- Terminology dated — "inversion" comes from the structured-programming era; today this *is* normal dependency direction ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)). (Where dependency direction *does* earn its keep, the [Impureim sandwich](../chapter2/axiom-11-impureheim.md) makes it a shape, not a framework.)

### Paradigm fit

- Doesn't transfer cleanly to functional programming or data pipelines; works mainly in its original context (large Java/.NET monoliths) ([Mikulski, *CUPID in Data Engineering*](https://mikulskibartosz.name/cupid-principles-in-data-engineering)).
- Doesn't apply cleanly across microservice boundaries — no implementation injection over HTTP/AMQP, so OCP loses meaning and DIP becomes contract-coupling ([Van Couvering, *Applying SOLID to Services*](https://david-vancouvering.medium.com/applying-solid-principles-to-services-e56ef2382a26)).

### Proposed alternatives

- **CUPID** — Composable, Unix philosophy, Predictable, Idiomatic, Domain-based. Properties on a spectrum, not rules ([cupid.dev](https://cupid.dev/); [North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).
- **Patterns over principles** — treat SOLID as context-dependent patterns to apply when symptoms appear, not rules to follow always ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction)).

## My read — half architecture, half not actionable

*This sharpens the community critique above rather than repeating it. The reasoning is my own; the one external attribution is cited inline.*

- **The structural/semantic split.** SOLID partitions cleanly. D, I, and the strategy-pattern form of O are *structural* — a convention, DI container, or linter enforces them, so they dissolve into invisible plumbing. S and L are *semantic* — about [cohesion](../chapter2/axiom-06-cohesion.md) and behavioral honesty — and nothing can mechanize them. The only live half of SOLID is S and L.
- **Only the un-mechanizable letters survive review — and only as symptoms, never by name.** Nobody says "Liskov violation," they say "this implementation behaves weird." Nobody says "SRP," they argue the class does too much. The principle vocabulary is dead in practice; the symptom vocabulary (blast radius, shotgun surgery, "why do I touch five files to add one thing") won.
- **SRP survives precisely because it's undefined.** Its vagueness isn't a bug — it's the only space in SOLID where real, contextual judgment ([cohesion](../chapter2/axiom-06-cohesion.md)) happens. The other letters became settled convention; SRP stays contested because it can't be reduced to a rule.
- **Two OCPs, and the bad one is the popular one.** Meyer's inheritance-based OCP (subclass to extend) is the fragile-base-class trap everyone actually hits. Bob's polymorphic OCP (add an implementation, never edit existing ones) is fine — but it's just "composition over inheritance" + "program to an interface" renamed. OCP is only sane *reactively*, along an axis you've already seen vary ([rule of three](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming))); applied speculatively it's just speculative generality.
- **OCP didn't die — it migrated up the stack.** Its surviving intent ("open for extension, closed for modification") is alive as Vertical Slice Architecture: add a feature by dropping in a vertical slice without touching existing slices. The unit of closure moved from the *class* to the *slice*, where it's finally actionable.
- **Refactoring to extract a shared concept is OCP working, not OCP breaking.** A one-time stabilizing extraction — done when the second consumer appears — buys closure for every future consumer. The health metric isn't "zero edits ever," it's *extraction frequency decaying over time* as the domain model matures. Persistent big extractions years in signal a wrong domain model and or design, not an OCP failure. Extract the *stable* domain concept (the aggregate); tolerate duplication on the *volatile* workflow.
- **SOLID is OOP-remediation, not universal design.** Its invisibility in FP is the tell: SRP, OCP, LSP, ISP, DIP are all structural givens in FP ([functional decomposition](../chapter2/axiom-00-data-vs-behaviour.md), [higher-order functions](../chapter2/axiom-08-first-class-functions.md), parametricity, small composable functions, dependencies-as-parameters), so the vocabulary is never needed. Even Mark Seemann — a rigorous SOLID defender — argues that, taken seriously, SOLID converges on FP ([Seemann, *SOLID: the next step is Functional*](https://blog.ploeh.dk/2014/03/10/solid-the-next-step-is-functional/)): push ISP to role interfaces and you reach single-method interfaces, which *are* functions. SOLID is a diagnostic vocabulary for *OOP-as-practiced* failure modes — useful for naming smells, but not the level at which design actually happens.
- **Judge SOLID by how it's practiced, not by what it was meant to be.** Almost no one applies the principles the way their authors intended, and the industry has long since settled into one particular way of working. That practiced version is the only SOLID most people ever meet — so debating what the principles *should* have meant is pointless; it only invites the reply *"you've misunderstood them."* The claim worth making is the concrete one: the version the industry actually practices isn't actionable — it doesn't help you reason about the code, only name what already went wrong. Everyone has felt that, so no one can dismiss it.

## CUPID — revisited later

The most promising replacement I keep circling back to is Dan North's **CUPID** — five *properties* (Composable, Unix philosophy, Predictable, Idiomatic, Domain-based) on a spectrum, rather than five rules to obey ([North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)). I'm still learning it, so I won't develop it here; I flag it as the alternative *framing* I find most honest and return to it later in the book.

## So what do I reason with instead?

When reading and writing code we must have the tools, the precise vocabulary to evaluate each line, each data point and each function, in several dimensions. To argue about trade-offs and to describe them properly.

SOLID does not give us that. The tell is right there: SOLID is invisible in functional code. It can only be applied where objects own mutable state and behaviour at once. And even when applied, half of it is pure architecture and the other is not actionable.

So the question I want answered isn't "how do I obey five principles?" It's:

**What are the building blocks that give me the precise vocabulary and metrics to reason about the code?**

And once I have them:

**How can I enforced those in the code itself, so I do not rely on anyone's discipline at review time?**

