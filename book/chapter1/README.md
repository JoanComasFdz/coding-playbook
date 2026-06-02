*Scope: criticism of SOLID as it's actually practiced in industry — cargo-culted, dogmatic, `IFoo`-per-class — not the principles charitably interpreted by their authors.*

## General

- "Principles" is the wrong word — they're contextual patterns or properties, not universal rules ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction); [North, *Why Every Element of SOLID Is Wrong*](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).
- Applied rigidly, SOLID produces over-abstracted, hard-to-navigate codebases — proliferation of tiny classes and interfaces ([Khoo, *Challenging the Gospel*](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7); [Mortenson, *SOLID — 25 Years Later*](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Open to vast amounts of interpretation and misinterpretation; the original definitions aren't operationally precise ([Marston, *Not-so-SOLID OO Principles*](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- No concrete problem/solution demonstrations — show the bug, the fix, the side effects ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- Second-order principles at best — they point in a direction, they don't define a goal ([Mortenson](https://dev.to/chriswritesstuff/solid-30-years-later-g79)).
- Rooted in late-90s OO assumptions; the framing feels dated ([nocomplexity, *Rise and Fall of SOLID*](https://nocomplexity.com/solid-programming/); [Dunn, *Is SOLID Still Relevant?*](https://dunnhq.com/posts/2021/solid-relevance/)).

## Per principle

### S — Single Responsibility
- Undefined in practice; "one reason to change" drifted to "one actor" with no operational test ([Marston](https://www.tonymarston.net/php-mysql/not-so-solid-oo-principles.html)).
- Applied rigidly, produces overly granular classes for theoretical purity ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).

### O — Open/Closed
- Requires predicting the future — which axis of variation will matter next ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Inheritance-for-extension caused the 90s "inheritance overdose" we're still recovering from ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).
- Arguably redundant — already implied by LSP ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/); [Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).

### L — Liskov Substitution
- Routinely misread as a *structural* rule (same interface ⇒ substitutable) when it's a *behavioral* contract ([Henney](https://www.slideshare.net/Kevlin/solid-deconstruction); [Oldwood, *KISSing SOLID Goodbye*](https://accu.org/journals/overload/22/122/oldwood_1957/)).

### I — Interface Segregation
- Cargo-culted into "one interface per class, even with a single implementation" ([Khoo](https://medium.com/@jeremykhoois/solid-principles-sucks-b5935b1235d7)).
- Arguably collapses into SRP — not a separate idea ([North](https://speakerdeck.com/tastapod/why-every-element-of-solid-is-wrong)).

### D — Dependency Inversion
- Routinely conflated with DI / DI frameworks; the principle ≠ the mechanism ([NDepend, *In Defense of SOLID*, noting the confusion](https://blog.ndepend.com/defense-solid-principles/)).
- Arguably reduces to SRP + LSP — Henney argues it isn't a separate principle ([Henney summary](https://yahnd.com/theater/r/vimeo/157708450/)).
- Terminology dated — "inversion" comes from the structured-programming era; today this *is* normal dependency direction ([Dunn](https://dunnhq.com/posts/2021/solid-relevance/)).

## Paradigm fit

- Doesn't transfer cleanly to functional programming or data pipelines; works mainly in its original context (large Java/.NET monoliths) ([Mikulski, *CUPID in Data Engineering*](https://mikulskibartosz.name/cupid-principles-in-data-engineering)).
- Doesn't apply cleanly across microservice boundaries — no implementation injection over HTTP/AMQP, so OCP loses meaning and DIP becomes contract-coupling ([Van Couvering, *Applying SOLID to Services*](https://david-vancouvering.medium.com/applying-solid-principles-to-services-e56ef2382a26)).

## Proposed alternatives

- **CUPID** — Composable, Unix philosophy, Predictable, Idiomatic, Domain-based. Properties on a spectrum, not rules ([cupid.dev](https://cupid.dev/); [North, *CUPID — for joyful coding*](https://dannorth.net/2022/02/10/cupid-for-joyful-coding/)).
- **Patterns over principles** — treat SOLID as context-dependent patterns to apply when symptoms appear, not rules to follow always ([Henney, *SOLID Deconstruction*](https://www.slideshare.net/Kevlin/solid-deconstruction)).

## Our critique — SOLID as diagnostic vocabulary, not a design framework

*Developed in discussion. Sharpens the community critique above rather than repeating it. Unsourced — these are our own arguments.*

- **The structural/semantic split.** SOLID partitions cleanly. D, I, and the strategy-pattern form of O are *structural* — a convention, DI container, or linter enforces them, so they dissolve into invisible plumbing. S and L are *semantic* — about cohesion and behavioral honesty — and nothing can mechanize them. The only live half of SOLID is S and L.
- **Only the un-mechanizable letters survive review — and only as symptoms, never by name.** Nobody says "Liskov violation," they say "this implementation behaves weird." Nobody says "SRP," they argue the class does too much. The principle vocabulary is dead in practice; the symptom vocabulary (blast radius, shotgun surgery, "why do I touch five files to add one thing") won.
- **SRP survives precisely because it's undefined.** Its vagueness isn't a bug — it's the only space in SOLID where real, contextual judgment (cohesion) happens. The other letters became settled convention; SRP stays contested because it can't be reduced to a rule.
- **Two OCPs, and the bad one is the popular one.** Meyer's inheritance-based OCP (subclass to extend) is the fragile-base-class trap everyone actually hits. Bob's polymorphic OCP (add an implementation, never edit existing ones) is fine — but it's just "composition over inheritance" + "program to an interface" renamed. OCP is only sane *reactively*, along an axis you've already seen vary (rule of three); applied speculatively it's just speculative generality with a badge on.
- **OCP didn't die — it migrated up the stack.** Its surviving intent ("open for extension, closed for modification") is alive as VSA: add a feature by dropping in a vertical slice without touching existing slices. The unit of closure moved from the *class* to the *slice*, where it's finally actionable.
- **Refactoring to extract a shared concept is OCP working, not OCP breaking.** A one-time stabilizing extraction — done when the second consumer appears — buys closure for every future consumer. The health metric isn't "zero edits ever," it's *extraction frequency decaying over time* as the domain model matures. Persistent big extractions years in signal a wrong domain model, not an OCP failure. Extract the *stable* domain concept (the aggregate); tolerate duplication on the *volatile* workflow.
- **SOLID is OOP-remediation, not universal design.** Its invisibility in FP is the tell: SRP, OCP, LSP, ISP, DIP are all structural givens in FP (functional decomposition, higher-order functions, parametricity, small composable functions, dependencies-as-parameters), so the vocabulary is never needed. Even Mark Seemann, a rigorous defender, concedes SOLID taken seriously converges on FP. SOLID is a diagnostic vocabulary for *OOP-as-practiced* failure modes — useful for naming smells, but not the level at which design actually happens.
- **Attack SOLID-as-practiced, not SOLID-in-principle.** "The cargo-culted industry version is broken" is unanswerable — everyone has seen it. "SOLID itself is wrong" invites the strawman defense ("you misunderstand the principles"). The former is the honest claim *and* the stronger one.
