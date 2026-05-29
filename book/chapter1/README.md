# Chapter 1

This chapter introduces all foundational principles that will shape the rest of the playbook.

The principles are sequenced so each one rests only on principles already introduced. Read top to bottom, since the list forms a narrative spine.

The code examples they provide are for educational purposes and are not final, production-ready, comprehensive implementations.

## Index

**0. Data vs Behaviour** — data is a fact; behaviour is an operation. We keep the two separate.

*↳ The founding premise. Once data is a fact rather than an object that owns and mutates its own state, the first thing you want from a fact is that it stays put.*

**1. Immutability** — data that can't change after creation.

*↳ Removes one whole class of bug (mutating state); the other source is code that reaches outside itself — so next we name that.*

**2. Side effects** — interactions with the outside world.

*↳ Once you can spot an effect, you can label the functions that contain them.*

**3. Impure functions** — functions carrying side effects; unpredictable output.

*↳ And only now, with impurity named, can we define its opposite.*

**4. Pure functions** — no effects; same input, same output.

*↳ Purity closes the back door — no hidden inputs or outputs through effects. The front door can still lie, though: silently undefined on some inputs, or smuggling outcomes through nulls and sentinels.*

**5. Honest, total signatures** — every outcome named in the return type; defined for every input the types admit.

*↳ The criterion is set; the rest of the chapter is the toolkit. We'll want to compose such functions — which first means treating functions as values.*

**6. First-class functions** — functions stored, passed, returned.

*↳ Once functions are values, functions can take and return other functions.*

**7. Higher-order functions** — functions over functions.

*↳ That's the machinery the container types will need (map/flatMap are HOFs) — but before introducing them, we need a clean way to take their values apart.*

**8. Pattern matching** — branch on a value's shape.

*↳ With pure/impure understood, a criterion for good signatures, and a way to branch, we can now sketch the target we're building toward.*

**9. Impureheim** *(concept only)* — effects at the edges, pure logic in the middle.

*↳ The north star. That pure core is only worth having if we have good types to fill it — starting with the simplest.*

**10. Maybe** — presence or absence (examples now lean on the HOFs from 7).

*↳ Absence is one missing case; next, a value that's one of two types.*

**11. Either** — one of two types (a sealed interface + records).

*↳ Before specializing this into success/failure, we must handle operations that succeed but return nothing.*

**12. Unit** — a type with a single value, for "nothing meaningful to return."

*↳ With Unit available for the no-value case, Result can be defined cleanly.*

**13. Result** *(concept)* — success or failure, no exceptions.

*↳ A bare Result is clumsy; the HOFs from earlier let us transform and chain it.*

**14. Result combinators** — map / flatMap / mapError.

*↳ Chaining needs things to chain: small fallible constructors.*

**15. Value objects** *(string failures first)* — make invalid states unrepresentable; each `from` returns a Result.

*↳ A domain full of fallible constructors is exactly what we can now wire together.*

**16. Railway** — chain them so the first failure short-circuits.

*↳ But stopping at the first error isn't always what you want.*

**17. Validation** — a `ValidationError` convention plus accumulate-every-error, the deliberate contrast to railway.

*↳ All of this handled two outcomes; for three or more we generalize the shape.*

**18. Discriminated unions** *(3+ outcomes)* — consumed via the pattern matching from 8; the reveal that Either and Result were DUs all along.

*↳ The same sum-type machinery models not just a computation's outcomes but the persistent shape of a thing across its lifecycle.*

**19. Make illegal states unrepresentable** — model a thing that is in one of several states as a sum of per-state records, not a product of nullable fields; each field lives only on the state where it is valid. The data-shape sibling of value objects (15) and the base the state machine (21) and typestate (24) escalate from.

*↳ That was data at rest; when the pure core decides what should *happen*, model its output the same way — as a DU of actions.*

**20. Pure functions returning actions** — the pure core decides, the impure shell executes (delivering the sandwich from 9).

*↳ Generalize "decide an action" into "decide the next state."*

**21. State machines** — centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

*↳ The shell was one-shot — load, decide, persist, return. Many programs aren't one-shot. Before we can describe what their longer-lived shells *do*, we need to name what they *hold*.*

**22. Session Context** — per-session mutable state held by the shell: accumulators, signals, flags, callbacks. Distinct from FSM state and from globals.

*↳ With a place to keep the session's working memory, the shell shape can grow beyond one-shot — into a loop that drives the FSM forward over the whole session.*

**23. Stateful Shell** — the long-running shell shape: read current state, dispatch the effect that state demands, await an environmental event, call `Transition`, repeat. *(Lineage: the language-runtime fetch-decode-execute *Interpreter Loop*.)*

*↳ Twenty-three axioms in, the structural toolkit is complete — entities, decisions, shells, the session-scoped state they hold, and the long-lived resources the shell carries between calls. One niche escalation closes the chapter: when the legal *order* of calls is itself part of the contract, lift each state into its own type so the wrong-order call cannot be written.*

**24. Typestate** — encode call order in the type system; each state is its own type, transitions return the next type, and operations valid only in one state live only on that state's type. The narrow-use type-level counterpart to the value-level state machines from 21.

*Note: most bridges are strict dependencies — the next chapter literally needs the previous one. Two (9 and 20) are intentionally motivational rather than strict: Impureheim is introduced early as a "north star" to give the tool-building that follows a clear purpose, and it pays off at 20. Axiom 24 is the chapter's one out-of-arc item — a niche tool placed at the end so it does not interrupt the constantly-used material that precedes it.*
