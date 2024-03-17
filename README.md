# Purpose

I've had the book, "Crafting Interpreters", for a while and went through the first section of it a couple of years ago, following the Java code to build an implementation of the Lox language... but unfortunately it didn't really stick with me. That's not the author's fault but mine; just copying and pasting code wasn't sufficiently effective, as I don't think doing so made me think enough about what I was writing. Moreover, lately I've been looking for a new project to whet my appetite to learn something new, and so I decided to implement Lox in Swift this time. This made me think a lot more about design decisions, and I tried doing things idiomatically in Swift rather than simply transliterate Java code into it. 

# Quick start

Checkout the project using git. Then open it up using Xcode and run the project. That should start up a REPL within Xcode itself in the bottom right of the IDE. You should be able to enter in expressions and see their effects/results in the REPL.

<img src="./images/repl.png" />

# Features

So far, the following have been implemented in `slox`:

- Native numeric, boolean, and string types, as well as `nil`
- Evaluation of expressions, including support for numeric, logical, and equality operators
- Native `print` statement
- `if`, `while`, and `for` statements
- Variable declaration and assignment
- Function declaration and invocation
- Lambda expressions
- Class declaration and instantiation
- Instance properties and methods
- Referencing the scoped instance via `this`
- Class-level properties and methods
- Single inheritance
- Invoking superclass methods via `super`
- List literals using square brackets
- Native functions for lists, `append()` and `deleteAt()`
- `break` and `continue` for flow control within loops

# Design

Most of the design of `slox` is very similar to the one in the book. There are four phases involved in the execution of code in `slox`:

- scanning for tokens
- parsing of tokens into statements and expressions
- resolving of variables from parsed code
- interpreting of resolved statements 

Both the REPL and file runner instantiate the scanner, parser, resolver, and interpreter in succession, each feeding their results to the next, and eventually printing the output of the interpreter.

Nonetheless, there are a few differences between this implementation and that in the book.

### Enums instead of class hierarchies

Instead of using a class hierarchy to represent statements and expressions, I decided to use enums instead. I found it _significantly_ easier to implement and understand the resolver and interpreter, rather than having to use the visitor pattern. (I have to admit that I am not a very good object-oriented programmer.) Plus, I didn't have to write code to generate all the classes; the Swift enum cases turned out to be much pithier than their Java counterparts, and so were easy to handwrite.

Also, I was able to take advantage of the Swift compiler to ensure that when processing statements and expressions in a `switch` statements, that they were exhaustive and I didn't need to worry about forgetting to handle a case. I would not have gotten the instant feedback of an exhaustivity check if I had used a class hierarchy. (And as far as I know, there is no way to express checking for all possible subclasses for a given class.)

### Management of scope depth

Another choice that I made was to have the resolver consume a set of `Statement`s and `Expression`s and produce a set of `ResolvedStatement`s and `ResolvedExpression`s, some of which possess scope depths for variables. I didn't like having the resolver interact with the interpreter, namely mutating state there, and instead preferred a more functional like approach. This way, the resolver can hand the interpreter the AST, from which it can read the depth values directly from the relevant expression nodes.

Moreover, the Java implementation of the interpreter used a `Map` using the object identity of expression instance as the key. I would have needed to have my `Expresion` enum conform to `Hashable`, and that just seemed weird to me when only two of the cases ever need to used as keys in such a dictionary.

This _does_ invite the possibility of maintenance burden as new statement and expression types are introduced, but at the moment I feel like that risk is minimal, and have clear separation between the resolver and interpreter.

### Error handling

Error handling is done a little differently too. I thought it was a little weird for `Lox` to both kick off processing and then also receive calls from multiple places in the program, as how was implemented in the book. So, instead any of the methods in `Scanner`, `Parser`, `Resolver`, and `Interpreter` can simply throw an error, which then bubbles out to the outermost calling method in `Lox`, and there it is handled. It just seemed easier to understand the system that way.

I also decided to create specialized error enums, one for each phase of processing pipeline, rather than one generalized error class/struct. This gives me a lot more flexibility in the future. Perhaps I may want to catch specific errors and have `slox` do something different for each case; this would be a lot harder to do with just one class/struct.

### Native functions

Instead of maintaining set of native functions in `Interpreter`'s constructor, they reside inside the `NativeFunction` enum. When the interpreter is constructed, it defines each of the native functions enumerated in `NativeFunction`. That keeps the responsibility of `Interpreter` clean and focused.

# Unit testing

This repository contains a fairly comprehensive suite of unit tests that exercise the scanner, parser, resolver, and interpreter; to run them, hit ⌘-U from within Xcode.

# Relevant links

- The online version of "Crafting Interpreters"  
  <a href="https://craftinginterpreters.com/contents.html">https://craftinginterpreters.com/contents.html</a>