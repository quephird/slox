# Purpose

I've had the book, "Crafting Interpreters", for a while and went through the first section of it a couple of years ago, following the Java code to build an implementation of the Lox language... but unfortunately it didn't really stick with me. That's not the author's fault but mine; just copying and pasting code wasn't sufficiently effective, as I don't think doing so made me think enough about what I was writing. Moreover, lately I've been looking for a new project to whet my appetite to learn something new, and so I decided to implement Lox in Swift this time. This made me think a lot more about design decisions, and I tried doing things idiomatically in Swift rather than simply transliterate Java code into it. 

# Quick start

Checkout the project using git. Then open it up using Xcode and run the project by hitting ⌘-R. That should start up a REPL within Xcode itself, in the bottom right of the IDE. You should be able to enter expressions and see their effects/results in the REPL.

<img src="./images/repl.png" />

# Features

So far, the following have been implemented in `slox`:

### Types

There are four scalar types, int, double, boolean, and string, as well as `nil`

### Expressions

Evaluation of expressions, including support for numeric, logical, and equality operators

### Variables

Variables are declared with the `var` keyword, and can be immediately assigned

```
var answer = 42;
```

### `print`

Lox has a builtin `print` statement which, for the time being, takes a single expression.

```
print "Hello, world!";
```

### Flow control

There are three types of flow control statements in Lox: `if`, `while`, and `for` statements.

```
if (x == 42) {
    print "YES!";
} else {
    print "nope";
}

var i = 0;
while (i < 3) {
    print i;
    i = i + 1;
}

for (var i = 0; i < 3; i = i + 1) {
    print i;
}
```

Additionally, users can use `break` and `continue` in `while` or `for` loops

```
var sum = 0;
for (var i = 1; i < 5; i = i + 1) {
    if (i == 3) {
        continue;
    }
}
print sum;

var i = 0;
while (true) {
    print i;
    if (i > 2) {
        break;
    }
    i = i + 1;
}
```

### Functions

Functions are declared with a preceding `fun` keyword, and invoked using parentheses:

```
fun add(a, b) {
    return a + b;
}

add(1, 2)
``` 

You can also create and invoke nameless functions or lambda expressions:

```
fun (a, b) { return a + b; }(1, 2)
```

### Classes

As with many other programming languages, classes in Lox are declared with a preceding `class` keyword, with the class body contained between two braces, and instantiated with parentheses like functions.

```
class Person {}
var me = Person();
```

Properties can be created dynamically _after_ class instantiation:

```
class Person {}
var me = Person();
me.name = "Danielle";
```

Classes can have methods, which do _not_ require the `fun` keyword, and can refer to instance properties via `this`:

```
class Person {
    greet() {
        print "My name is " + this.name;
    }
}
var me = Person();
me.name = "Danielle";
me.greet();
```

Classes can be declared with an `init` method to set properties upon instantiation.

```
class Person {
    init(name) {
        this.name = name
    }
}
var me = Person("Danielle");
```

Classes can also have static methods, which are denoted as such with the `class` keyword:

```
class Math {
    class add(a, b) {
        return a + b;
    }
}
Math.add(1, 2)
```

You can also define computed properties in classes, which look just like functions but do not have an argument list:

```
class Circle {
    init(radius) {
        this.radius = radius;
    }

    area {
        return 3.14159 * this.radius * this.radius;
    }
}
var c = Circle(4);
c.area
```

This implementation of Lox supports single inheritance, using the `<` operator to denote subclassing. You can also invoke superclass methods via `super`, and override methods on a superclass:

```
class BankAccount {
    init(amount) {
        this.balance = amount;
    }
    
    withdraw(amount) {
        if (this.balance >= amount) {
            this.balance -= amount;
            return;
        }
        
        print "Insufficient funds!";
    }
}

class SavingsAccount < BankAccount {
    init(amount) {
        super.init(amount);
    }

    withdraw(amount) {
        if ((this.balance - amount) > 100) {
            this.balance -= amount;
            return;
        }

        print "Insufficient funds!";
    }
}

var ba = BankAccount(199);
ba.withdraw(100);
print ba.balance;

var sa = SavingsAccount(199);
sa.withdraw(100);
```

### Collections

Currently, there are two collection types supported in Lox: lists and dictionaries. List literals are created using square brackets, and there are native properties and functions for them:

```
var foo = [1, 2, 3];
foo.count;             // Prints 3

foo.append(4);
foo;                   // Prints [1, 2, 3, 4]

foo.deleteAt(2);
foo;                   // Prints [1, 2, 4]
```

Dictionary literals are also created with square brackets, but also use the color character to delimit keys from values. Likewise, dictionaries also have some built-in properties and methods:

```
var bar = ["a": 1, "b": 2];
bar.count              // Prints 2

bar["b"] = 3;
bar;                   // Prints ["a": 1, "b": 3]

bar.keys;              // Prints ["a", "b"]
bar.values;            // Prints ["1", "3"]

bar.merge(["b": 2, "c": 3])
bar;                   // Prints ["a": 1, "b": 2, "c": 3]

bar.removeValue("a")   // Prints 1
```

# Design

Most of the design of `slox` is fairly similar to the one in the book. There are four phases involved in the execution of code in `slox`:

- scanning for tokens
- parsing of tokens into statements and expressions
- resolving of variables from parsed code
- interpreting of resolved statements 

However, unlike how they are implemented in the book, the REPL and file runner instantiate just the interpreter, passing in code to be executed; it is the interpreter that instantiates and runs the scanner, parser, resolver in succession, each feeding their results to the next. The interpreter also reads in a small standard library defined in a string; at this point, only a class declaration for a `List` class and some associated methods are defined in it.

There are a few other differences between this implementation and that in the book which are described below.

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