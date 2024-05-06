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
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        let input = "42"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        let input = "(42)"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .int(42)
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

        let locToken = Token(type: .minus, lexeme: "-", line: 1)
        let expectedError = RuntimeError.unaryOperandMustBeNumber(locToken)
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretBinaryExpressionInvolvingIntegers() throws {
        let input = "21 * 2"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBinaryExpressionInvolvingDoubles() throws {
        let input = "21.0 * 2.0"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .double(42.0)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBinaryExpressionInvolvingAnIntAndADouble() throws {
        let input = "21.0 * 2"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .double(42.0)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBinaryExpressionInvolvingModulusOperator() throws {
        let input = "8 % 3"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)!
        let expected: LoxValue = .int(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStringlyBinaryExpression() throws {
        let input = "\"forty\" + \"-two\""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
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

        let locToken = Token(type: .star, lexeme: "*", line: 1)
        let expectedError = RuntimeError.binaryOperandsMustBeNumbers(locToken)
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretComplexExpression() throws {
        let input = "(-2) * (3 + 4)"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(-14)
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
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCompoundStatementInvolvingAVariable() throws {
        let input = "var theAnswer; theAnswer = 42; theAnswer"
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretUsageOfCompoundAssignmentOperator() throws {
        let input = """
var foo = 2;
foo += 40;
foo
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(3)
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
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(3)
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
        let expected: LoxValue = .int(120)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLambdaExpression() throws {
        let input = "fun (a, b) { return a + b; }(2, 3)"

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(5)
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
        let expected: LoxValue = .int(7)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariablesReferencedInsideFunctionDeclarationDoNotLeakOut() throws {
        let input = """
fun add(a, b) { return a + b; }
add(2, 3);
a
"""

        let interpreter = Interpreter()
        let locToken = Token(type: .identifier, lexeme: "a", line: 3)
        let expectedError = RuntimeError.undefinedVariable(locToken)
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretVariadicFunction() throws {
        let input = """
fun avg(*nums) {
    return nums.reduce(0, fun(acc, num) { return acc+num; })/nums.count;
}
avg(1, 2, 3, 4, 5)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSplattingIntoAnArgumentList() throws {
        let input =  """
var foo = [1, 2, 3];
fun sum(a, b, c) {
    return a+b+c;
}
sum(*foo)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(6)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSplattingWorksProperlyWithArityChecker() throws {
        let input =  """
fun sum(a, b, c) {
    return a+b+c;
}
var foo = [1, 2, 3];
sum(*foo, 4, 5)
"""

        let interpreter = Interpreter()
        let expectedError = RuntimeError.wrongArity(3, 5)
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
        let expected: LoxValue = try interpreter.makeString(string: "Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAssignmentOfNewValueToIinstanceProperty() throws {
        let input = """
class Universe {}
var universe = Universe();
universe.answer = 21;
universe.answer *= 2;
universe.answer
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = try interpreter.makeString(string: "Hello, Becca")
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
        let expected: LoxValue = try interpreter.makeString(string: "My name is Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMethodInSubclassWithThisReferenceResolves() throws {
        let input = """
class A {
    init(foo) {
        this.foo = foo;
    }
}

class B < A {
    init(foo) {
        super.init(foo);
    }

    getFoo() {
        return this.foo;
    }
}

var b = B(42);
b.getFoo()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInstancePropertyHasNotYetBeenSet() throws {
        let input = """
class Person {}
var person = Person();
person.name
"""

        let interpreter = Interpreter()
        let nameToken = Token(type: .identifier, lexeme: "name", line: 3)
        let expectedError = RuntimeError.undefinedProperty(nameToken)
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
        let expected: LoxValue = .int(55)
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
        let expected: LoxValue = try interpreter.makeString(string: "Becca")
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
        let expected: LoxValue = .int(5)
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
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingComputedPropertyOfClass() throws {
        let input = """
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
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .double(50.26544)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfListWithDouble() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2.0]
"""

        let interpreter = Interpreter()
        let locToken = Token(type: .double, lexeme: "2.0", line: 2)
        let expectedError = RuntimeError.indexMustBeAnInteger(locToken)
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretMutationOfList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2] = 6;
foo[2]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(6)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMutationOfListViaCompoundAssignmentOperator() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo[2] += 39;
foo[2]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMutationOfListAsClassProperty() throws {
        let input = """
class Foo {}
var foo = Foo();
foo.bar = [1, 2, 3];
foo.bar[1] += 40;
foo.bar[1]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
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
        let expected: LoxValue = .int(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvokingFunctionReturnedAsElementOfList() throws {
        let input = """
var bar = [fun() { return "not called!"; }, fun () { return "forty-two"; }];
bar[1]()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementInMultidimensionalList() throws {
        let input = """
var baz = [[1, 2], [3, 4]];
baz[1][1]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(4)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCreateAnEmptyList() throws {
        let input = """
var quux = [];
quux.count
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(0)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAddingTwoLists() throws {
        let input = """
var xyzzy = [1, 2, 3] + [4, 5, 6];
xyzzy
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [
            .int(1),
            .int(2),
            .int(3),
            .int(4),
            .int(5),
            .int(6),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCreatingListFromConstructor() throws {
        let input = """
var foo = List();
foo
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [])
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
        let expected: LoxValue = .int(2)
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
        let expected: LoxValue = .int(4)
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
        let expected: LoxValue = .int(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMappingOverAList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo.map(fun(n) { return n*n; })
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [
            .int(1),
            .int(4),
            .int(9),
            .int(16),
            .int(25),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretFilteringAList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo.filter(fun(n) { return n<=3; })
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [
            .int(1),
            .int(2),
            .int(3),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretReducingOverAList() throws {
        let input = """
var foo = [1, 2, 3, 4, 5];
foo.reduce(0, fun(acc, n) { return acc+n; })
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(15)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSplattingAListIntoAnotherList() throws {
        let input = """
var foo = [1, 2, 3];
[*foo, 4, 5, 6]
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [
            .int(1),
            .int(2),
            .int(3),
            .int(4),
            .int(5),
            .int(6),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCloningAListCreatesSeparateCopy() throws {
        let input = """
var foo = [1, 2];
var bar = foo.clone();
foo.append(3);
bar
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeList(elements: [
            .int(1),
            .int(2),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretForLoopWithBreakStatement() throws {
        let input = """
var sum = 0;
for (var i = 1; i < 10; i = i + 1) {
    sum = sum + i;
    if (i == 3) {
        break;
    }
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(6)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretConsecutiveForLoopsWithSameInitializerClauses() throws {
        // This tests whether `i` is scoped properly locally within
        // both `for` loops and no errors occur. Previously, there was
        // a bug; see https://github.com/quephird/slox/issues/69
        let input = """
var sum = 0;
{
    for (var i = 1; i <= 3; i += 1) {
        sum += i;
    }

    for (var i = 1; i <= 3; i += 1) {
        sum += i;
    }
}

sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(12)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretWhileLoopWithBreakStatement() throws {
        let input = """
var sum = 0;
var i = 1;
while (i < 10) {
    sum = sum + i;
    if (i == 3) {
        break;
    }
    i = i + 1;
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(6)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNestedLoopWithBreakStatementInsideInnerLoop() throws {
        let input = """
var sum = 0;
for (var i = 1; i <= 5; i = i + 1) {
    for (var j = 1; j <= 5; j = j + 1) {
        sum = sum + i*j;
        if (j == 2) {
            break;
        }
    }
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(45)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretWhileLoopWithContinue() throws {
        let input = """
var i = 0;
var sum = 0;
while (i < 5) {
    i = i + 1;
    if (i == 3) {
        continue;
    }
    print i;
    sum = sum + i;
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(12)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretForLoopWithContinue() throws {
        let input = """
var sum = 0;
for (var i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
        continue;
    }
    sum = sum + i;
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(12)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNestedLoopsWithBreakAndContinue() throws {
        let input = """
var sum = 0;
for (var i = 1; i <= 3; i = i + 1) {
    if (i == 2) {
        continue;
    }

    for (var j = 1; j <= 3; j = j + 1) {
        if (j == 2) {
            break;
        }

        sum = sum + i*j;
    }
}
sum
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(4)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGettingKeysFromDictionary() throws {
        let input = """
var foo = ["a": 1, "b": 2, "c": 3];
foo.keys
"""

        let interpreter = Interpreter()
        guard case .instance(let list as LoxList) = try interpreter.interpretRepl(source: input) else {
            XCTFail()
            return
        }
        let actualSet = Set(list.elements)
        let expectedSet = [
            try interpreter.makeString(string: "a"),
            try interpreter.makeString(string: "b"),
            try interpreter.makeString(string: "c"),
        ] as Set<LoxValue>
        XCTAssertEqual(actualSet, expectedSet)
    }

    func testInterpretGettingValuesFromDictionary() throws {
        let input = """
var foo = ["a": 1, "b": 2, "c": 3];
foo.values
"""

        let interpreter = Interpreter()
        guard case .instance(let list as LoxList) = try interpreter.interpretRepl(source: input) else {
            XCTFail()
            return
        }
        let actualSet = Set(list.elements)
        let expectedSet = [
            .int(1),
            .int(2),
            .int(3),
        ] as Set<LoxValue>
        XCTAssertEqual(actualSet, expectedSet)
    }

    func testInterpretMergingTwoDictionaries() throws {
        let input = """
var foo = ["a": 1, "b": 1];
var bar = ["b": 2, "c": 3];
foo.merge(bar);
foo
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeDictionary(kvPairs: [
            try interpreter.makeString(string: "a"): .int(1),
            try interpreter.makeString(string: "b"): .int(2),
            try interpreter.makeString(string: "c"): .int(3),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCloningADictionaryCreatesSeparateCopy() throws {
        let input = """
var foo = ["a": 1, "b": 2];
var bar = foo.clone();
foo["c"] = 3;
bar
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected = try interpreter.makeDictionary(kvPairs: [
            try interpreter.makeString(string: "a"): .int(1),
            try interpreter.makeString(string: "b"): .int(2),
        ])
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEnumWithMethod() throws {
        let input = """
enum Color {
    case red, green, blue;

    isRed() {
        if (this == Color.red) {
            return true;
        }

        return false;
    }
}

Color.blue.isRed()
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .boolean(false)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEnumWithClassLevelMethod() throws {
        let input = """
enum Color {
    case red, green, blue;

    class lookup(name) {
        if (name == "red") {
            return Color.red;
        } else if (name == "green") {
            return Color.green;
        } else if (name == "blue") {
            return Color.blue;
        }

        return nil;
    }
}

Color.lookup("green").name
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        // NOTA BENE: We need to compare names here because we do not
        // currently have a means of getting a handle to a specific
        // Lox enum case from within Swift.
        let expected: LoxValue = try interpreter.makeString(string: "green")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEnumWithNoCases() throws {
        let input = """
enum Life {
    class theAnswer() {
        return 42;
    }
}

Life.theAnswer();
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .int(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretComparingCasesOfDifferentEnumsButSameNames() throws {
        let input = """
enum PizzaSize {
    case small, medium, large;
}

enum ClothingSize {
  case small, medium, large;
}

PizzaSize.medium == ClothingSize.medium;
"""
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = .boolean(false)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementThatMatchesFirstCase() throws {
        let input = """
fun spell(number) {
    switch (number) {
    case 1:
        return "one";
    case 2:
        return "two";
    default:
        return "unhandled";
    }
}

spell(1)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "one")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementThatMatchesAnotherCase() throws {
        let input = """
fun spell(number) {
    switch (number) {
    case 1:
        return "one";
    case 2:
        return "two";
    default:
        return "unhandled";
    }
}

spell(2)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementThatFallsThroughToDefaultCase() throws {
        let input = """
fun spell(number) {
    switch (number) {
    case 1:
        return "one";
    case 2:
        return "two";
    default:
        return "unhandled";
    }
}

spell(3)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "unhandled")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementWithACaseThatHasMultipleStatements() throws {
        let input = """
var answer = "";
switch (42) {
case 41:
    answer += "not ";
    answer += "the ";
    answer += "answer";
case 42:
    answer += "forty-";
    answer += "two";
default:
    answer += "unhandled";
}

answer
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementWithACaseThatDeclaresAVariable() throws {
        let input = """
switch (42) {
case 42:
    var answer = "forty-two";
}

answer
"""

        let interpreter = Interpreter()
        let locToken = Token(type: .identifier, lexeme: "answer", line: 6)
        let expectedError = RuntimeError.undefinedVariable(locToken)
        XCTAssertThrowsError(try interpreter.interpretRepl(source: input)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretSwitchStatementWithACaseThatHasABreakStatement() throws {
        let input = """
var answer = "forty-two";
switch (42) {
case 42:
    if (true) {
        break;
    }
    // We should never get here!!!
    answer = "NEVER!";
}

answer
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementWithACaseThatHasAListOfTestValues() throws {
        let input = """
fun foo(number) {
    switch (number) {
    case 1:
        return "one";
    case 2, 3, 4:
        return "two, three, or four";
    default:
        return "unhandled";
    }
}

foo(3)
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "two, three, or four")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementWithJustOneCase() throws {
        let input = """
var answer = "";
switch (42) {
case 42:
    answer = "forty-two";
}

answer
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretSwitchStatementWithJustDefault() throws {
        let input = """
var answer = "";
switch (42) {
default:
    answer = "forty-two";
}

answer
"""

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(source: input)
        let expected: LoxValue = try interpreter.makeString(string: "forty-two")
        XCTAssertEqual(actual, expected)
    }
}
