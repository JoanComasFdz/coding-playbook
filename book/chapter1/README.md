# Chapter 1

This chapter introduces all foundational principles that will shape the rest of the playbook.

The principles are sequenced so each one rests only on principles already introduced. Read top to bottom, since the list forms a narrative spine.

---

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

*↳ Now the pure core can return a rich set of outcomes — model them as actions.*

**19. Pure functions returning actions** — the pure core decides, the impure shell executes (delivering the sandwich from 9).

*↳ Generalize "decide an action" into "decide the next state."*

**20. State machines** — centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

---

*Note: most bridges are strict dependencies — the next chapter literally needs the previous one. Two (9 and 19) are intentionally motivational rather than strict: Impureheim is introduced early as a "north star" to give the tool-building that follows a clear purpose, and it pays off at 19.*
