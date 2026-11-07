# A failing service test points somewhere

The usual objection to testing at service level: when a test that runs the whole service fails, it doesn't say *where*. Somewhere between the HTTP request and the database row, something broke. Unit tests exist partly to answer that.

In code built on [Chapter 2](../chapter2/README.md), the objection mostly goes away, because of where the decisions live.

## The position

- **Every decision is in the pure core, and the core has function tests.** If a business rule is wrong, a function test fails first, and it names the rule ([Axiom 6](../chapter2/axiom-06-pure-functions.md), [Axiom 13](../chapter2/axiom-13-impureim.md)).
- **So a service test that fails while the function tests pass points at the shell:** the wiring, the mapping, the database, or a simulator. The search is already narrowed to the part with no decisions in it.
- **The shell is thin, so that search is short.** A handler that gathers, calls one pure function and acts on its result has a handful of lines where something can go wrong.

## Why

- **Failures sort themselves by level.** A wrong decision fails a function test, which names the rule. A wrong wiring or mapping fails a service test while the function tests stay green. Which level failed already says what kind of bug it is.
- **It is the same property that makes a good oracle.** [Chapter 1](../chapter1/README.md#the-goal-a-codebase-that-is-a-search-oracle) asks an oracle to say *where* and *why* when it says no. The compiler does it best. Function tests do it for decisions. Service tests do it well enough for a thin shell.
- **Unit tests of the shell would add little.** A mocked controller test that fails says a call happened in a different order. That is rarely the bug that matters.

## Example

A refund is approved by a pure function and saved by a handler.

- `DecideRefund(order, request, today)` is function-tested: one test per rule (too late, already refunded, partial amount).
- A service test posts a refund request and reads the row back.

If the service test fails with *"cannot insert NULL into column `refunded_at`"* while every `DecideRefund` test passes, the rule is fine and the mapping from the decision to the row is not. Nobody has to step through the business logic to find that out.

## When not to

- **When logic has leaked into the shell.** A handler that branches on business conditions is no longer thin, and a failing service test no longer points anywhere useful. The fix is to move the logic into the core, not to unit-test the handler (see the open question in [Testing the core and the whole](01-testing-the-core-and-the-whole.md#trade-offs--when-not-to)).
- **When a failure depends on timing or concurrency.** A service test can show that something goes wrong under load or interleaving without showing where. Those failures need their own investigation, whatever the test levels.
