<details>
<summary>

## Total Beginner’s Guide

</summary>

Completely baffled by Nix? By Lisp? Do you see a bunch of letter spaghetti and wonder, why would anybody care about this? Me too, friend. Me too.

The worlds of Lisp and Nix are both independently confusing and idiosynratic. It’s a match made in hell.

<details>

<summary>

### Practical Example: Easy Mode: `nix-shell`

</summary>

If you’re really, utterly confused by how to install anything, but for some magical reason you do have Nix available (wat), this is by far the easiest way to get something working.

Enter the [`nix-shell` example](examples/channels/nix-shell) and run `nix-shell`. Tada: you have `sbcl` available on the command line, and one lisp package preloaded: `alexandria`:

```
$ cd examples/channels/nix-shell
$ nix-shell
[nix-shell:…/nix-shell]$ sbcl
This is SBCL 2.2.9.nixos, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.
* (require "asdf")
("ASDF" "asdf" "UIOP" "uiop")
* (asdf:load-system "alexandria")
T
* (alexandria:iota 10)
(0 1 2 3 4 5 6 7 8 9)
*
```

Add any other packages to `default.nix` as you need them.

If you have flakes enabled (see [nixos.wiki/wiki/Flakes](https://nixos.wiki/wiki/Flakes)), you can also try the [flake develop example](examples/flakes/flake-develop).

Either way see their respective READMEs for more info.

To actually build a binary executable you can run later, read on.

</details>

<details>

<summary>

### Practical Example: Flakes

</summary>

This is the easiest way to start building a binary, in number of actual steps.

See the [flake example](examples/flake-app).

But, a word of caution: flakes are a layer *on top of Nix*. This is fine as long as it works, but if you really don’t know any Nix at all, it’s yet another thing to learn before you get it.

For some people that’s ideal: they don’t care about the details right now, “just do the easiest thing and get out of my way.” If so then flakes are for you! Also they’re (probably) the future of Nix so it’s a safe bet.

But others, like me, only get confused by layers of abstraction, we’re more “depth first learners”, and seeing yet another thing whose purpose I don’t understand (what problems do flakes solve?) in a language I don’t understand (Nix?) in a paradigm I don’t understand (lazy evaluation?) is far more confusing than a raw low level approach.

Yes, after a month of building my own Lisp-in-Nix implementation, now I understand Nix well enough to understand flakes. And now I love them. But one month ago? No way.

But it really depends on you. Give them a spin, see what sticks.

</details>

<details>

<summary>

### Practical Example: “Channels”

</summary>

Do you want to avoid flakes? Does your system not support flakes? Do you not know what flakes even are and is everything confusing and do you just want to try *something?!*

Try this:

1. Copy [examples/channels/hello-binary](examples/channels/hello-binary) to a fresh directory.

2. Change the top lines in default.nix from:

```nix
{
  ...
}:

with pkgs.lispPackagesLite;
```

into:

```nix
# Get an "original" nixpkgs copy
{
  pkgs ? import <nixpkgs> {}
}:

let
  # This is just the cl-nix-lite source code
  cl-nix-lite = pkgs.fetchFromGitHub {
    owner = "hraban";
    repo = "cl-nix-lite";
    # replace these two lines with the output of
    # nix run nixpkgs#nix-prefetch-github -- hraban cl-nix-lite --rev v0 --nix | grep 'rev\|sha'
    rev = "";
    sha256 = "";
  };
  # Create a copy of nixpkgs with the cl-nix-lite overlay applied
  pkgs' = pkgs.extend (import cl-nix-lite);
in

# Now replace every occurrence of pkgs in this file by pkgs'
with pkgs'.lispPackagesLite;
```

3. Run the following command:

```sh
nix run nixpkgs#nix-prefetch-github -- hraban cl-nix-lite --rev v0 --nix | grep 'rev\|sha'
```

Grab the two lines of output, and replace their corresponding lines in the snippet you just pasted, in step 2.

4. Run `nix-build`

5. Done. You should have your binary in `result/bin/hello`. Feel free to mess around in the source files and rebuild.

</details>

<details>

<summary>

### Background info (confused? start here)

</summary>

Nix, at its core, is a *programming language* that lets you implement every step of a build system: from fetching the source, to building it, to installing it on your system. There is a huge central repository of many such packages across many programming languages, and their compilers, and tools, etc, all implemented in Nix: that’s “nixpkgs”. It contains e.g. GCC, which lets you build other apps, but it also contains useful functions like `fetchFromGitHub`.

People have taken this (too) far. They’ve built an entire Operating System in Nix. It’s NixOS. It started out as an experiment but it’s here to stay. However it is completely unrelated from this entire project: whether you use Nix on your Mac, Windows, existing Linux computer, or NixOS: this project just helps you build Common Lisp projects. And their dependencies.

There you have it:

- Nix: the language. Compare to Python without stdlib, or raw C without even `#include <stdlib.h>`
- nixpkgs: A giant repository of useful helper functions and all conceivable software in the world for every language, in one. The cornerstone of any useful Nix project.
- NixOS: Cool but unrelated.

### Lisp

Common Lisp is a very old family of Lisp, predating C, that managed to stay relevant and modern. Other, completely unrelated lisps, are Clojure (modern) and Emacs Lisp (also old but still relevant).

This entire project is purely about Common Lisp and has nothing to do with the others.

Common Lisp has many different implementations, and its spec is notoriously reticent to define any implementation details. In fact, the spec says nothing about the concept of packages, bundling, compilation (some but very little), “binaries”, etc.

### ASDF

ASDF is a build system for Common Lisp, but not a package repository. It specifies all the “sane” things a normal, ⅯⅯth century programming language should have: from “which file has which piece of code”, to “which files belong together”, and the ability to bundle them into a single “unit”. The only other language I know of which doesn’t have this built-in is C, or JavaScript (but even that is changing). With ASDF, your code organisation feels more like Python than C. More like Node.JS, less like bare JavaScript.

ASDF is close to a `package.json` file actually: it even has `description`, `version`, `author` fields, etc.

Example ASDF definition:

```common-lisp
(defsystem "hello-lisp"
  :description "hello-lisp: a sample Lisp system."
  :version "0.0.1"
  :author "Joe User <joe@example.com>"
  :licence "Public Domain"
  :depends-on ("optima.ppcre" "command-line-arguments")
  :components ((:file "packages")
               (:file "macros" :depends-on ("packages"))
               (:file "hello" :depends-on ("macros"))))
```

ASDF introduces the concept of “systems”, which you might as well call a “module”. Unfortunately the word “package” already means something very specific (and semi advanced) in Lisp, so just avoid it.

*ASDF does **not** offer a package repository!* That means: it’s not Pip, it’s not NPM, it’s not Maven, etc. ASDF needs you to supply all the code somehow. If you don’t already have all necessary dependencies available on your local hard disk, ASDF can’t help you.

<blockquote>

<details>

<summary>

*Note:* This is not about asdf-vm.com.

</summary>

That’s a recent and completely unrelated project
that helps you manage separate versions of Python, Ruby, etc, all in one
tool. If anything, that’d be more a Nix thing, than a Lisp thing. And to make
matters worse: you can manage Lisp versions using asdf-vm. There was
understandable consternation in the Common Lisp community when they announced
the name and it remains extremely confusing. This is the only thing I’ll say
about that project because it’s 100% unrelated.

</details>

</blockquote>

### A word on Package Repositories

Such an obvious part of any ecosystem, why even question their existence? Package repositories: NPM, Pip, Cargo, Maven, ... what’s the problem? The problem: they are all basically the same thing, reimplemented and reinvented in 99%-similar-1%-different ways. Nix *could* completely obviate the need for package repositories.

Notable language that *doesn’t* have a package repository: Go. In Go, you specify imports directly via the source location in code. It comes with its own baggage, but it’s interesting context. It is no coincidence that vendoring code is very common in Go, compared to other languages.

(“Vendoring”: including your dependencies in your own project’s repository. Think `git add node_modules`.)

Theoretically, Nix makes package repositories obsolete. Specifically: nixpkgs makes package repositories obsolete. More specifically: nixpkgs *is* a package repository.[^1]

Practically, most x-language-in-Nix ecosystems are bootstrapped by leveraging their respective existing package repositories. It’s easier for both maintainers and users to just copy all of NPM / Pip / ... into nixpkgs. Maintainers don’t need to worry about where to find each project, or when to update it. Users get a familiar environment. “Oh, this is like NPM / Pip / ..., but with different syntax.”

This lisp-packages-lite project *does* drop the existing Lisp package repository, but that’s only possible because of two peculiarities in the Common Lisp world:

1. Common Lisp code moves slowly, and remains stable for ages. In JavaScript, a package that hasn’t had commits for 2 years is dead. In Common Lisp, it’s completely normal to find and use a package with no commits for >10 years. That means it’s stable. Benefit for lisp-packages-lite: less overhead when maintaining a central repository of "what is every package’s last version?"
2. The Common Lisp ecosystem is relatively small. There are only, what, a few hundred packages? A single human being can maintain it (and he has: Zach Beane maintains the de facto Common Lisp package repository on his own, for >10y now: QuickLisp).

### QuickLisp

Think NPM / Pip for Common Lisp. It is built on top of ASDF. It is a de facto standard. Maintained by Zach Beane. Notable difference: in NPM, all packages are maintained by their respective owners, and updates are published individually. In QuickLisp, Zach sits down every couple of months and fetches the last version of every package, tests them all, and publishes a new version of the entire QuickLisp repository with every package simultaneously updated.

---

Now, back to this project, lisp-packages-lite...

</details>

</details>

# Lisp Packages Lite

Nix-only implementation of a lisp derivation, and registry of popular Common Lisp packages.

This is a grounds-up implementation of a Lisp-in-Nix module, without using QuickLisp. I started with a `stdenv.mkDerivation` and worked my up from there.

This contains:

1. A lisp derivation builder for your own project
2. Derivations for the commonly used Lisp packages

Together, they offer a "batteries included" build environment for your Lisp project in Nix.

## Features

- Tight integration with ASDFv3:
  - Testing
  - Native binary output
  - `.fasl` output
- No QuickLisp
- Explicitly managed dependencies
- Doesn’t touch the Lisp source code at all. No .asd file mangling.
- Multi-system projects (e.g. `cl-async`, `cl-async-ssl`, `cl-async-repl`)
- ... each with different dependencies
- Flakes

The trade-off is in favour of robustness, at the cost of more human work in managing the Nix derivation definitions.

## Usage

### Code: `lispScript`: Single-file Scripts (Easy!)

> [!NOTE]
> See the beginner’s guide for details on where exactly this goes

This is the easiest way to get started:

```nix
with pkgs.lispPackagesLite; lispScript rec {
  name = "json-format";
  src = ./main.lisp;
  dependencies = [ yason ];
};
```

`main.lisp`:

```common-lisp
#!/usr/bin/env sbcl --script

(require "asdf")

(asdf:load-system "yason")

(yason:with-output (t :indent t)
  (yason:encode (yason:parse *standard-input*)))
```

You now have a JSON formatter written in Common Lisp.

Real project using this: [mac-app-util](https://github.com/hraban/mac-app-util).

### Code: `lispDerivation`: Single System, Multiple Files

> [!TIP]
> See the beginner’s guide for details on where exactly this goes

When your project grows too large for a single `main.lisp` file, you can move on to a full-fledged Lisp system defined in ASDF with its own .asd file.

```nix
lispDerivation {
  lispSystem = "my-system";
  lispDependencies = [ alexandria arrow-macros ];
  src = pkgs.lib.cleanSource ./.;
}
```

If your package defines multiple systems that you want to export, you can define them all:

```nix
lispDerivation {
  lispSystems = [ "foo-a" "foo-b" ];
  lispDependencies = [ alexandria arrow-macros ];
  src = pkgs.lib.cleanSource ./.;
}
```

Example for when that makes sense: the `prove` package (a testing framework) used to be called `cl-test-more`. Prove now has two .asd files: `prove.asd` and `cl-test-more.asd`, a compatibility layer. ASDF will only load that file if you tell it explicitly to build `cl-test-more`. Otherwise, it won’t even know to look for it.

Example for when you *don’t* need this: if your main system includes various "private" systems from the same repo explicitly, e.g. via `:depends-on`, you don’t need to tell ASDF about it. It will automatically start looking for them in the current directory. Again, this feature is only useful for “public” systems which are not referenced by the main system. You don’t need it for your `foo-utils.asd` or `foo-test.asd`: just reference them in your `foo.asd` as usual and they will be found.

Real project using this: [git-hly](https://github.com/hraban/git-hly).

### Code: `lispMultiDerivation`: Multiple Systems in One

> [!NOTE]
> This is only supported in the big package scope as of now. It’s an advanced API which doesn’t work and has very limited benefits. Concrete advice: do not use this, unless you are stubborn and don’t need my advice.

Does your Lisp project expose multiple separate, different systems, each with different functionality and (in particular) different dependencies?

You have two options:

- "just include all of them" in a single derivation (easiest solution of course), or
- specify separate systems entirely:

```nix
lispMultiDerivation {
  systems = {
    foo = {};
    foo-b = {
      lispDependencies = [ alexandria ];
    };
    foo-c = {
      lispSystem = "foo/c";
      lispDependencies = [ foo-b fiveam ];
    };
  };
  src = pkgs.lib.cleanSource ./.;
}
```

Note:
- This evaluates to an attrset with one entry for each system defined in the `systems` set.
- The system name is automatically derived from the attribute key name in the `systems` set.
- You can override it using a `lispSystem` key, as per.
- You can omit `lispDependencies` entirely if you have none.
- You can include other systems defined in the same block, as long as there is no circular dependency chain.
- This is only useful if your separate systems have different lispDependencies. If they don’t, just create a regular `lispDerivation` with `lispSystems = [ "foo-a" "foo-b" ]`.
- You don’t need this for your “internal” packages (see similar note in the previous chapter).
- This is only worth it if the different systems have different dependencies. I use this heavily in [the pre-defined list of packages](lisp-packages-lite.nix), because those are libraries and they’re intended for inclusion by other projects. For them, being light-weight matters. But for a personal project, I recommend keeping it all in a single `lispDerivation` and merging all dependencies into a single `lispDependencies`. Far easier.

If this is a dependency in your own project, you’ll want to use it as follows:

foo.nix:
```nix
{ pkgs
, lispPackagesLite
}:

with lispPackagesLite;

lispMultiDerivation {
  systems = {
    foo = {};
    foo-b = {
      lispDependencies = [ alexandria ];
    };
    foo-c = {
      lispSystem = "foo/c";
      lispDependencies = [ foo-b fiveam ];
    };
  };
  src = pkgs.lib.cleanSource ./.;
}
```

bar.nix:

```nix
{
  pkgs ? import <nixpkgs> {},
}:

with rec {
  cl-nix-lite = pkgs.fetchFromGitHub { ... };
  lispPackagesLite = import cl-nix-lite { inherit pkgs; };
  foo = import ./foo.nix { inherit pkgs lispPackagesLite; };
};

with lispPackagesLite;

lispDerivation {
  lispSystem = "bar";
  src = pkgs.lib.cleanSource ./.;
  lispDependencies = [ foo.foo-b ];
}
```

For real-world examples, peruse [`lisp-packages-lite.nix`](lisp-packages-lite.nix).

### Missing Dependency

If you need a third party library which does not exist in cl-nix-lite, there are two solutions:

1. Include it in your own project as a separate `lispDerivation`, which you then add in your `lispDependencies`
2. Add it to `cl-nix-lite` and send a PR to get it upstreamed.[^2]

Fundamentally there is little difference between an “external” dependency, or your “main” project or code. To `cl-nix-lite` it’s all the same. The only difference is the `src` attribute: does it point outside, or to a local path? Due to how Nix works, at the end of the day, `cl-nix-lite` just sees a local directory with the source and it won’t know if it came from your system or an external host.

There are two examples to demonstrate this:

- [external dependency using channels](./examples/channels/external-dependency)
- [external dependency using flakes](./examples/flakes/external-dependency)

### Boiler Plate

Every project needs some setup:

- Flakes: [flake example](examples/flakes/make-binary)
- Channels: look in the [Total Beginner’s Guide](#total-beginners-guide).

### Binary Cache

Pre-compiled versions of all standard lisp packages are published to Cachix, so you don’t have to rebuild tools like Alexandria.

The cache is located at [cl-nix-lite.cachix.org](https://cl-nix-lite.cachix.org), where you can also find instructions on how to set it up on your local machine.

### Setting custom Lisp

By default this package uses SBCL, but you can use any Lisp you want. Pass a supported Lisp derivation as the `lisp` argument to override.

Example:

```nix

...

let
  lispPackagesLite = pkgs.lispPackagesLiteFor pkgs.clisp;
in

...
```

The supported lisps are:

- ABCL
- CLISP
- ECL
- SBCL (default)

You can use any other lisp by passing a function which gets a filename, and returns a shell invocation that executes that file and then quits.

Example for CLISP:

```nix
...

let
  lisp = f: "${pkgs.clisp}/bin/clisp ${f}";
  lispPackagesLite = pkgs.lispPackagesLiteFor lisp;
in

...
```

Different lisps have different levels of support.  Most of this is best effort.

### Modern ASDF

Are you unhappy with your bundled ASDF? Just include `asdf` as any other lisp dependency to get the latest one. It will automatically be picked up.

Note: Nixpkgs also provide a package called ‘asdf’ which is unrelated to lisp’s ASDF, but the names might clash if you have a `with pkgs;` somewhere in your code. Be careful with scoping.

### Emacs & SLIME (or: Working in the REPL)

See the [Emacs & SLIME example](examples/emacs-slime) for a trick to use this during interactive development.

It includes a cl-nix-lite alternative to `ql:quickload` for working in the REPL.

## Output: binary, .fasl files, or a lisp binary?

Is your program itself intended to be used as a dependency? Then you don’t need to do anything special: pre-compiled .fasls will be left next to each .lisp file, and you can include your derivation itself as a `lispDependencies` entry for another lisp derivation. This is appropriate for libraries, e.g. alexandria.

Do you want to output a single executable, instead? This is natively supported by ASDF, so you can leverage that. See:

- The modern example, using a [`flake`](examples/flakes/make-binary)
- The classic [`make-binary`](examples/channels/hello-binary) using `nix-build`
- [ASDF best practices][ASDF best practices] to configure ASDF.

A third way to deliver your final output is as a lisp interpreter itself, which has been configured to find a predetermined set of dependencies.

## Testing

Make sure your ASDF defines tests as per the standard ASDF conventions, see [ASDF best practices][ASDF best practices].

To enable a derivation’s checks, get its `enableCheck` property:

```
$ nix-build -A alexandria.enableCheck
```

This isn’t quite as elegant as `overrideAttrs (_: { doCheck = true; } )`, mostly because my Nix-fu isn’t at that level yet. WIP.

To test all packages, see [examples/channels/test-all](examples/channels/test-all).

## Technical Detail: Recursive Dependency Deduplicator

This lisp derivation builder implements a transitive, “eval-time” full dependency tree resolver and deduplicator in Nix. It solves a fundamental impedance mismatch between Common Lisp and Nix.

A Lisp project, e.g. `cl-async`, can provide multiple actual Lisp systems. Lisp likes to go back and forth between different such project directories as their respective systems include each other, and build what’s needed in different directories as it finds it. In Nix, this is impossible: you build a derivation alone, in one pass, and once it’s done it’s done, no more changing things.

The source code has all the gory details, and hopefully plenty of comments to explain what is going on, and why. Long story short: you can now depend on a system from a separate derivation, which itself depends on another system defined back in your own repository, and you won’t get Nix build errors.

## Glossary

This package (lisp-modules-lite) makes a distinction between Nix *derivations* and Lisp *systems*:

- **derivation**: A Nix concept. It is a single atomic "block" of "code": it can be just the source code, or a pre-built package ready to use.
- **system**: A Common Lisp (actually an ASDF) concept. It is CL’s closest relative to e.g. a Python "package". Confusingly: Nix also has a concept of system, e.g. `x86_64-darwin`. It’s an OS+Architecture description. Because of that confusion, I try to call a Lisp system `lispSystem` in the code, instead of `system`.
- **package**: Very confusing word which I avoid. It can mean “Lisp package” which is sort-of-but-not-really close to “namespaces” in other languages, or it can mean a Nix derivation. Don’t use this word.

See the [`examples`](examples) directory for demonstrations on how to use this builder.

### 1 Nix derivation, many Lisp systems

A crucial, defining feature of this implementation is that there is only ever *one single Nix derivation per Lisp source code project*. This means *there is **no** 1 ⭤ 1 relationship between Lisp systems and Nix derivations*: if a single piece of code defines multiple systems (as many do; `trivia`, `cl-async`, `babel`, ...) they all still result in a single Nix derivation that exports all of them.

## TODO

This is just my unofficial issue tracker.

- An example showing fasl-only building, no binary
- Don’t use `CL_SOURCE_REGISTRY` but use source map files?
- Don’t clobber existing `CL_SOURCE_REGISTRY`
- Check if `lispDerivation` is actually the best name for this function

## Comparison to `lisp-modules` in nixpkgs

The crucial difference with both: No QuickLisp. This is an ideological difference rather than a material one, to an end user.

For a more detailed comparison than that: this project started somewhere late 2022, and both the official `nixpkgs.lispPackages` and this `cl-nix-lite` have diverged considerably, since. I haven’t kept up to date with the main lispPackages development, so I’m not fully equipped to give a proper comparison anymore.

## Motivation

Common Lisp (ASDFv3) and the common Nix derivation idiom are fundamentally at odds: Nix packages are commonly one-repository-one-package (or to be precise "one derivation one package"). ASDFv3 on the other hand has no problems exporting multiple packages ("systems") from a single repository. If you map that directly to a single derivation, you either have to duplicate dependencies across multiple derivations, or build too much code when you don't need it.

Let's say you have a project that defines multiple systems. What do you build?

- Every possible derivation? Problem: you might not /want/ to build certain subsystems at all, particularly if both:
  1. the final project doesn’t need them, AND
  2. they can’t be built on your particular system
- Only one possible derivation? Problems:
  1. (small problem) "Which derivations does this package actually export vs which are just internal?" See e.g. `cl-async`, with `cl-async-ssl` (external) and `cl-async-util` (internal)
  2. (big problem) When one single repository defines multiple systems in one .asd file (again see `cl-async`), you could end up loading e.g. `cl-async-util` from the derivation that only pre-compiled `cl-async-base`, and ASDF will say, "Ok this directory DOES define cl-async-util, it just hasn’t pre-compiled it yet, so let me just do that right now!", try to write in the /nix/store, and fail. There is no sane way out of this post-facto. I call this "the cl-async issue".

The other lisp module implementations are smart about which package defines which systems. Based on QuickLisp, they export only those systems which are actually external. Unfortunately this isn't fool proof (see "https://github.com/NixOS/nixpkgs/pull/196818").

This implementation, on the other hand, does nothing smart at all. It treats all derivations and their source as a black box. You explicitly list which systems it exports, and that's it. It relies on ASDF to find those systems in those derivations.

The downside is a convoluted Nix implementation to figure out the actual dependency tree, particularly when multiple systems live in the same source derivation. To solve The Cl-async Issue, you need to ensure there is only ever exactly one copy of cl-async in the dependencies of the final project. This is a struggle in Nix, although it is possible. Notably this is done purely through the explicit dependencies as specified in the .nix hierarchy: no QuickLisp database nor .asd file introspection is done whatsoever.

## Why not QuickLisp?

QuickLisp and Nix solve the same problem: dependency management. The main benefit of QuickLisp for an end user is “just list your dependencies, and you're good to go”; Nix offers the same.

QuickLisp faces limitations that Nix doesn't need to worry about. Notably, it must be bootstrappable from pure Common Lisp without any dependencies. It has a low bus factor (basically just the one benevolent maintainer: Zach Beane). A discussion on this topic was held in 2016 on [Hacker News](https://news.ycombinator.com/item?id=13097333), and the comments ring just as true in 2023. Notably, someone laments the lack of alternative. I believe Nix can fill that gap.

The other lisp modules leverage QuickLisp which helps bootstrap the list of packages and “known good versions”, and updates. In this package, there are no special cases: every package must be included, managed and updated manually.

But perhaps the most important reason to omit QL is “because there are already two other modules that rely on QL and I wanted to try it without.”

## Links

- [ASDF best practices][ASDF best practices]
- [ASDF 3, or Why Lisp is Now an Acceptable Scripting Language (extended version)](http://fare.tunes.org/files/asdf3/asdf3-2014.html): Extremely detailed design document by the author of ASDFv3 with tons of lisp wisdom, and general programming wisdom. Recommended reading.
- [lisp-modules](../lisp-modules): The original Common Lisp module in nixpkgs. Relies on QuickLisp.
- [lisp-modules-new](../lisp-modules-new): A fresh reimplementation of Common-Lisp-in-Nix. Also relies on QuickLisp.
- [what is `makeScope`](https://old.reddit.com/r/NixOS/comments/z47sky/introducing_lisppackageslite_common_lisp_in_pure/ixr0snv/): Reddit user jonringer117 explains `makeScope`.

[ASDF best practices]: https://github.com/fare/asdf/blob/master/doc/best_practices.md

## License

Copyright © 2022–2024  Hraban Luyat

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

[^1]: Ok *even more specifically*: it’s not a package repository as it doesn’t actually store any actual packages! It just stores a deterministic configuration for how to build those packages. So it’s a... “package recipe repository”? The point is, with Nix, the derivation (= recipe) might as well be the final package itself. Like for a program, the source code might as well be the binary: whether that’s true depends on your perspective and your star sign.
[^2]: Upstreaming means merging into the original package repository, in this case `cl-nix-lite`.

