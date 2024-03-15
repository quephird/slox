//
//  InterpreterTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/27/24.
//

import XCTest

final class InterpreterTests: XCTestCase {
    func testInterpretStringLiteralExpression() throws {
        let input = "\"forty-two\""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        let input = "42"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        let input = "(42)"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretUnaryExpression() throws {
        let input = "!true"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .boolean(false)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidUnaryExpression() throws {
        let input = "-\"forty-two\""
        let interpreter = Interpreter()

        let expectedError = RuntimeError.unaryOperandMustBeNumber
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretNumericBinaryExpression() throws {
        let input = "21 * 2"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStringlyBinaryExpression() throws {
        let input = "\"forty\" + \"-two\""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEqualityExpression() throws {
        let input = "true != false"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidBinaryExpression() throws {
        let input = "\"twenty-one\" * 2"
        let interpreter = Interpreter()

        let expectedError = RuntimeError.binaryOperandsMustBeNumbers
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretComplexExpression() throws {
        let input = "(-2) * (3 + 4)"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(-14)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLogicalExpression() throws {
        let input = "true and false or true"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretComparisonExpression() throws {
        let input = "10 < 20"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariableDeclaration() throws {
        let input = "var theAnswer = 42; theAnswer"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCompoundStatementInvolvingAVariable() throws {
        let input = "var theAnswer; theAnswer = 42; theAnswer"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretWhileStatementWithMutationOfVariable() throws {
        let input = """
var i = 0;
while (i < 3) {
    i = i + 1;
}
i
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretIfStatementWithConditionalMutationOfVariable() throws {
        let input = """
var theAnswer;
if (true)
    theAnswer = 42;
else
    theAnswer = 0;
theAnswer
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBlockStatementThatMutatesVariableAtTopLevel() throws {
        let input = """
var theAnswer = 21;
{
    theAnswer = theAnswer * 2;
}
theAnswer
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretShadowingInBlockStatement() throws {
        let input = """
var theAnswer = 42;
{
    var theAnswer = "forty-two";
}
theAnswer
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretFunctionDeclarationAndInvocation() throws {
        let input = """
fun add(a, b) {
    return a + b;
}
add(1, 2)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretRecursiveFunction() throws {
        let input = """
fun fact(n) {
    if (n <= 1)
        return 1;
    return n * fact(n-1);
}
fact(5)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(120)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLambdaExpression() throws {
        let input = "fun (a, b) { return a + b; }(2, 3)"

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(5)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLambdaReturnedAsValue() throws {
        let input = """
fun makeAdder(n) {
    return fun (a) { return n + a; };
}
var addTwo = makeAdder(2);
addTwo(5)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(7)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariablesReferencedInsideFunctionDeclarationDoNotLeakOut() throws {
        let input = """
fun add(a, b) { return a + b; }
add(2, 3);
a
"""

        let interpreter = Interpreter()
        let expectedError = RuntimeError.undefinedVariable("a")
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretClassDeclarationAndInstantiation() throws {
        let input = """
class Person {}
var person = Person();
person.name = "Danielle";
person.name
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMethodInvocation() throws {
        let input = """
class Person {
    sayHello(name) {
        return "Hello, " + name;
    }
}
var me = Person();
me.sayHello("Becca")
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("Hello, Becca")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStatementsInvolvingThis() throws {
        let input = """
class Person {
    greeting() {
        return "My name is " + this.name;
    }
}
var me = Person();
me.name = "Danielle";
me.greeting()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("My name is Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInstancePropertyHasNotYetBeenSet() throws {
        let input = """
class Person {}
var person = Person();
person.name
"""

        let interpreter = Interpreter()
        let expectedError = RuntimeError.undefinedProperty("name")
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretClassWithInitializerWithNonzeroArity() throws {
        let input = """
class Person {
    init(name, age) {
        this.name = name;
        this.age = age;
    }
}
var me = Person("Danielle", 55);
me.age
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(55)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallingInitDirectlyOnAnInstance() throws {
        let input = """
class Person {
    init(name) {
        this.name = name;
    }
}
var me = Person("Danielle");
var becca = me.init("Becca");
becca.name
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("Becca")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretClassWithStaticMethod() throws {
        let input = """
class Math {
    class add(a, b) {
        return a + b;
    }
}
Math.add(2, 3)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(5)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallToMethodOnSuperclass() throws {
        let input = """
class A {
    getTheAnswer() {
        return 42;
    }
}
class B < A {}
var b = B();
b.getTheAnswer()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallingMethodInSuperclassResolvesProperly() throws {
        let input = """
class A {
    method() {
        return 21;
    }
}
class B < A {
    method() {
        return 2*super.method();
    }
}
var b = B();
b.method()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMutationOfList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2] = 6;
foo[2]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(6)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfListReturnedByFunction() throws {
        let input = """
fun foo() {
    return [1, 2, 3];
}
foo()[1]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvokingFunctionReturnedAsElementOfList() throws {
        let input = """
var bar = [fun() { return "not called!"; }, fun () { return "forty-two"; }];
bar[1]()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementInMultidimensionalList() throws {
        let input = """
var baz = [[1, 2], [3, 4]];
baz[1][1]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(4)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretExpressionWithListSubscriptingMethodInvocationAndPropertyGetting() throws {
        let input = """
class Foo { }
var foo = Foo();
foo.bar = fun() { return [1, 2, 3]; };
foo.bar()[1]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAppendingToAList() throws {
        let input = """
var foo = [1, 2, 3];
foo.append(4);
foo.count
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(4)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretDeletingFromAList() throws {
        let input = """
var foo = [1, 2, 3];
foo.deleteAt(1);
foo.count
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .number(2)
        XCTAssertEqual(actual, expected)
    }
}
