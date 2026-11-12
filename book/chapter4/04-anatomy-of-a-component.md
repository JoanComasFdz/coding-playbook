# Anatomy of a Component

> **Work in progress.** This draft covers one part of the Play: how the code inside a component is laid out by visibility. The rest is still to do (see *Still to write*). The layout is something I am trying out, not yet something I have settled on.

A [component](../chapter2/README.md#components) is a deployable unit or a library. Its callers see its API and nothing else. This Play is about the inside view: where the public code goes, where the private code goes, and how a reader tells them apart without opening every file.

Like every Play, it adds no new principle. It is [Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md#encapsulation-read-precisely)'s "hide only secrets" and the [*Information hiding*](03-information-hiding.md) Play, applied to the folder layout of one component.

## Problem / forces

- **The public surface is scattered.** In a typical project, public and internal types sit side by side in the same folders. To learn what a component offers, a caller (or a reviewer) has to open every file and read its access modifier.
- **A name is not a boundary.** A folder or namespace called `Internal` tells the reader something, but the compiler doesn't check it. ASP.NET Core used `*.Internal` namespaces for types that stayed `public`, called "pubternal" APIs, and made most of them truly `internal` in .NET Core 3.0, because leaving them public "was confusing to customers" [3].
- **The language decides what can be enforced.** C# has an assembly boundary (`internal`). Java's package-private stops at the package, and a subpackage is an unrelated package (see *Java*).
- **Frameworks have their own conventions for the entry point.** In .NET, a library registers itself through an `Add{Service}` extension method on `IServiceCollection` [4]. The layout has to leave room for it.

## What I do today

- **The root of the component is its public API.** Every public type lives at the root, and nothing else does.
- **One `Internal/` folder holds everything else,** all marked `internal`. The folder tells the reader; the keyword lets the compiler enforce it.
- **A type used by both goes to the root.** A value object that appears in the API's signatures is public, even when the internals use it too. Inside, it is already-validated data ([Axiom 19](../chapter2/axiom-19-value-objects.md)).
- **No `Public/` folder.** The root already means public, so a `Public` segment adds a `using` to every caller and no information.
- **`Api.cs` declares the contract.** The delegates the component offers ([Axiom 10](../chapter2/axiom-10-first-class-functions.md)), and the records and enums they take and return, in one file. A reader learns the whole surface from one file.
- **`ServiceCollectionExtensions.cs` is the entry point the framework shapes** ([Axiom 13](../chapter2/axiom-13-impureim.md#definitions)): one `Add{Feature}` method that wires the internals to the delegates in `Api.cs`.
- **Visibility and purity are two different splits.** `Internal/` holds both the pure core (static modules) and the impure shell (a `BackgroundService`, an adapter). The layout says who may call a type, not whether it has effects. [Axiom 13](../chapter2/axiom-13-impureim.md) still decides that.
- **Slices go inside `Internal/`.** When a component grows, its internals are grouped by feature ([*Vertical slices*](02-vertical-slices.md)): `Internal/Sampling/`, `Internal/Collection/`. The root stays flat, because it is the interface, and an interface should be small.

## Why

- **The surface is visible.** "What does this component offer?" is answered by listing the root folder. "Is this type part of the API?" is answered by its path. That is [Axiom 1](../chapter2/axiom-01-explicit-over-implicit.md) at folder grain: what a caller needs is visible where it looks.
- **The secret has one home.** Everything likely to change sits under `Internal/`, behind the surface ([*Information hiding*](03-information-hiding.md)). Changing it changes no caller.
- **The compiler enforces it, not convention.** In C#, a caller can't reach an `internal` type, whatever its folder. The folder only has to match the keyword.
- **It is not a new idea.** Go builds it into the toolchain: since Go 1.4, a package under a directory named `internal` can only be imported from the tree rooted at its parent [1]. The Eclipse platform has the same rule as a naming convention: a package with `internal` in its name is not API, and other components must not reference it [2].

## C# example

> **To do.** The ProcessMonitoring component from my reference-service comparison as the example: the root with `Api.cs`, `ServiceCollectionExtensions.cs` and the value objects, and `Internal/` with the core module and the background service.

## Java

Java has no assembly boundary. Package-private access stops at the package, and `com.example.monitoring.internal` is a different package from `com.example.monitoring`, so a type in the subpackage has to be `public` to be used from the root. That brings back the pubternal problem. Two ways out:

- **Keep the internals in the same package as the API,** package-private, with no `internal` subpackage. Enforced by the compiler; the reader tells API from internals by the modifier, not the folder.
- **Use a JPMS module** (Java 9 and later). The `module-info.java` exports the API package and not the `internal` one, so code outside the module can't reach it, however `public` it is.

> **To do.** Which one I pick, and the example.

## Trade-offs & when NOT to

- **A check the compiler doesn't make.** Nothing stops a `public` type in `Internal/`, or an `internal` one at the root. A review rule or an architecture test closes the gap; the tool is a choice for an ADR.
- **Tests that need internals.** `InternalsVisibleTo` lets a test project see `internal` types. Pure functions under `Internal/` can be function-tested that way; everything else is tested through the API ([Chapter 3](../chapter3/README.md)).
- **Tiny components.** A component with one public file and one internal file gains little from a folder.
- **Generated or framework-required types.** Some frameworks need public types (a controller, a serializer target). They go where the framework needs them, and the layout bends.

## What might change tomorrow

- Whether value objects stay at the root, or in a root subfolder named by concept.
- Whether one `Api.cs` stays readable as a component grows, or splits into one file per concept at the root.
- The Java choice: same package, or a JPMS module.
- Whether the same layout works for a deployable service, which adds a composition root and its own dependencies.

## Still to write

From the scope in the [Chapter 4 README](README.md):

- **The API, API-first,** as [Chapter 3](../chapter3/README.md) requires of component tests.
- **The shell's handlers** as ordinary classes, and **the core's static modules.**
- **The adapters** to systems owned by others.
- **A service vs. a library:** the composition root and the service's own dependencies.

## References

[1] **Go**, *Go 1.4 Release Notes*, "Internal packages", 2014. An `internal` directory's packages can only be imported from the tree rooted at its parent; the design is in Russ Cox's document at golang.org/s/go14internal.
<https://go.dev/doc/go1.4>

[2] **Jim des Rivières**, *How to Use the Eclipse API*, Eclipse Corner, 2001. Packages with `internal` in their name are not API; clients must not reference another component's internal packages.
<https://eclipse.googlesource.com/www.eclipse.org/articles/+/refs/heads/master/Article-API-Use/index.html>

[3] **Microsoft**, *Breaking changes in .NET Core 3.0*, "Pubternal APIs removed". Most types in `*.Internal` namespaces became truly `internal`.
<https://learn.microsoft.com/dotnet/core/compatibility/3.0>

[4] **Microsoft**, *Options pattern guidance for .NET library authors*. Registration methods are named `Add{Service}`, in a static class named `{Type}Extensions`.
<https://learn.microsoft.com/dotnet/core/extensions/options-library-authors>

> **Sources to verify before citing:** Simon Brown, "Package by component", in Robert C. Martin, *Clean Architecture* (2017), ch. 34, "The Missing Chapter": one public interface per component, everything else package-private. So far read only in secondary summaries.
