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

*↳ We'll want to pass these around — which first means treating functions as values.*

**5. First-class functions** — functions stored, passed, returned.

*↳ Once functions are values, functions can take and return other functions.*

**6. Higher-order functions** — functions over functions.

*↳ That's the machinery the container types will need (map/flatMap are HOFs) — but before introducing them, we need a clean way to take their values apart.*

**7. Pattern matching** — branch on a value's shape.

*↳ With pure/impure understood and a way to branch, we can now sketch the target we're building toward.*

**8. Impureheim** *(concept only)* — effects at the edges, pure logic in the middle.

*↳ The north star. That pure core is only worth having if we have good types to fill it — starting with the simplest.*

**9. Maybe** — presence or absence (examples now lean on the HOFs from 6).

*↳ Absence is one missing case; next, a value that's one of two types.*

**10. Either** — one of two types (a sealed interface + records).

*↳ Before specializing this into success/failure, we must handle operations that succeed but return nothing.*

**11. Unit** — a type with a single value, for "nothing meaningful to return."

*↳ With Unit available for the no-value case, Result can be defined cleanly.*

**12. Result** *(concept)* — success or failure, no exceptions.

*↳ A bare Result is clumsy; the HOFs from earlier let us transform and chain it.*

**13. Result combinators** — map / flatMap / mapError.

*↳ Chaining needs things to chain: small fallible constructors.*

**14. Value objects** *(string failures first)* — make invalid states unrepresentable; each `from` returns a Result.

*↳ A domain full of fallible constructors is exactly what we can now wire together.*

**15. Railway** — chain them so the first failure short-circuits.

*↳ But stopping at the first error isn't always what you want.*

**16. Validation** — a `ValidationError` convention plus accumulate-every-error, the deliberate contrast to railway.

*↳ All of this handled two outcomes; for three or more we generalize the shape.*

**17. Discriminated unions** *(3+ outcomes)* — consumed via the pattern matching from 7; the reveal that Either and Result were DUs all along.

*↳ Now the pure core can return a rich set of outcomes — model them as actions.*

**18. Pure functions returning actions** — the pure core decides, the impure shell executes (delivering the sandwich from 8).

*↳ Generalize "decide an action" into "decide the next state."*

**19. State machines** — centralized state, transitions as DUs, decisions as pure functions returning actions. Everything composes.

---

*Note: most bridges are strict dependencies — the next chapter literally needs the previous one. Two (8 and 18) are intentionally motivational rather than strict: Impureheim is introduced early as a "north star" to give the tool-building that follows a clear purpose, and it pays off at 18.*