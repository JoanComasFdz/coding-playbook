# Chapter 5 — Next to Hexagonal Architecture and DDD

[Chapter 1](../chapter1/README.md) opened this book with a question: if SOLID can't be acted on, what do I reason with instead? This chapter closes it with the question a reader has at the end. The industry already has an answer for structuring business software. How does this book stand next to it, and when should I use which?

That answer, as I meet it in C# and Java codebases, is a combination I'll call **hex DDD**: [hexagonal architecture](https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)) and its relatives, filled with the tactical patterns of [Domain-Driven Design](https://en.wikipedia.org/wiki/Domain-driven_design).

My claim is narrow. For small and medium products, the axioms of [Chapter 2](../chapter2/README.md), the testing of [Chapter 3](../chapter3/README.md) and the Plays of [Chapter 4](../chapter4/README.md) reach most of the objectives hex DDD was built for, with fewer parts. They don't reach all of them. Where they stop is where I would use hex DDD (see *When to use hex DDD instead*).

> **Draft.** The objectives, their sources and the comparison are here. Rows marked † rest on Plays that are not written yet. A worked example of one feature built both ways is still to do.

## What I am comparing against

Four things that usually arrive together:

- **Hexagonal architecture**, or Ports and Adapters (Cockburn, 2005) [1]. The application sits in the middle and talks to the outside only through ports. Each technology gets an adapter.
- **Onion Architecture** (Palermo, 2008) [2] and **Clean Architecture** (Martin, 2012) [3]. The same idea drawn as layers, with one rule: dependencies point inward.
- **The tactical patterns of DDD** (Evans, 2003) [4]: entities, value objects, aggregates, repositories, domain events.
- **A [mediator](https://en.wikipedia.org/wiki/Mediator_pattern) library**, MediatR in .NET [9]: one handler class per request, dispatched through a pipeline. I know of no Java library with the same standing. The closest is PipelinR, which describes itself as "similar to a popular MediatR .NET library" [10].

As it usually lands in a codebase, in my experience and in Microsoft's reference design [5]:

- three projects, Domain, Application and Infrastructure, where Domain references nothing;
- an interface per repository in the domain, implemented in the infrastructure;
- entities with behavior, grouped in aggregates;
- a handler per request, behind the mediator;
- mapping between each layer's types;
- unit tests of the handlers, with the repositories mocked.

**Scope.** This is a comparison of how the code inside one deployable is organized. Strategic DDD (bounded contexts, context maps, the core domain) is out of scope for this book, and so is system topology. Both come back once, in *When to use hex DDD instead*.

## The evidence: what these approaches are for

Each objective below is taken from the source that states it.

**Hexagonal architecture.** Cockburn's intent, in full: "Allow an application to equally be driven by users, programs, automated test or batch scripts, and to be developed and tested in isolation from its eventual run-time devices and databases" [1]. The problem behind it is the "infiltration of business logic into the user interface code". The same mechanism lets a "mock" database stand in for the real one, and lets a database be replaced without the application noticing.

**Clean Architecture.** Martin lists what the architecture produces [3]:

- "Independent of Frameworks."
- "Testable. The business rules can be tested without the UI, Database, Web Server, or any other external element."
- "Independent of UI."
- "Independent of Database. You can swap out Oracle or SQL Server, for Mongo, BigTable, CouchDB, or something else."
- "Independent of any external agency."

All five follow from one rule: "source code dependencies can only point inwards."

**Onion Architecture.** Palermo's objection to classic layering is that the UI ends up coupled to data access through the layers between them. His fix: "all coupling is toward the center", with the domain model in the middle and the infrastructure at the edge, behind interfaces the core owns [2]. This is [dependency inversion](https://en.wikipedia.org/wiki/Dependency_inversion_principle) applied to the whole application.

**DDD.** Evans defines it as "an approach to the development of complex software in which we: 1. Focus on the core domain. 2. Explore models in a creative collaboration of domain practitioners and software practitioners. 3. Speak a ubiquitous language within an explicitly bounded context" [4]. The patterns each answer a problem he names:

- **Layered architecture.** "When the domain-related code is diffused through such a large amount of other code, it becomes extremely difficult to see and to reason about." So: "Isolate the expression of the domain model and the business logic, and eliminate any dependency on infrastructure, user interface, or even application logic that is not business logic."
- **Aggregates.** "It is difficult to guarantee the consistency of changes to objects in a model with complex associations." So: cluster them, give each cluster a root that enforces its invariants, and "use the same aggregate boundaries to govern transactions and distribution."
- **Repositories.** "The sheer technical complexity of applying most database access infrastructure quickly swamps the client code, which leads developers to dumb-down the domain layer." And unconstrained queries reach inside an aggregate, "making it impossible for these objects to enforce the rules of the domain model."

**Behavior in the domain.** Fowler's [anemic domain model](https://en.wikipedia.org/wiki/Anemic_domain_model) is a model whose objects are "little more than bags of getters and setters", with the logic in services. His objection: such designs "incur all of the costs of a domain model, without yielding any of the benefits" [6].

**The mediator.** Bogard names the problem MediatR answers in two words: "reducing chaotic dependencies" [9]. A controller or service that collects a dozen injected collaborators is the case he means.

**Enforcement.** Microsoft's guide adds a practical reason for the separate projects: layering "may be easier to enforce if layers are implemented as different class libraries", because the dependencies between them are then explicit, and a domain project that references nothing can't reach the infrastructure [5].

## What the same sources say about their limits

Several of these authors limit their own advice:

- **Microsoft:** "DDD approaches should be applied only if you are implementing complex microservices with significant business rules. Simpler responsibilities, like a CRUD service, can be managed with simpler approaches" [5].
- **Palermo:** "This architecture is not appropriate for small websites." It is "appropriate for long-lived business applications as well as applications with complex behavior" [2].
- **Vernon:** "DDD is not appropriate for just any enterprise application." And: "Modeling complex domains is the sweet spot for DDD" [7].
- **Fowler:** "Domain Models aren't always the best tool" [6].
- **Cockburn** favors few ports: "two, three or four ports" [1]. A port per repository is not what his article describes.
- **Bogard** uses MediatR only at the edges of his systems [9].

Cockburn's and Martin's articles have no section on cost, or on when not to apply the pattern [1][3].

So proposing a lighter default for smaller products doesn't contradict this literature. Half of it says the same.

## Objective by objective

| # | Objective | Stated by | This book's answer | Verdict |
|---|---|---|---|---|
| 1 | Test business rules without UI or database | [1] [3] | Rules are pure static functions ([Axiom 6](../chapter2/axiom-06-pure-functions.md)). A function test passes values in and compares the result ([Chapter 3](../chapter3/README.md)): no mock, no in-memory adapter. | Met, with fewer parts |
| 2 | Keep business logic out of UI and database code | [1] [4] | The core reads only its parameters and acts only through its return value ([Axiom 13](../chapter2/axiom-13-impureim.md)). | Met, with fewer parts |
| 3 | The domain depends on no framework or infrastructure | [2] [3] [5] | The core takes values and returns values or actions ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md)). There is no dependency left to invert. | Met, with fewer parts |
| 4 | Any driver can run the application: UI, API, tests, batch | [1] | An entry point is a few lines that call a handler: an ordinary class that runs one unit of work ([Axiom 13](../chapter2/axiom-13-impureim.md#example)). Any entry point can call the same handler. | Met, with fewer parts |
| 5 | The code speaks the business language | [4] | [Axiom 0](../chapter2/axiom-00-ubiquitous-language.md). | Met, same idea |
| 6 † | Invariants always hold | [4] [5] | An invalid value can't be built: value objects ([Axiom 19](../chapter2/axiom-19-value-objects.md)), unions ([Axiom 22](../chapter2/axiom-22-discriminated-unions.md), [Axiom 23](../chapter2/axiom-23-illegal-states.md)), state machines ([Axiom 25](../chapter2/axiom-25-state-machines.md)). A rule across several records is a pure decision over the value that holds them ([Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md#example)). | Met for the rules; the transaction boundary is open |
| 7 | Logic lives in the domain, not in services | [4] [6] | Logic lives in modules of pure functions next to the types they work on ([Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md)). | Met differently |
| 8 | Fewer tangled dependencies in handlers | [9] | One handler per unit of work ([*Vertical slices*](../chapter4/02-vertical-slices.md)). The core is static, so it has nothing to inject. | Met, with fewer parts |
| 9 † | Database access doesn't swamp or bypass the domain | [4] | Handlers use the database directly. What they load is parsed into types the rules can trust ([Axiom 19](../chapter2/axiom-19-value-objects.md)). | Met differently |
| 10 | Test a use case without real infrastructure | [1] | Not pursued. Once the rules are tested as functions, what is left is plumbing, and plumbing is tested for real ([Chapter 3](../chapter3/README.md)). | Not pursued: nothing left to test in isolation |
| 11 | Swap a technology cheaply | [1] [3] | Systems owned by others are hidden behind a small surface. The component's own database is not ([*Information hiding*](../chapter4/03-information-hiding.md)). | Partly, by choice |
| 12 | The build rejects a dependency in the wrong direction | [5] | Not by default. Here the compiler checks other things: which values can exist, that every case is handled, what is `internal`. The direction check can be added the same way, with a project for the core. | Not met by default; can be added |
| 13 | Strategic design: core domain, bounded contexts | [4] | Out of scope. | Not met; can be combined |

Notes on the rows that need one:

**Rows 1 to 3: the same goal, reached by purity.** Hex DDD protects the domain with a rule about references: nothing in the domain may point outward. This book gets there by another route. A pure function has nothing to point at, because everything it needs arrives as a value. Seemann makes the same observation about functional code in general: "A pure function can call other pure functions, but it can't call impure functions", so a functional design falls "into a pit of success that looks a lot like Ports and Adapters". Of the object-oriented route he says it is possible, "but it takes so much effort" [8]. One caveat: in Haskell the compiler enforces purity. In C# and Java it is a rule (see row 12).

**Row 4: the handler is the use case.** This book's shell has two parts. The entry point is what the framework shapes: a controller, an event subscription, a background service. The handler is what runs inside it: one unit of work, as rounds of gather, decide, act. A controller and a queue consumer can call the same handler, the way both would call a use case through its port in hex DDD, without the port. [Axiom 8](../chapter2/axiom-08-cohesion.md#what-dry-is-for) also lets two entry points each write their own orchestration, when sharing it would tie them together.

**Row 6: the rules are covered; the transaction is not yet.** Types make an invalid value or an illegal state impossible to build, which is stronger than a check inside an aggregate root. A rule that spans several records is covered too, as long as they are loaded as one value: `DecideAdd` in [Axiom 24](../chapter2/axiom-24-pure-functions-returning-actions.md#example) checks the number of lines in the whole `Cart`. What an aggregate adds is on the shell's side: which records are loaded and saved together in one transaction, and what happens when two requests change them at the same time. That part belongs to the [*DDD tactical patterns*](../chapter4/01-DDD-tactical-patterns.md) Play, which is a draft.

**Row 7: is this an anemic model?** By the look of it, yes: records without methods, logic elsewhere. By Fowler's argument, no. His objection is to logic scattered through procedural services, and he ties the worth of a domain model to one condition: "This is worthwhile iff you use the powerful OO techniques to organize complex logic" [6]. This book organizes complex logic with other techniques: unions, state machines, composition. The logic still lives in the domain, in one place per rule, with no service and no dependency around it. And without an identity-tracking ORM, most of the mapping cost he mentions is gone. A reader who defines a rich model as "methods on entities" will still call it anemic; [Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md#tell-dont-ask-the-road-not-taken) says why I take the other road.

**Anemic is a property with a verdict attached.** The word describes something neutral: data without methods. But it arrives with a verdict. Fowler introduces it as an anti-pattern whose "fundamental horror" is that "it's so contrary to the basic idea of object-oriented design; which is to combine data and process together" [6]. That is a fair charge inside object-oriented design, where it was made. It doesn't carry over to a design that separates data and process on purpose. The pair of names also does part of the arguing: if only methods on data may be called *rich*, everything else is poor before anyone has looked at it. I use *anemic* here as a description, not as a grade.

**Row 9: a repository where it earns its place.** Evans's two worries are real. This book answers the second one with types: data loaded from the database is parsed, so a query can't produce a value that skips the rules. The first one, database code swamping the caller, depends on the query. A simple read or write stays in the handler. A query complex enough that a developer needs a second read to understand it earns a named function of its own, and that is a repository in all but the interface. What this book drops is the repository produced mechanically for every table, CRUD queries included: an indirection with no job left, since nothing in the shell is swapped for a mock. The persistence Play, not written yet, is where this gets shown.

**Row 10: this isn't a preference; it follows from the split.** Hex DDD tests a use case by replacing its ports with mocks. In this book, the rules are pure and already proven by function tests, value objects included. What is left in a handler is plumbing: it passes what it loaded to a pure function and acts on the result. A mock for that returns exactly the value the function test already used, so the test proves nothing new, and it has to know which calls the handler makes, in which order. Fowler names that cost: "Mockist tests are thus more coupled to the implementation of a method. Changing the nature of calls to collaborators usually cause a mockist test to break" [11]. So this book skips that level and tests the component as a whole, with real dependencies, where plumbing can really fail ([Chapter 3](../chapter3/README.md)). Those tests are slower than mocks, and they return far more. A fast test that proves nothing is not a bargain. The price is in Chapter 3's *Trade-offs*.

**Row 11: who pays for the option to swap.** In hex DDD a repository port has two jobs: it lets tests replace the database, and it allows a swap. This book takes the first job away (rows 1 and 10). The second then has to pay for the layer alone, on every feature, for an event that may never come. The [*Information hiding*](../chapter4/03-information-hiding.md#trade-offs--when-not-to) Play makes that argument. Systems owned by others are different: they do change, and this book hides them too.

**Row 12: what the build checks, on each side.** Separate projects make the compiler check one thing: the domain project can't use a type from a project or package it doesn't reference. That is real. It stops an ORM type or a repository implementation from appearing in the domain. It doesn't check where a rule is written (it can still sit in a controller), or where an interface is placed. And it doesn't stop effects that need no reference at all: the clock, the file system and the network are in the standard library of both languages. This book moves other checks to the compiler: an invalid value can't be built, a missing case doesn't compile, a failure is in the signature. Neither approach makes the compiler check purity in C# or Java. The two sets of checks don't compete, and a component that wants the reference check as well can give its core a project of its own. Whether this book should prescribe that is open (see *Still to do*).

## What "simpler" means here

It means fewer parts for the same feature. For a product built by this book's rules there is:

- no interface whose only implementation sits next to it ([Chapter 1](../chapter1/README.md#enforce-decisions-not-ceremony)'s ceremony test);
- no mapping between layers that hold the same data under different names;
- no mock, and no in-memory copy of a database;
- no mediator between a controller and its handler;
- no separate project per layer.

It doesn't mean familiar. This book asks for things many C# and Java teams have not used: `Result`, unions, `Match`, composition, and the discipline of keeping effects out of the core. Whether that is harder to learn for someone who has seen neither approach, I don't know; fewer parts suggests it isn't. But most engineers in these languages have already seen hex DDD. A team that switches pays for retraining, and a new hire brings less with them. That is a real cost of this book's approach, and the first objection I expect.

## What hex DDD gets right

- **The objectives.** Rows 1 to 9 are goals this book shares. It disagrees about the means, not the ends.
- **The vocabulary.** Ubiquitous language ([Axiom 0](../chapter2/axiom-00-ubiquitous-language.md)) and value object ([Axiom 19](../chapter2/axiom-19-value-objects.md)) are DDD's names, and this book keeps them. Aggregate, repository and domain event come back in the [*DDD tactical patterns*](../chapter4/01-DDD-tactical-patterns.md) Play, modeled this book's way.
- **A known shape.** A new team member who has seen one hex DDD codebase can find their way in the next. That counts in a large organization.
- **One check by the build** (row 12). Project references stop the domain from using infrastructure types. It is one check, not the whole discipline, but with many developers a boundary the build checks beats one a reviewer checks.
- **Strategic design** (row 13). Evans himself is reported to consider the building blocks over-emphasized next to it. This book has nothing to say there.

## When to use hex DDD instead

Each "not met" above becomes a criterion:

- **Several teams, or several business areas, in one product.** That is what bounded contexts and context maps are for. Strategic DDD can also sit on top of this book's way of writing code: the two are at different levels.
- **Invariants across several records, changed concurrently.** Until the aggregate Play is written, this book has no worked answer, and DDD's aggregate is a proven one.
- **So many developers that review can't hold the line.** Then the reference check of separate projects is worth having. It can be had without the rest of hex DDD (row 12).
- **A replacement that is planned, not imagined.** A team that knows it will move off a store or a data source is no longer paying for a maybe, and a port pays for itself.
- **A domain complex enough to justify it.** That is the condition Microsoft, Palermo and Vernon set themselves.

## What this comparison does not show

- **It is argument and precedent, not measurement.** I have not built the same product both ways and counted. A pilot on one small product would count for more than this chapter.
- **Hex DDD is a family.** I compare against the form I meet in enterprise codebases. A hexagonal design with three ports and no mediator is closer to this book than to that form.
- **It is my experience.** Other teams apply these patterns with more restraint than the ones I have seen.

## Still to do

- **The rows marked †.** They wait for the persistence Play and the [*DDD tactical patterns*](../chapter4/01-DDD-tactical-patterns.md) Play.
- **One feature, built both ways,** in C# and Java, with the files and types counted.
- **A project for the core?** Whether this book should prescribe one, so the build checks references, and an analyzer that rejects the clock and I/O inside it (row 12). The tool would be a choice for an ADR.
- **Sources to verify before citing:**
  - Netflix, *Ready for changes with Hexagonal Architecture* (2020): a team that chose hexagonal for a planned change of data sources, and tests use cases with mocked sources. Read only through notes.
  - Eric Evans at QCon London 2009 and DDD Europe 2016, on the over-emphasis on building blocks. Read only through an attendee's notes.
  - Vaughn Vernon's "DDD scorecard" in *Implementing Domain-Driven Design* (2013), ch. 1.
  - Scott Wlaschin, *Domain Modeling Made Functional* (2018), as the book-length precedent for DDD with functions.

## References

[1] **Alistair Cockburn**, *Hexagonal architecture*, 2005. The intent, the mock database, and the preference for a small number of ports.
<https://alistair.cockburn.us/hexagonal-architecture/>

[2] **Jeffrey Palermo**, *The Onion Architecture: part 1*, 2008. "All coupling is toward the center"; not appropriate for small websites.
<https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/>

[3] **Robert C. Martin**, *The Clean Architecture*, The Clean Code Blog, 2012. The five properties and the Dependency Rule.
<https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html>

[4] **Eric Evans**, *Domain-Driven Design Reference: Definitions and Pattern Summaries*, Domain Language, 2015. The definition of DDD and the problem statement of each pattern, by the author of *Domain-Driven Design* (Addison-Wesley, 2003).
<https://domainlanguage.com/wp-content/uploads/2016/05/DDD_Reference_2015-03.pdf>

[5] **Microsoft**, *Designing a DDD-oriented microservice*, in *.NET Microservices: Architecture for Containerized .NET Applications*. The three-project layout, and the advice to apply DDD only to complex services.
<https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/ddd-oriented-microservice>

[6] **Martin Fowler**, *AnemicDomainModel*, martinfowler.com, 2003.
<https://martinfowler.com/bliki/AnemicDomainModel.html>

[7] **Vaughn Vernon**, interview on *Implementing Domain-Driven Design*, InformIT, 2013.
<https://www.informit.com/articles/article.aspx?p=2023702>

[8] **Mark Seemann**, *Functional architecture is Ports and Adapters*, ploeh blog, 2016. Also cited in [Axiom 13](../chapter2/axiom-13-impureim.md).
<https://blog.ploeh.dk/2016/03/18/functional-architecture-is-ports-and-adapters/>

[9] **Jimmy Bogard**, *You Probably Don't Need to Worry About MediatR*, 2022. The author of MediatR on what it is for, and where he uses it.
<https://jimmybogard.com/you-probably-dont-need-to-worry-about-mediatr/>

[10] **Eduards Sizovs**, *PipelinR*, GitHub. A command processing pipeline for Java: "similar to a popular MediatR .NET library".
<https://github.com/sizovs/PipelinR>

[11] **Martin Fowler**, *Mocks Aren't Stubs*, martinfowler.com, 2007. Classical and mockist testing, and what each couples a test to.
<https://martinfowler.com/articles/mocksArentStubs.html>

---

← Previous: [Chapter 4 — Plays](../chapter4/README.md)
