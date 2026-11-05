# Axiom 7 — Cohesion

**A function is cohesive when it has exactly one reason to change: one input shape, one decision, one output shape. Group code together, and split it apart, by reason to change; never by surface similarity.**

- A function with one reason to change can be described without the word "and". The moment an honest description needs an "and", the function is doing two jobs.
- The metric is *reason to change*, not how alike two pieces of code look. Two functions that read the same but change for different reasons are **not** duplication. One function that reads as a unit but changes for two reasons is not cohesive.

[Axiom 6](axiom-06-honest-total-signatures.md) made the signature *honest*: every outcome named, every input defined. But a signature can tell the whole truth and still promise too much. A function that validates an order *and* prices it *and* records the decision can have a perfectly honest signature around three jobs.

- Purity ([Axiom 5](axiom-05-pure-functions.md)) limits what a function may touch.
- Honesty and totality ([Axiom 6](axiom-06-honest-total-signatures.md)) limit how it reports its outcomes.
- This axiom limits *how much it decides at all*.

Honest, total **and cohesive** is the full test for a well-formed function. Of the three, cohesion gets the least help from the compiler: honesty and totality show up in the types, but "one reason to change" is a judgment about the future.

---

## Definitions

**One reason to change.** The phrase comes from the Single Responsibility Principle [2], but this book applies it to a function, where it becomes checkable instead of philosophical. A cohesive function has:

- **one input shape:** the parameters describe a single kind of request, not a grab bag with a mode switch;
- **one decision:** the body answers a single question, not several stapled together;
- **one output shape:** the return type names the outcomes of *that* decision, nothing more.

If a function takes a `bool` or an enum that switches its body between two behaviors, it has two reasons to change living in one place. The flag is the symptom; "one reason to change" is the property.

**Reason to change, not similarity.** This is the key distinction: *looking similar is not a good enough reason to merge code.* The right question is never "do these two pieces look alike?" but "will they change *together*, for the *same* reason?" Two functions can be identical today and still belong apart, because next quarter one follows a billing rule and the other a tax rule, and those rules change independently. Merge them because they look alike, and every future change to one becomes a risk to the other.

**Both directions, one metric.** Reason to change tells you when to *split* (one function, one job) and when to *group* (code that changes together lives together). It is one rule read in both directions, not two principles. Martin states it in exactly these terms: "Gather together the things that change for the same reasons. Separate those things that change for different reasons." [2]

> **Relationship to SOLID and CUPID.** SRP names the right instinct, "a class should have one reason to change" [2]. But at the class level, "responsibility" is open to interpretation, and two readers rarely draw the boundary in the same place ([Chapter 1](../chapter1/README.md) makes the full argument). Applied to a function, the instinct becomes something you can check: one input shape, one decision, one output shape. It is also CUPID's *Unix philosophy* property, "do one thing well" [3]. This axiom is not a critique of those frameworks. It is the function-level form of the property they both point at, which is the level this book works at.

---

## Example

The DRY reflex says: these two render functions look 90% alike, so merge them.

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// "They're basically the same" — so a flag is born.
public string RenderLine(LineItem item, bool isReceipt)
{
    var amount = item.Amount.ToString("C");
    if (isReceipt)
        return $"{item.Name}  {amount}"
             + (item.TaxExempt ? "  (tax-exempt)" : "");
    return $"{item.PoNumber}  {item.Name}  {amount}";
}
```

</td>
<td>

```java
// "They're basically the same" — so a flag is born.
public String renderLine(LineItem item, boolean isReceipt) {
    var amount = format(item.amount());
    if (isReceipt)
        return item.name() + "  " + amount
             + (item.taxExempt() ? "  (tax-exempt)" : "");
    return item.poNumber() + "  " + item.name() + "  " + amount;
}
```

</td>
</tr>
</table>

The `bool isReceipt` is the giveaway. One function now has two reasons to change: invoice rules and receipt rules share a body and an `if`. The day receipts get a second marker, you reopen the function that also renders invoices, and the diff touches code that had no reason to change. Looking alike bought you a shared body and a shared blast radius.

The flag is also *boolean-blind* at the call site, as [Axiom 6](axiom-06-honest-total-signatures.md) describes: `RenderLine(item, true)`, true of *what*? But the unreadable argument is the smaller problem here. Two reasons to change sharing one body is the one that costs you.

Cohesion splits by reason to change, and extracts only the part that really is one concept:

<table>
<tr><th>C#</th><th>Java</th></tr>
<tr>
<td>

```csharp
// One reason to change each. The only shared concept is money formatting.
public string RenderInvoiceLine(InvoiceLine line) =>
    $"{line.PoNumber}  {line.Name}  {FormatMoney(line.Amount)}";

