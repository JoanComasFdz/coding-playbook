# Axiom 0 — Ubiquitous Language

**One name per concept, one concept per name — the same word in the conversation and in the code.**

- Give each domain concept exactly one name, taken from the domain, and use it unchanged everywhere it appears: types, functions, parameters, fields, tests, and the sentence you say out loud about it.
- Never two names for one concept (synonyms), never one name for two concepts (homonyms).

It builds nothing on its own. Most of the rest of the book is a way of taking one of these names and making the compiler hold you to it.

---

## Definitions

> The vocabulary the people who discuss the domain and the code that implements it share — one word per concept, that word unchanged from the whiteboard to the type name.

The term comes from Domain-Driven Design[1]. This axiom takes only its **code-shaping** half: it is about the *words in the source* — what you call a type, a function, a parameter, a variable — not about team ritual or system decomposition (see *When NOT to*).

Three claims hide in "one term, one thing, everywhere":

- **One term per concept.** The thing the domain calls a *shipment* is `Shipment` in code — not `Order` in the API, `txn` in the table, and `data` in the function that moves it.
- **One concept per term.** A word means exactly one thing. `Order` that means both *a purchase* and *a sort direction* is two concepts wearing one name; split them.
- **Everywhere.** The word is the same at every layer the concept surfaces — the type, every function that takes or returns it, the variable that holds it, the test that exercises it, and the conversation about it. A reader should not be able to tell whether two engineers are discussing the code or the domain.

---

## Problem / forces

Naming is the hard part of programming, and the cost of getting it wrong is paid on every read, forever.

The default is drift. The domain expert says *shipment*; the REST layer says *order*; the database says `txn`; the method is `Process`; the variable is `data`. Each renaming is a translation step — a place where a reader has to re-map "what they said" onto "what the code calls it," and a place where a misunderstanding becomes a defect. **Synonyms** scatter one concept across the codebase under several aliases, so a change to the concept means finding all of them. **Homonyms** fuse two concepts under one word, so a change meant for one silently lands on the other.

The forces pulling toward drift are always present and always cheap:

- Technical and CRUD vocabulary (`Manager`, `Helper`, `Service`, `process`, `handle`, `data`, `item`, `tmp`) is generic, always available, and means nothing in particular — so it never has to be argued about.
- The domain's own word is sometimes longer, sometimes contested, and sometimes not yet understood well enough to name.
- Frameworks and tutorials supply their own nouns, and those leak into the model.

The competing pull this axiom does *not* deny: plumbing that has no domain meaning should not be dressed in business words (see *When NOT to*).

---

## Why

**1. The name is the documentation that cannot go stale.**
A `Shipment` that means *shipment* everywhere needs no comment to explain it, and no comment that can rot out of sync with it. Precise domain names are the cheapest, most durable documentation there is — and they live exactly where the reader already is.

**2. One word collapses the translation layers.**
Every alias for a concept is a seam between two vocabularies, and seams are where misreadings live. Naming the concept once, the same way at every layer, removes those seams. When two parts of a system must agree on what a word *means* and that agreement lives only in people's heads, it is the most fragile coupling there is; a single shared, exact name is the cheapest cure — it turns an agreement-by-convention into an agreement the code can show you.

**3. It is the enabler — the rest of the book gives these names teeth.**
On its own, a good name is only a convention; nothing stops the next person from ignoring it. Almost every other axiom is a way of taking one of these names and making it un-bypassable: a *type* that **is** a domain concept rather than a bare `string`; a *signature* that **names** every outcome it can produce instead of hiding them; a *value* whose construction guarantees the word is earned; a closed set of *cases*, each named, instead of an untyped flag. The discipline supplies the words. The mechanisms that follow are where each word gets compiled in. Read that way, this axiom is not the weakest in the book for lacking enforcement — it is the one the others exist to enforce.

**4. It is generative, not a grade.**
You do not spot a naming problem after the design is finished, the way you spot a smell. You answer *"what does the domain call this?"* as you type the name — before any structure exists. It is a question you can act on at the keyboard, which is the whole bar this book holds a building block to.

---

## C#/Java example

The same function, in framework words and in the domain's words:

```csharp
// ❌ technical / CRUD vocabulary — every name is a translation step
bool Process(Dictionary<string, object> data, int type) { … }

// ✅ the domain's words — the signature reads like the sentence you'd say
ShippingLabel PrintLabel(Shipment shipment, Carrier carrier) { … }
```

```java
// ❌ a synonym scatter: one concept, three names across three files
class Debtor  { … }   // billing
class Payer   { … }   // invoicing
class Account { … }   // ledger   — all the same "customer who owes money"

// ✅ one concept, one name, used everywhere
class Debtor { … }
```

And the homonym, split apart:

```csharp
// ❌ one word, two concepts
enum Order { Ascending, Descending }      // a sort direction
record Order(CustomerId Buyer, …);        // a purchase

// ✅ each concept gets its own word
enum SortDirection { Ascending, Descending }
record PurchaseOrder(CustomerId Buyer, …);
```

None of this is enforced by the compiler yet — `Process` compiles as happily as `PrintLabel`. That is the point of the axioms that follow: they are how a chosen name stops being optional.

---

## Trade-offs

- **You pay in name length and in learning.** The domain's word is sometimes longer or more awkward than `data` — you take it anyway, because a precise long name beats a short lie. And you have to actually learn the domain's vocabulary, which is work the generic word lets you skip.
- **The right word is a moving target.** As the domain is understood better, the right name changes, and a rename ripples across every site. Modern tooling makes the mechanical rename cheap; agreeing on the new word is the part that is not.
- **It is the one axiom the compiler cannot check.** Nothing flags "this is the wrong domain word" or "you have used two words for one concept." Choosing the right name stays a human judgment — made at the keyboard and confirmed at review. The mechanisms in the rest of the book make a *chosen* name un-bypassable; they cannot tell you it was the right name.

---

## When NOT to

- **Outside the domain core.** Code with no domain meaning — a generic cache, a retry wrapper, a `Pipeline<T>` — should speak the language of *its* layer (infrastructure), not be forced into business words. The rule is "speak the language of the layer you are in"; it just happens that most code in this book lives in the domain layer.
- **One language per model, not one global dictionary.** The same word can legitimately mean different things in *billing* and in *shipping*. Forcing a single global meaning across an entire system is the *strategic* form of this idea — bounded contexts and the maps between them — and that is system decomposition, out of scope here. This axiom governs the names *inside one model's code*, not the translation between models.
- **Don't manufacture jargon.** *Ubiquitous* means *shared with the people who know the domain*, not *dressed up to sound domain-y*. If the experts say "cancel," the type is `Cancel`, not `TerminationRequest`.

---

## References

[1] **Eric Evans**, *Domain-Driven Design: Tackling Complexity in the Heart of Software*, Addison-Wesley (2003) — coined *Ubiquitous Language*: a language structured around the domain model and used by all team members, in speech and in code, to connect the model to the implementation. This axiom keeps only that code-shaping half; the strategic apparatus around it (bounded contexts, context maps) is out of scope (see the [playbook scope](../../README.md#scope)).

[2] **Phil Karlton**, widely attributed: *"There are only two hard things in Computer Science: cache invalidation and naming things."* The folklore acknowledgement that naming is a first-order problem, not a finishing touch.
