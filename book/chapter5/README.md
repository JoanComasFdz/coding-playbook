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
- **A [mediator](https://en.wikipedia.org/wiki/Mediator_pattern) library**, MediatR in .NET [9]: one handler class per request, dispatched through a pipeline.

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
| 4 | Any driver can run the application: UI, API, tests, batch | [1] | Each entry point is a thin handler in the shell, and all of them call the same core. Orchestration may repeat between entry points ([Axiom 8](../chapter2/axiom-08-cohesion.md#what-dry-is-for)). | Met, with some repetition |
| 5 | The code speaks the business language | [4] | [Axiom 0](../chapter2/axiom-00-ubiquitous-language.md). | Met, same idea |
| 6 † | Invariants always hold | [4] [5] | An invalid value can't be built: value objects ([Axiom 19](../chapter2/axiom-19-value-objects.md)), unions ([Axiom 22](../chapter2/axiom-22-discriminated-unions.md), [Axiom 23](../chapter2/axiom-23-illegal-states.md)), state machines ([Axiom 25](../chapter2/axiom-25-state-machines.md)). | Met for one value or record; open for several |
| 7 | Logic lives in the domain, not in services | [4] [6] | Logic lives in modules of pure functions next to the types they work on ([Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md)). | Met differently |
| 8 | Fewer tangled dependencies in handlers | [9] | One handler per unit of work ([*Vertical slices*](../chapter4/02-vertical-slices.md)). The core is static, so it has nothing to inject. | Met, with fewer parts |
| 9 † | Database access doesn't swamp or bypass the domain | [4] | Handlers use the database directly. What they load is parsed into types the rules can trust ([Axiom 19](../chapter2/axiom-19-value-objects.md)). | Met differently |
| 10 | Test a use case without real infrastructure | [1] | Not attempted. The boundary is tested as a whole, with real dependencies ([Chapter 3](../chapter3/README.md)). | Not met, by choice |
| 11 | Swap a technology cheaply | [1] [3] | Systems owned by others are hidden behind a small surface. The component's own database is not ([*Information hiding*](../chapter4/03-information-hiding.md)). | Partly, by choice |
| 12 | Layering the compiler enforces | [5] | Only `static` and `internal` are enforced. The rest are rules a reader checks: the coding rules for [C#](../chapter2/coding-rules-csharp.md) and [Java](../chapter2/coding-rules-java.md). | Not met |
| 13 | Strategic design: core domain, bounded contexts | [4] | Out of scope. | Not met; can be combined |

Notes on the rows that need one:

**Rows 1 to 3: the same goal, reached by purity.** Hex DDD protects the domain with a rule about references: nothing in the domain may point outward. This book gets there by another route. A pure function has nothing to point at, because everything it needs arrives as a value. Seemann makes the same observation about functional code in general: "A pure function can call other pure functions, but it can't call impure functions", so a functional design falls "into a pit of success that looks a lot like Ports and Adapters". Of the object-oriented route he says it is possible, "but it takes so much effort" [8]. One caveat: in Haskell the compiler enforces purity. In C# and Java it is a rule (see row 12).

**Row 4: orchestration can repeat.** In hex DDD, an HTTP endpoint and a queue consumer call the same use-case object. Here each is its own shell handler around the same pure decision. The decision is shared; the gathering and acting are written per entry point.

**Row 6: one record, yes; several, not yet.** Types make an invalid value or an illegal state impossible to build, which is stronger than a check inside an aggregate root. What an aggregate adds is the boundary of what is loaded, changed and saved together, under concurrent use. That belongs to the [*DDD tactical patterns*](../chapter4/01-DDD-tactical-patterns.md) Play, which is a draft.

**Row 7: is this an anemic model?** By the look of it, yes: records without methods, logic elsewhere. By Fowler's argument, no. His objection is to logic scattered through procedural services, and he ties the worth of a domain model to one condition: "This is worthwhile iff you use the powerful OO techniques to organize complex logic" [6]. This book organizes complex logic with other techniques: unions, state machines, composition. The logic still lives in the domain, in one place per rule, with no service and no dependency around it. And without an identity-tracking ORM, most of the mapping cost he mentions is gone. A reader who defines a rich model as "methods on entities" will still call it anemic; [Axiom 2](../chapter2/axiom-02-data-is-not-behavior.md#tell-dont-ask-the-road-not-taken) says why I take the other road.

**Row 9: no repository interface.** Evans's two worries are real. This book answers the second one with types: data loaded from the database is parsed, so a query can't produce a value that skips the rules. The first one, database code swamping the caller, is answered only by keeping handlers thin. When the same query is needed in many handlers, a shared function for it earns its place. The persistence Play, not written yet, is where this gets shown.

**Row 10: a real disagreement.** Hex DDD tests a use case by replacing its ports with mocks. [Chapter 3](../chapter3/README.md) argues that such a test returns nothing here: the rules are already proven by function tests, and the mocks replace exactly the plumbing a test of the boundary should check. So this book skips that level and tests the component as a whole, with real dependencies. The price is in Chapter 3's *Trade-offs*: containers, setup, and slower tests than mocks.

**Row 11: who pays for the option to swap.** In hex DDD a repository port has two jobs: it lets tests replace the database, and it allows a swap. This book takes the first job away (rows 1 and 10). The second then has to pay for the layer alone, on every feature, for an event that may never come. The [*Information hiding*](../chapter4/03-information-hiding.md#trade-offs--when-not-to) Play makes that argument. Systems owned by others are different: they do change, and this book hides them too.

## What "simpler" means here

It means fewer parts for the same feature. For a product built by this book's rules there is:

- no interface whose only implementation sits next to it ([Chapter 1](../chapter1/README.md#enforce-decisions-not-ceremony)'s ceremony test);
- no mapping between layers that hold the same data under different names;
- no mock, and no in-memory copy of a database;
- no mediator between a controller and its handler;
- no separate project per layer.

It doesn't mean easier to learn. This book asks for things many C# and Java teams have not used: `Result`, unions, `Match`, composition, and the discipline of keeping effects out of the core. Hex DDD asks for more structure, but it is structure many engineers already know. That is a real cost of this book's approach, and the first objection I expect.

## What hex DDD gets right

- **The objectives.** Rows 1 to 9 are goals this book shares. It disagrees about the means, not the ends.
- **The vocabulary.** Ubiquitous language, value object, aggregate, repository, domain event: this book takes these names from DDD and keeps them ([Chapter 4](../chapter4/README.md)).
- **A known shape.** A new team member who has seen one hex DDD codebase can find their way in the next. That counts in a large organization.
- **Enforcement by the compiler** (row 12). With many developers, a boundary the build checks beats one a reviewer checks.
- **Strategic design** (row 13). Evans himself is reported to consider the building blocks over-emphasized next to it. This book has nothing to say there.

## When to use hex DDD instead

Each "not met" above becomes a criterion:

- **Several teams, or several business areas, in one product.** That is what bounded contexts and context maps are for. Strategic DDD can also sit on top of this book's way of writing code: the two are at different levels.
- **Invariants across several records, changed concurrently.** Until the aggregate Play is written, this book has no worked answer, and DDD's aggregate is a proven one.
- **So many developers that review can't hold the line.** Then project references that the compiler checks are worth their cost.
- **A replacement that is planned, not imagined.** A team that knows it will move off a store or a data source is no longer paying for a maybe, and a port pays for itself.
- **A domain complex enough to justify it.** That is the condition Microsoft, Palermo and Vernon set themselves.

## What this comparison does not show

- **It is argument and precedent, not measurement.** I have not built the same product both ways and counted. A pilot on one small product would count for more than this chapter.
- **Hex DDD is a family.** I compare against the form I meet in enterprise codebases. A hexagonal design with three ports and no mediator is closer to this book than to that form.
- **It is my experience.** Other teams apply these patterns with more restraint than the ones I have seen.

## Still to do

- **The rows marked †.** They wait for the persistence Play and the [*DDD tactical patterns*](../chapter4/01-DDD-tactical-patterns.md) Play.
- **One feature, built both ways,** in C# and Java, with the files and types counted.
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

---

← Previous: [Chapter 4 — Plays](../chapter4/README.md)
