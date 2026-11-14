# Vertical Slices

> **Skeleton.** The scope and the argument are here. The examples and the full write-up are still to do.

A vertical slice keeps all the code for one feature in one place: the request, the decision, the persistence and the response. The alternative is to spread that feature across technical layers: controllers, services, repositories, DTOs.

This is about how code is organised **inside one deployable**. It is not about splitting a system into services. That is system topology, and it is out of scope for this book.

Like every Play, this adds no new principle. It is [Cohesion](../chapter2/axiom-08-cohesion.md) and [Connascence](../chapter2/axiom-09-connascence.md) applied to the folder layout.

## Problem / forces

- In a layered layout, one feature lives in four or five folders: controller, service, repository, DTO, mapping.
- Adding or changing a feature touches every layer: "why do I touch five files to add one thing?"
- Shared layers couple features to each other. Change the shared service for feature A, and you risk breaking feature B.

## What I do today

- Group code by feature, not by technical layer: one folder per slice.
- Make each slice one [Impureim sandwich](../chapter2/axiom-13-impureim.md): the orchestrator gathers the data, calls a pure decision, and acts on the result.
- Share only the stable domain concepts across slices: [value objects](../chapter2/axiom-19-value-objects.md) and [aggregates](01-DDD-tactical-patterns.md#aggregate). Tolerate duplication in the volatile workflow.
- Add a feature by adding a slice. When a change touches several slices, ask why.

## Why

- **Cohesion.** Group by reason to change. A feature changes together, so it lives together. [Axiom 8](../chapter2/axiom-08-cohesion.md) already notes that the same metric, pointed at a folder, is what vertical slices reach for.
- **Connascence: locality.** A layered layout spreads one feature's connascence (shared names, types and meanings between controller, service, repository and DTO) across folders that sit far apart. A slice pulls it close. [Axiom 9](../chapter2/axiom-09-connascence.md): "High locality makes strong connascence tolerable."
- **Connascence: degree.** Slices share little, so the binding between them stays low.
- **The central model.** Each slice's orchestrator is the impure shell. The decision is a pure function returning an [action DU](../chapter2/axiom-24-pure-functions-returning-actions.md).
- **OCP, made actionable.** In Bogard's words: "New features only add code, you're not changing shared code and worrying about side effects." The unit that stays closed is the *slice*, not the class. "Does this change touch one slice or several?" is a question two reviewers answer the same way ([Chapter 1](../chapter1/README.md#ocp-did-not-die-it-moved-up-the-stack)).

Bogard's own rule is the two Chapter 2 lenses in one line: "Minimize coupling between slices, and maximize coupling in a slice." High cohesion inside a slice, low connascence between slices.

## Example

> **To do.** One feature as a slice, in C# and Java: a request record, a pure decision returning an action DU, and an orchestrator as the impure shell. Show it next to the same feature in a layered layout.

## Trade-offs & when NOT to

- **Ceremony.** Vertical slices as practised often come with a handler interface per request and a mediator library. Apply the [decisions-vs-ceremony test](../chapter1/README.md#enforce-decisions-not-ceremony) from [Chapter 1](../chapter1/README.md): remove it and ask what the reader lost. If the answer is nothing, leave it out.
- **Duplication.** Slices repeat similar code. That is intended for the volatile workflow. Extract a shared concept once it proves stable, not because two pieces of code look alike ([Axiom 8](../chapter2/axiom-08-cohesion.md): similarity is not a reason to merge).
- **Thin CRUD.** When every feature is the same thin read and write, a folder per endpoint adds structure without adding information.
- **No features to slice.** A library or a single-purpose module has no requests in this sense. Slicing does not apply.

## What might change tomorrow

- Where the shared domain code lives next to the slices: a shared domain folder, or something else. Still open.
- Whether the slice or the aggregate is the main unit of organisation, once the DDD tactical patterns Play is written in full.
- Tooling picks (a mediator library or plain classes) are contextual choices. They go in an ADR when made.

## References

- Jimmy Bogard, [*Vertical Slice Architecture*](https://www.jimmybogard.com/vertical-slice-architecture/).
