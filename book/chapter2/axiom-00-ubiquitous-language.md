# Axiom 0 — Ubiquitous Language

**One name per concept, one concept per name: the same word in the conversation and in the code.**

- Give each domain concept exactly one name, taken from the domain. Use it unchanged everywhere: types, functions, parameters, fields, tests, and the sentence you say out loud about it.
- Never two names for one concept (synonyms). Never one name for two concepts (homonyms).

This axiom builds nothing on its own. Most of the rest of this book is a way of taking one of these names and making the compiler hold you to it.

---

## Definitions

> A vocabulary shared by the people who discuss the domain and the code that implements it: one word per concept, unchanged from the whiteboard to the type name.

The term comes from Domain-Driven Design [1]. This axiom takes only the half that shapes code: the *words in the source*, meaning what you call a type, a function, a parameter or a variable. It is not about team rituals or how to split a system (see *When NOT to*).

"One term, one thing, everywhere" holds three claims:

- **One term per concept.** What the domain calls a *shipment* is `Shipment` in the code. Not `Order` in the API, `txn` in the table and `data` in the function that moves it.
- **One concept per term.** A word means exactly one thing. An `Order` that means both *a purchase* and *a sort direction* is two concepts with one name. Split them.
- **Everywhere.** The word is the same wherever the concept appears: the type, every function that takes or returns it, the variable that holds it, the test that checks it, and the conversation about it. Listening to two engineers, you should not be able to tell whether they are talking about the code or the domain.

---

## Example

The same function, in framework words and in the domain's words:

```csharp
// ❌ technical / CRUD vocabulary: every name is a translation step
bool Process(Dictionary<string, object> data, int type) { … }

// ✅ the domain's words: the signature reads like the sentence you'd say
ShippingLabel PrintLabel(Shipment shipment, Carrier carrier) { … }
```

A synonym scatter, and its fix:

```java
// ❌ one concept, three names across three files
class Debtor  { … }   // billing
class Payer   { … }   // invoicing
class Account { … }   // ledger   — all the same "customer who owes money"

// ✅ one concept, one name, used everywhere
class Debtor { … }
```

A homonym, split apart:

```csharp
// ❌ one word, two concepts
enum Order { Ascending, Descending }      // a sort direction
record Order(CustomerId Buyer, …);        // a purchase

// ✅ each concept gets its own word
enum SortDirection { Ascending, Descending }
record PurchaseOrder(CustomerId Buyer, …);
```

The compiler enforces none of this yet: `Process` compiles as happily as `PrintLabel`. That is what the axioms that follow are for. They are how a chosen name stops being optional.

---

## Problem / forces

Naming is one of the hard parts of programming [2], and a bad name costs you on every read, forever.

Left alone, names drift. The domain expert says *shipment*, the REST layer says *order*, the database says `txn`, the method is `Process` and the variable is `data`. Each rename is a translation step: a place where the reader has to map "what they said" onto "what the code calls it", and a place where a misunderstanding becomes a bug.

- **Synonyms** scatter one concept across the codebase under several names. Changing the concept means finding all of them.
- **Homonyms** merge two concepts under one word. A change meant for one silently lands on the other.

The forces pulling toward drift are always there, and always cheap:

- Technical vocabulary (`Manager`, `Helper`, `Service`, `process`, `handle`, `data`, `item`, `tmp`) is generic and always available. It means nothing in particular, so nobody has to argue about it.
- The domain's own word is sometimes longer, sometimes disputed, and sometimes not yet understood well enough to name.
- Frameworks and tutorials bring their own nouns, and those leak into the model.

One pull in the other direction is valid: plumbing with no domain meaning should not be dressed up in business words (see *When NOT to*).

---

## Why

**1. The name is documentation that cannot go out of date.**
A `Shipment` that means *shipment* everywhere needs no comment to explain it, and so has no comment that can drift out of sync. Precise domain names are cheap, durable documentation, and they sit exactly where the reader already is.

**2. One word removes the translation layers.**
Every alias for a concept is a seam between two vocabularies, and seams are where misreadings happen. Naming the concept once, the same way everywhere, removes those seams.

When two parts of a system must agree on what a word *means*, and that agreement lives only in people's heads, it is one of the most fragile kinds of coupling. A single, exact, shared name is the cheapest fix: the agreement moves out of people's heads and into the code, where you can see it.

**3. It is the starting point; the rest of this book enforces it.**
On its own, a good name is only a convention. Nothing stops the next person from ignoring it. Almost every later axiom takes one of these names and makes it impossible to bypass:

- a *type* that **is** a domain concept, instead of a bare `string`;
- a *signature* that **names** every outcome it can produce, instead of hiding them;
- a *value* whose construction guarantees it deserves its name;
- a closed set of named *cases*, instead of an untyped flag.

This axiom supplies the words; the mechanisms that follow turn each word into code. So this is not the weakest axiom in this book because nothing enforces it. It is the one the others exist to enforce.

**4. You act on it while you write, not after.**
You don't find a naming problem after the design is done, the way you find a smell. You ask *"what does the domain call this?"* as you type the name, before any structure exists. It is a question you can act on at the keyboard, which is what [Chapter 1](../chapter1/README.md) asks of every building block.

---

## Trade-offs

- **You pay in name length and in learning.** The domain's word is sometimes longer or more awkward than `data`. You use it anyway, because a precise long name beats a short lie. And you have to actually learn the domain's vocabulary, which the generic word lets you skip.
- **The right word changes.** As the domain is better understood, the right name changes, and a rename touches every place it appears. Tooling makes the mechanical rename cheap. Agreeing on the new word is the hard part.
- **The compiler cannot check it.** Nothing flags "this is the wrong domain word" or "you used two words for one concept". Choosing the right name stays a human judgment, made at the keyboard and confirmed in review. The rest of this book makes a *chosen* name impossible to bypass. It cannot tell you it was the right name.

---

## When NOT to

- **Outside the domain core.** Code with no domain meaning (a generic cache, a retry wrapper, a `Pipeline<T>`) should use the language of *its* layer, infrastructure, not business words. The rule is "speak the language of the layer you are in". Most code in this book just happens to live in the domain layer.
- **One language per model, not one global dictionary.** The same word can legitimately mean different things in *billing* and in *shipping*. Forcing one meaning across a whole system is the *strategic* form of this idea (bounded contexts and the maps between them). That is system decomposition, out of scope here. This axiom covers the names *inside one model's code*, not the translation between models.
- **Don't invent jargon.** *Ubiquitous* means *shared with the people who know the domain*, not *dressed up to sound domain-like*. If the experts say "cancel", the type is `Cancel`, not `TerminationRequest`.

---

## References

[1] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley (2003). Coined *Ubiquitous Language*: a language built around the domain model and used by the whole team, in speech and in code, to connect the model to the implementation. This axiom keeps only the half that shapes code. The strategic parts (bounded contexts, context maps) are out of scope (see the [playbook scope](../../README.md#scope)).

[2] **Phil Karlton**, widely attributed: *"There are only two hard things in Computer Science: cache invalidation and naming things."* The folklore admission that naming is a first-order problem, not a finishing touch.

---

← [Chapter 2 Contents](README.md) · Next: [Axiom 1 — Data is not Behavior](axiom-01-data-vs-behaviour.md) →
