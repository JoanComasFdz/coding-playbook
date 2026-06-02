# Chapter 1 — SOLID Names the Symptom

*Scope: criticism of SOLID as it's actually practiced in industry — cargo-culted, dogmatic, `IFoo`-per-class — not the principles charitably interpreted by their authors. This chapter is the hook for the whole book; the building blocks it points toward live in [Chapter 2 — Fundamentals](../chapter2/README.md).*

## The hook

For years SOLID was the vocabulary I reached for whenever I had to justify a design. It sounded like a method: five letters, learn them, apply them, get good code. But somewhere along the way I noticed I could *recite* SOLID without it ever changing a single decision I made at the keyboard. When I tried to use it forward — to *generate* a design rather than grade one — it gave me nothing actionable. "Single responsibility" never told me where to draw the line; "open/closed" never told me which axis would vary.

What I was left with was a set of words for *naming things that had already gone wrong*. SOLID stopped being something I could act on and became something I could point at — after the fact. That is a real and useful thing for a vocabulary to be. It is just not a design framework, and I had been treating it as one. This chapter is me working out why, and where I went looking instead.

## It's not just me — the community signal

Before my own read, the receipts. The unease I felt is well-trodden ground; here is what others have argued, with sources, so you can follow each thread yourself. (Third-person attribution below is deliberate — these are *their* claims, not mine.)

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

## My read — SOLID as diagnostic vocabulary, not a design framework

*This sharpens the community critique above rather than repeating it. Unsourced — these are my own arguments.*

- **The structural/semantic split.** SOLID partitions cleanly. D, I, and the strategy-pattern form of O are *structural* — a convention, DI container, or linter enforces them, so they dissolve into invisible plumbing. S and L are *semantic* — about [cohesion](../chapter2/axiom-06-cohesion.md) and behavioral honesty — and nothing can mechanize them. The only live half of SOLID is S and L.
- **Only the un-mechanizable letters survive review — and only as symptoms, never by name.** Nobody says "Liskov violation," they say "this implementation behaves weird." Nobody says "SRP," they argue the class does too much. The principle vocabulary is dead in practice; the symptom vocabulary (blast radius, shotgun surgery, "why do I touch five files to add one thing") won.
- **SRP survives precisely because it's undefined.** Its vagueness isn't a bug — it's the only space in SOLID where real, contextual judgment ([cohesion](../chapter2/axiom-06-cohesion.md)) happens. The other letters became settled convention; SRP stays contested because it can't be reduced to a rule.
- **Two OCPs, and the bad one is the popular one.** Meyer's inheritance-based OCP (subclass to extend) is the fragile-base-class trap everyone actually hits. Bob's polymorphic OCP (add an implementation, never edit existing ones) is fine — but it's just "composition over inheritance" + "program to an interface" renamed. OCP is only sane *reactively*, along an axis you've already seen vary (rule of three); applied speculatively it's just speculative generality with a badge on.
- **OCP didn't die — it migrated up the stack.** Its surviving intent ("open for extension, closed for modification") is alive as VSA: add a feature by dropping in a vertical slice without touching existing slices. The unit of closure moved from the *class* to the *slice*, where it's finally actionable.
- **Refactoring to extract a shared concept is OCP working, not OCP breaking.** A one-time stabilizing extraction — done when the second consumer appears — buys closure for every future consumer. The health metric isn't "zero edits ever," it's *extraction frequency decaying over time* as the domain model matures. Persistent big extractions years in signal a wrong domain model, not an OCP failure. Extract the *stable* domain concept (the aggregate); tolerate duplication on the *volatile* workflow.
- **SOLID is OOP-remediation, not universal design.** Its invisibility in FP is the tell: SRP, OCP, LSP, ISP, DIP are all structural givens in FP ([functional decomposition](../chapter2/axiom-00-data-vs-behaviour.md), [higher-order functions](../chapter2/axiom-08-first-class-functions.md), parametricity, small composable functions, dependencies-as-parameters), so the vocabulary is never needed. Even Mark Seemann, a rigorous defender, concedes SOLID taken seriously converges on FP. SOLID is a diagnostic vocabulary for *OOP-as-practiced* failure modes — useful for naming smells, but not the level at which design actually happens.
- **Attack SOLID-as-practiced, not SOLID-in-principle.** "The cargo-culted industry version is broken" is unanswerable — everyone has seen it. "SOLID itself is wrong" invites the strawman defense ("you misunderstand the principles"). The former is the honest claim *and* the stronger one.

## CUPID — revisited later

The most promising replacement I keep circling back to is Dan North's **CUPID** — five *properties* (Composable, Unix philosophy, Predictable, Idiomatic, Domain-based) on a spectrum, rather than five rules to obey ([North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)). I'm still learning it, so I won't develop it here; I flag it as the alternative *framing* I find most honest and return to it later in the book.

## So what do I reason with instead?

Here is the loop this chapter opened, closed. SOLID is a fine diagnostic vocabulary — it names smells after they appear — but a vocabulary that can only name symptoms after the fact is the wrong altitude for *designing* anything. Symptoms imply there is a level *below* them, where the actual building blocks live: the place a smell either can or cannot occur in the first place.

The tell is right there in my own read: SOLID is invisible in functional code. It only bites where objects own mutable state and behaviour at once — that is the soil every one of its failure modes grows in. Pull those apart and most of SOLID stops being something you remediate and starts being something the compiler simply enforces up front.

So the question I want answered isn't "how do I obey five principles?" It's: **if my design vocabulary can only name problems after the fact, what would building blocks look like that make those problems unrepresentable up front — enforced by the type system, not by my discipline at review time?** That is the whole of Chapter 2.

It starts at the soil: [Axiom 0 — Data vs Behaviour](../chapter2/axiom-00-data-vs-behaviour.md) separates the two things OOP fuses, and from there the axioms build up — [honest, total signatures](../chapter2/axiom-05-honest-total-signatures.md) so a type can't lie about what it does, [closed sets over open hierarchies](../chapter2/axiom-20-discriminated-unions.md) and [making illegal states unrepresentable](../chapter2/axiom-21-illegal-states.md) so the bad case never compiles. Read the [full index](../chapter2/README.md), or just start at the beginning.
