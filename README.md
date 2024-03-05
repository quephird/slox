# Purpose

I've had the book, "Crafting Interpreters", for a while and went through the first section of it a couple of years ago, following the Java code to build an implementation of the Lox language... but unfortunately it didn't really stick with me. That's not the author's fault but mine; just copying and pasting code wasn't sufficiently effective, as I don't think doing so made me think enough about what I was writing. Moreover, lately I've been looking for a new project to whet my appetite to learn something new, and so I decided to implement Lox in Swift this time. This made me think a lot more about design decisions, and I tried doing things idiomatically in Swift rather than simply transliterate Java code into it. 

# Quick start

Checkout the project using git. Then open it up using Xcode and run the project. That should start up a REPL within Xcode itself in the bottom right of the IDE. You should be able to enter in expressions and see their effects/results in the REPL.

<img src="./images/repl.png" />

# Features

So far, the following have been implemented in `slox`:

- Evaluation of expressions, including support for numeric, logical, and equality operators
- Native `print` statement
- `if`, `while`, and `for` statements
- Variable declaration and assignment
- Function declaration and invocation
- Lambda expressions

There are four phases involved in execution of code in `slox`: 

- scanning for tokens
- parsing of tokens into statements and expressions
- resolving of variables from parsed code
- interpreting of resolved statements 

# Relevant links

- The online version of "Crafting Interpreters"  
  <a href="https://craftinginterpreters.com/contents.html">https://craftinginterpreters.com/contents.html</a>