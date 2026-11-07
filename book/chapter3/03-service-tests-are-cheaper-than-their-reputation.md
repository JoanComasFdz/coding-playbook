# Service tests are cheaper than their reputation

Tests that run a whole service with its real dependencies have a reputation: slow to run, hard to write, painful to maintain. That reputation is part of why so many codebases test their shell with mocks instead.

Much of it is out of date.

## The position

- **Run the service in-process, with its real dependencies in containers.** Frameworks can host the whole service inside the test process and call its endpoints directly, and container tooling can start a real database for the test run. A service test then calls an endpoint and checks the result, the way a user of the service would.
- **Simulate only what you don't own.** Third-party systems are replaced by simulators that behave like the real thing at the protocol level. Your own database is not simulated: it is the real one, in a container.
- **Write fewer, broader tests.** One service test covers the handler, the mapping and the database access of a path together. A few per path are enough, because the decisions are already covered by function tests ([Testing the core and the whole](01-testing-the-core-and-the-whole.md)).

## Why

- **Starting is the slow part; running is not.** Starting a database container takes seconds, once per test run. After that, a request that validates input and writes a row takes milliseconds. Spread over a whole suite, the startup cost is small.
- **They are cheaper to keep than the mocks they replace.** A mocked test has to be updated every time the wiring changes. A service test only changes when the service's behavior changes.
- **They find what mocks can't.** A wrong column type, a missing migration, a serialization mistake: these only show up against the real thing.

## Example

> **To do.** A service test in C# and Java: the service hosted in-process, a database in a container, one endpoint called, and the stored row checked.

## When not to

- **The setup is real work.** Containers, test data, simulators and their upkeep cost time, most of all in a service with many dependencies. The cost is lower than its reputation, not zero.
- **Very large suites still add up.** Thousands of service tests are slow, however fast each one is. Keep them to the paths that matter, and push every decision down into function tests.
- **Tools are dated choices.** Testcontainers, ASP.NET Core's in-process test host, WireMock and similar tools change over time. Which ones to use is a contextual choice for an ADR, not part of this position.
