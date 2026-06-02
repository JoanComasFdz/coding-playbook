# Axiom 6 — Cohesion

**A function is cohesive when it has exactly one reason to change — one input shape, one decision, one output shape. Group code together, and split it apart, by reason-to-change; never by surface similarity.**

- A function with one reason to change can be described without the word "and." The moment the honest description needs an "and," the function is doing two jobs.
- The metric is *reason-to-change*, not how alike two pieces of code look. Two functions that read identically but change for different reasons are **not** duplication; one function that reads as a unit but changes for two reasons is not cohesive.

[Axiom 5](axiom-05-honest-total-signatures.md) made the signature *honest* — every outcome named, every input defined. But a signature can tell the whole truth and still promise too much: a function that validates an order *and* prices it *and* records the decision has a perfectly honest signature wrapped around three jobs. Purity (Axiom 4) and honesty (Axiom 5) constrain what a function may do to its inputs and how it must report its outcomes; this axiom constrains *how much it should decide at all*. Honest, total, **and cohesive** is the full criterion for a well-formed function — and cohesion is the one of the three the compiler cannot check for you.

---

## Definitions

**One reason to change.** The phrase is borrowed from the Single Responsibility Principle, but the playbook pins it to a function, where it becomes testable instead of philosophical. A cohesive function has:

- **one input shape** — the parameters describe a single kind of request, not a grab-bag with a mode selector;
- **one decision** — the body resolves a single question, not several stapled together;
- **one output shape** — the return type names the outcomes of *that* decision, nothing more.

If a function takes a `bool`/enum that switches its body between two behaviours, it has two reasons to change living in one place. That is the symptom; "one reason to change" is the property.

**Reason-to-change, not similarity.** This is the load-bearing distinction. *Similarity is not a good or sufficient property for merging code.* The right question is never "do these two pieces look alike?" but "will they change *together*, for the *same* reason?" Two functions can be byte-for-byte similar today and still belong apart, because next quarter one tracks a billing rule and the other a tax rule, and those rules move independently. Merge them on similarity and every future change to one becomes a risk to the other.

**Both directions, one metric.** Reason-to-change tells you when to *split* (one function, one job) and when to *group* (code that changes together lives together). They are the same rule read forwards and backwards, not two principles.

> **Relationship to SOLID and CUPID.** SRP names the right instinct — "a class should have one reason to change" — but at the class level "responsibility" is open to interpretation, and two readers rarely draw the boundary in the same place. Pinned to a function, the instinct sharpens into something you can actually check: one input shape, one decision, one output shape. It is also CUPID's *Unix-philosophy* pillar — *do one thing well*. This axiom is not a critique of those frameworks; it is the function-level form of the property they both gesture at, which is the level this playbook works at.

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

The `bool isReceipt` is the tell. One function now carries two reasons to change: invoice rules and receipt rules share a body and an `if`. The day receipts grow a second marker, you reopen the function that also renders invoices — and the diff touches code that had no business changing. Similarity bought you a shared body and a shared blast radius. The flag is *boolean-blind* at the call site as well — `RenderLine(item, true)`: true of *what*? — the surface tell [Axiom 5](axiom-05-honest-total-signatures.md) names; but the unreadable argument is the lesser fault here, and two reasons to change sharing one body is the one that costs you.

Cohesion splits by reason-to-change, and extracts only the part that is *genuinely* one concept:

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

`FormatMoney` is shared because it *is* one concept with one reason to change — the way the system renders money. The two render functions are kept apart because they are two concepts with two reasons to change, no matter how alike they looked. The flag is gone, and so is the coupled blast radius: a change to receipts touches `RenderReceiptLine` and nothing else.

---

## Problem / forces

The competing force is **DRY pressure**, and it is a real force, not a strawman. Genuine duplication of a single concept *is* a maintenance hazard: the rule that lives in five copies is the rule someone updates in four. The instinct to remove repetition is correct often enough that it hardens into a reflex — for many engineers it becomes the *only* code-quality rule they reach for, applied to any two fragments that resemble each other. The reflex misreads the rule: in Hunt and Thomas's original, DRY is about *knowledge* — *"every piece of knowledge must have a single, authoritative, unambiguous representation"*[5] — not about *code text*, and two fragments that merely resemble each other need not encode the same knowledge. Reason-to-change is that rule made operational: one piece of knowledge is exactly what changes for one reason.

The cost lands when the reflex fires early, on **similarity that is not yet sameness**. Two fragments look alike at the moment you write them, so you extract a shared helper. Then the callers' reasons-to-change diverge — and the helper grows a `bool`, then an enum, then a branch per caller, until it is a small framework that every caller must thread arguments through and no caller fully owns. The merge that was supposed to reduce duplication has instead coupled two things that wanted to move independently. Sandi Metz's rule applies: *duplication is far cheaper than the wrong abstraction*, because duplication is local and visible, while the wrong abstraction is a shared dependency that fights every future change.

The discipline is to wait for the reason-to-change to reveal itself before committing to a shape — the **rule of three**: tolerate the duplication until you have seen the same thing change, for the same reason, enough times to be sure it is one concept and not two that rhyme.