public string RenderReceiptLine(ReceiptLine line) =>
    $"{line.Name}  {FormatMoney(line.Amount)}"
      + (line.TaxExempt ? "  (tax-exempt)" : "");

private static string FormatMoney(Money amount) =>
    amount.Value.ToString("C");
```

</td>
<td>

```java
// One reason to change each. The only shared concept is money formatting.
public String renderInvoiceLine(InvoiceLine line) {
    return line.poNumber() + "  " + line.name()
         + "  " + formatMoney(line.amount());
}

public String renderReceiptLine(ReceiptLine line) {
    return line.name() + "  " + formatMoney(line.amount())
         + (line.taxExempt() ? "  (tax-exempt)" : "");
}

private static String formatMoney(Money amount) {
    return amount.format();
}
```

</td>
</tr>
</table>

`FormatMoney` is shared because it *is* one concept with one reason to change: the way the system displays money. The two render functions stay apart because they are two concepts with two reasons to change, no matter how alike they looked. Each now also takes its own input type (`InvoiceLine`, `ReceiptLine`): one input shape each. The flag is gone, and so is the shared blast radius. A change to receipts touches `RenderReceiptLine` and nothing else.

---

## Problem / forces

The competing force is **DRY pressure**, and it is real. True duplication of one concept *is* a maintenance hazard: a rule that lives in five copies is a rule someone updates in four. Removing repetition is right often enough that it hardens into a reflex. For many engineers it becomes the *only* code-quality rule they reach for, applied to any two pieces of code that look alike.

That reflex misreads the rule. In Hunt and Thomas's original, DRY is about *knowledge*, "every piece of knowledge must have a single, authoritative, unambiguous representation within a system" [5], not about *code text*. Two pieces of code that merely look alike don't necessarily encode the same knowledge. Reason to change makes the original rule usable: one piece of knowledge is exactly what changes for one reason.

The cost comes when the reflex fires too early, on **similarity that isn't yet sameness**:

1. Two pieces of code look alike when you write them, so you extract a shared helper.
2. The callers' reasons to change drift apart.
3. The helper grows a `bool`, then an enum, then a branch per caller.
4. It ends up as a small framework that every caller has to thread arguments through, and that no caller fully owns.

The merge that was meant to reduce duplication has instead tied together two things that wanted to move independently. As Sandi Metz puts it, "duplication is far cheaper than the wrong abstraction" [1]: duplication is local and visible, while the wrong abstraction is a shared dependency that fights every future change.

The discipline is to wait until the reason to change shows itself before you pick a shape. That is the [**rule of three**](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)) [4]: put up with the duplication until you have seen the same thing change, for the same reason, often enough to be sure it is one concept and not two that happen to rhyme.

---

## Why

**1. One reason to change is a unit you can hold in your head.**
A function with one input shape, one decision and one output shape fits in your head at once: you can read it, test it and review it without loading a second context. The honest signature of [Axiom 6](axiom-06-honest-total-signatures.md) tells you *what* outcomes exist; cohesion keeps the number of decisions behind them at one, so the signature stays small enough to be honest about. Two jobs in one function means two sets of test cases multiplied together, and a review that has to reason about how they interact.

**2. Reason to change is a better metric than similarity.**
Similarity asks "do these look alike?"; reason to change asks "will they change together?". Only the second question predicts what a future edit will cost. Code that really is one concept (it changes in one place, for one reason) earns a single home. Code that merely rhymes doesn't, and merging it buys a shared blast radius for nothing. This is the simplicity-first move: cohesion *removes* a rule ("remove duplication on sight") and replaces it with a sharper one that fires less often, and more accurately, on sameness instead of resemblance.

**3. A cohesive function is the unit that composes.**
Functions that each answer a single question fit together; functions that each answer three resist it. When a behavior is built from small, single-purpose pieces, you can see each contract at a glance, and a changing requirement lands on the one piece that owns that reason, not on a tangle that owns several. That is why cohesion sits beside [Axiom 6](axiom-06-honest-total-signatures.md) at the foundation: an honest, total, single-purpose function is about as clean a building block as there is.

**4. Grouping by reason scales, but this axiom stops at the function.**
The same metric, pointed at a folder instead of a function, says that code that changes together belongs together. Beck puts it as "put everything that changes at the same time in one place" [6], and his principle of *local consequences* asks for code where a change in one place doesn't force changes elsewhere [7]. Feature-folder and vertical-slice layouts aim for exactly that. That is a real and good instinct, and it belongs one level up, where functions are composed into modules. This axiom claims only the function-level form.

---

## Trade-offs

- **Cohesion is a judgment call the compiler won't make for you.** Honesty and totality show up in a signature. "One reason to change" is a claim about the future, and the future is exactly what you can't see when you write the function. Two pieces of code may share one reason to change today and split into two tomorrow, or look like two and turn out to be one. This axiom doesn't pretend to settle that up front. It gives you the right *question*, and pairs it with the rule of three so you don't have to guess on first sight.
- **Sometimes you have to keep duplication you're itching to remove.** Holding two similar-looking functions apart, betting that their reasons to change differ, feels like leaving money on the table. Right up until the change that would have rippled through a shared helper touches only one of them.

---

## When NOT to

- **When the repetition is one real concept.** Cohesion is not a license to never share code. A single rule (money formatting, a domain calculation, one validation) that repeats and changes *for one reason* should be extracted. That is DRY being right, and reason to change agrees with it. This axiom sharpens *when* to share; it doesn't forbid sharing.
- **When splitting would scatter one thought.** Breaking a function into a swarm of one-line helpers, each with technically "one reason to change", can leave the reader jumping around a file to piece one thought back together. Cohesion is about reasons to change, not line count. A function that does one job is allowed to be several statements long, and keeping those statements together, readable in one place, is the same instinct, not its opposite.

  The smell that *does* call for extraction is different: a high-level step sitting next to a fiddly mechanical detail, forcing the reader to work through the detail to follow the main thread. That detail wants a name. But extract it because it is a concept with its own reason to change, not to make every statement sit at the same level of detail. (This is where the idea of *locality of behavior* lives, "the behaviour of a unit of code should be as obvious as possible by looking only at that unit of code" [8]. It is cohesion at reading distance, not a separate rule.)

---

## References

[1] **Sandi Metz**, *The Wrong Abstraction*, sandimetz.com, 2016. The essay behind "duplication is far cheaper than the wrong abstraction": the clearest statement of why removing duplication too early costs more than the repetition it removes. <https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction>

[2] **Robert C. Martin**, *Agile Software Development: Principles, Patterns, and Practices*, Prentice Hall, 2002, which states the Single Responsibility Principle as "a class should have only one reason to change"; restated in *Clean Architecture*, Prentice Hall, 2017, as "responsible to one, and only one, actor". The "gather together / separate" wording is from his post *The Single Responsibility Principle*, 8 May 2014: <https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html>. This axiom is its function-level form.

[3] **Dan North**, *CUPID — for joyful coding*, dannorth.net, 2022. Proposes properties over principles. Its *Unix philosophy* property, "do one thing well", is the same instinct as function-level cohesion. <https://dannorth.net/cupid-for-joyful-coding/>

[4] **Martin Fowler**, *Refactoring: Improving the Design of Existing Code*, 2nd ed., Addison-Wesley, 2018. Home of the **rule of three** (attributed to Don Roberts): refactor toward an abstraction when you see the duplication a third time, not the first. It is what keeps reason to change from being a guess.

[5] **Andrew Hunt & David Thomas**, *The Pragmatic Programmer*, Addison-Wesley, 1999 (20th-anniversary ed. 2019). Source of the DRY principle in its original, often-forgotten form: *"every piece of knowledge must have a single, authoritative, unambiguous representation within a system"*. It is about knowledge, not duplicated code text. The misreading this axiom corrects is DRY applied to text instead of knowledge.

[6] **Kent Beck**, *Cohesion*, Software Design: Tidy First? (newsletter), 1 November 2022: "put everything that changes at the same time in one place". <https://newsletter.kentbeck.com/p/cohesion>

[7] **Kent Beck**, *Implementation Patterns*, Addison-Wesley, 2007, ch. 3 ("A Theory of Programming"). The first of its six principles, *Local Consequences*: structure the code so that changes have local consequences.

[8] **Carson Gross**, *Locality of Behaviour (LoB)*, htmx.org, 29 May 2020. <https://htmx.org/essays/locality-of-behaviour/>

---

← Previous: [Axiom 6 — Honest, total signatures](axiom-06-honest-total-signatures.md) · Next: [Axiom 8 — Connascence](axiom-08-connascence.md) →