---

## Why

**1. One reason to change is the unit you can hold in your head.**
A function with one input shape, one decision, and one output shape fits in a single frame: you can read it, test it, and review it without paging in a second context. The honest signature of [Axiom 5](axiom-05-honest-total-signatures.md) tells you *what* outcomes exist; cohesion keeps the count of decisions behind those outcomes at one, so the signature stays small enough to be honest about. Two jobs in one function means two test matrices multiplied together and a review that has to reason about their interaction.

**2. Reason-to-change is a better metric than similarity.**
Similarity asks "do these look alike?"; reason-to-change asks "will they move together?" — and only the second question predicts what a future edit will cost. Code that is genuinely one concept — it changes in one place, for one reason — earns a single home; code that merely rhymes does not, and merging it buys a shared blast radius for nothing. This is the simplicity-first move: cohesion *removes* a rule — "de-duplicate on sight" — and replaces it with a sharper one that fires less often, and more accurately, on sameness rather than resemblance.

**3. A cohesive function is the unit that composes.**
Functions that each resolve a single question snap together; functions that each resolve three resist it. When a behaviour is built from small, single-purpose pieces, you can see each contract at a glance, and a changing requirement lands on the one piece that owns that reason rather than on a tangle that owns several. That is why cohesion sits beside [Axiom 5](axiom-05-honest-total-signatures.md) at the foundation: an honest, total, single-purpose function is the cleanest building block there is.

**4. Group-by-reason scales — but the axiom stops at the function.**
The same metric, pointed at a directory instead of a function, says "code that changes together belongs together" — which is what feature-folder and vertical-slice layouts are reaching for. That is a real and good instinct, but it is *topology*, and this is a coding playbook: the axiom claims only the function-level form and notes the rest as out of scope.

---

## Trade-offs

The real cost is that **cohesion is a judgment call the compiler will not make for you.** Purity, honesty, and totality are visible in a signature; "one reason to change" is a claim about the future, and the future is exactly what you cannot see when you write the function. Two pieces of code may genuinely share one reason to change today and split into two tomorrow — or look like two and turn out to be one. The axiom does not pretend to resolve this statically; it gives you the right *question* and pairs it with the rule of three so you are not forced to guess on first sight.

The second cost is that cohesion sometimes tells you to **keep duplication you are itching to remove**, and you have to be willing to. Holding two similar-looking functions apart, on the bet that their reasons-to-change differ, feels like leaving money on the table — right up until the change that would have rippled through a shared helper touches only one of them.

---

## When NOT to

- **When the repetition is one genuine concept.** Cohesion is not a licence to never share code. A single rule — money formatting, a domain calculation, one validation — that recurs and changes *for one reason* should be extracted; that is DRY being right, and reason-to-change agrees with it. The axiom sharpens *when* to share, it does not forbid sharing.
- **When "splitting" would shred locality.** Decomposing a function into a swarm of one-line helpers, each technically with "one reason to change," can leave the reader chasing indirection across a file to reconstruct one thought. Cohesion is about reasons-to-change, not line count; a function that does one job is allowed to be several statements long, and keeping those statements together where they can be read in one place is the same instinct, not its opposite. The smell that *does* warrant extraction runs the other way: when a high-level step in the body sits next to a fiddly mechanical detail, forcing the reader to mentally inline that detail to follow the thread, the detail wants a name — but extract it because it is a concept with its own reason to change, not to make every statement sit at one uniform altitude. (This is where the old "code locality" idea lives — it is cohesion read at reading-distance, not a separate rule.)

---

## References

[1] **Sandi Metz**, *The Wrong Abstraction*, sandimetz.com, 2016. The essay behind "duplication is far cheaper than the wrong abstraction" — the clearest statement of why premature de-duplication costs more than the repetition it removes.
<https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction>

[2] **Robert C. Martin**, *Clean Architecture: A Craftsman's Guide to Software Structure and Design*, Prentice Hall, 2017. The source of the "one reason to change" framing of the Single Responsibility Principle, later refined to "responsible to one actor." This axiom is its function-level specialization.

[3] **Dan North**, *CUPID — for joyful coding*, dannorth.net, 2022. Proposes properties over principles; its *Unix philosophy* pillar — "do one thing well" — is the same instinct as function-level cohesion.
<https://dannorth.net/cupid-for-joyful-coding/>

[4] **Martin Fowler**, *Refactoring: Improving the Design of Existing Code*, 2nd ed., Addison-Wesley, 2018. Home of the **rule of three** (attributed to Don Roberts): refactor toward an abstraction when you have seen the duplication a third time, not the first — the discipline that keeps reason-to-change from being a guess.

[5] **Andrew Hunt & David Thomas**, *The Pragmatic Programmer*, Addison-Wesley, 1999 (20th-anniversary ed. 2019). Source of the DRY principle in its original, often-forgotten form — *"every piece of knowledge must have a single, authoritative, unambiguous representation within a system"* — about knowledge, not duplicated code text. The misreading this axiom corrects is DRY applied to text instead of knowledge.
