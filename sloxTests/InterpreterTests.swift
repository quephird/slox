//
//  InterpreterTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/27/24.
//

import XCTest

final class InterpreterTests: XCTestCase {
    func testInterpretStringLiteralExpression() throws {
        // "forty-two"
        let stmt: ResolvedStatement = .expression(.literal(.string("forty-two")))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        // 42
        let stmt: ResolvedStatement = .expression(.literal(.number(42)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        // (42)
        let stmt: ResolvedStatement = .expression(.grouping(.literal(.number(42))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretUnaryExpression() throws {
        // !true
        let stmt: ResolvedStatement =
            .expression(
                .unary(
                    Token(type: .bang, lexeme: "!", line: 1),
                    .literal(.boolean(true))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .boolean(false)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidUnaryExpression() throws {
        // -"forty-two"
        let stmt: ResolvedStatement =
            .expression(
                .unary(
                    Token(type: .minus, lexeme: "-", line: 1),
                    .literal(.string("forty-two"))))
        let interpreter = Interpreter()

        let expectedError = RuntimeError.unaryOperandMustBeNumber
        XCTAssertThrowsError(try interpreter.interpretRepl(statements: [stmt])!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretNumericBinaryExpression() throws {
        // 21 * 2
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .literal(.number(21)),
                    Token(type: .star, lexeme: "*", line: 1),
                    .literal(.number(2))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStringlyBinaryExpression() throws {
        // "forty" + "-two"
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .literal(.string("forty")),
                    Token(type: .plus, lexeme: "+", line: 1),
                    .literal(.string("-two"))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEqualityExpression() throws {
        // true != false
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .literal(.boolean(true)),
                    Token(type: .bangEqual, lexeme: "!=", line: 1),
                    .literal(.boolean(false))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidBinaryExpression() throws {
        // "twenty-one" * 2
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .literal(.string("twenty-one")),
                    Token(type: .star, lexeme: "*", line: 1),
                    .literal(.number(2))))
        let interpreter = Interpreter()

        let expectedError = RuntimeError.binaryOperandsMustBeNumbers
        XCTAssertThrowsError(try interpreter.interpretRepl(statements: [stmt])!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretComplexExpression() throws {
        // (-2) * (3 + 4)
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .grouping(.unary(
                        Token(type: .minus, lexeme: "-", line: 1),
                        .literal(.number(2)))),
                    Token(type: .star, lexeme: "*", line: 1),
                    .grouping(.binary(
                        .literal(.number(3)),
                        Token(type: .plus, lexeme: "+", line: 1),
                        .literal(.number(4))))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .number(-14)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLogicalExpression() throws {
        // true and false or true
        let stmt: ResolvedStatement =
            .expression(
                .logical(
                    .logical(
                        .literal(.boolean(true)),
                        Token(type: .and, lexeme: "and", line: 1),
                        .literal(.boolean(false))),
                    Token(type: .or, lexeme: "or", line: 1),
                    .literal(.boolean(true))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretComparisonExpression() throws {
        // 10 < 20
        let stmt: ResolvedStatement =
            .expression(
                .binary(
                    .literal(.number(10)),
                    Token(type: .less, lexeme: "<", line: 1),
                    .literal(.number(20))))

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariableDeclaration() throws {
        // var theAnswer = 42; theAnswer
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(42))),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCompoundStatementInvolvingAVariable() throws {
        // var theAnswer; theAnswer = 42; theAnswer
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.nil)),
            .expression(
                .assignment(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(.number(42)),
                    0)),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    0))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretWhileStatementWithMutationOfVariable() throws {
        // var i = 0;
        // while (i < 3) {
        //    i = i + 1;
        // }
        // i
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "i", line: 1),
                .literal(.number(0))),
            .while(
                .binary(
                    .variable(
                        Token(type: .identifier, lexeme: "i", line: 2),
                        0),
                    Token(type: .less, lexeme: "<", line: 2),
                    .literal(.number(3))),
                .block([
                    .expression(
                        .assignment(
                            Token(type: .identifier, lexeme: "i", line: 3),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "i", line: 3),
                                    1),
                                Token(type: .plus, lexeme: "+", line: 3),
                                .literal(.number(1))),
                            1))
                ])),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "i", line: 5),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretIfStatementWithConditionalMutationOfVariable() throws {
        // var theAnswer;
        // if (true)
        //     x = 42;
        // else
        //     x = 0;
        // theAnswer
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                nil),
            .if(
                .literal(.boolean(true)),
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .literal(.number(42)),
                        0)),
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .literal(.number(0)),
                        0))),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 6),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBlockStatementThatMutatesVariableAtTopLevel() throws {
        // var theAnswer = 21
        // {
        //     theAnswer = theAnswer * 2;
        // }
        // theAnswer
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(21))),
            .block([
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .binary(
                            .variable(
                                Token(type: .identifier, lexeme: "theAnswer", line: 3),
                                1),
                            Token(type: .star, lexeme: "*", line: 3),
                            .literal(.number(2))),
                        1)),
            ]),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 5),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretShadowingInBlockStatement() throws {
        // var theAnswer = 42
        // {
        //     var theAnswer = "forty-two";
        // }
        // theAnswer
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(42))),
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(.string("forty-two"))),
            ]),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 5),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretFunctionDeclarationAndInvocation() throws {
        // fun add(a, b) {
        //     return a + b;
        // }
        // add(1, 2)
        let statements: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "a", line: 2),
                                    0),
                                Token(type: .plus, lexeme: "+", line: 2),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 2),
                                    0)))
                    ])),
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "add", line: 4),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 4),
                    [
                        .literal(.number(1)),
                        .literal(.number(2)),
                    ]))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretRecursiveFunction() throws {
        // fun fact(n) {
        //     if (n <= 1)
        //         return 1;
        //     return n * fact(n-1);
        // }
        // fact(5)
        let statements: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "fact", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "n", line: 1),
                    ],
                    [
                        .if(
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "n", line: 2),
                                    0),
                                Token(type: .lessEqual, lexeme: "<=", line: 2),
                                .literal(.number(1))),
                            .return(
                                Token(type: .return, lexeme: "return", line: 3),
                                .literal(.number(1))),
                            nil),
                        .return(
                            Token(type: .return, lexeme: "return", line: 4),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "n", line: 4),
                                    0),
                                Token(type: .star, lexeme: "*", line: 4),
                                .call(
                                    .variable(
                                        Token(type: .identifier, lexeme: "fact", line: 4),
                                        1),
                                    Token(type: .rightParen, lexeme: ")", line: 4),
                                    [
                                        .binary(
                                            .variable(
                                                Token(type: .identifier, lexeme: "n", line: 4),
                                                0),
                                            Token(type: .minus, lexeme: "-", line: 4),
                                            .literal(.number(1)))
                                    ])))
                    ])),
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "fact", line: 5),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 5),
                    [.literal(.number(5)),])),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(120)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLambdaExpression() throws {
        // fun (a, b) { return a + b; }(2, 3)
        let statements: [ResolvedStatement] = [
            .expression(
                .call(
                    .lambda(
                        [
                            Token(type: .identifier, lexeme: "a", line: 1),
                            Token(type: .identifier, lexeme: "b", line: 1),
                        ],
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 1),
                                .binary(
                                    .variable(
                                        Token(type: .identifier, lexeme: "a", line: 1),
                                        0),
                                    Token(type: .plus, lexeme: "+", line: 1),
                                    .variable(
                                        Token(type: .identifier, lexeme: "b", line: 1),
                                        0)))
                        ]),
                    Token(type: .rightParen, lexeme: ")", line: 1),
                    [
                        .literal(.number(2)),
                        .literal(.number(3))
                    ]))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(5)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretLambdaReturnedAsValue() throws {
        // fun makeAdder(n) {
        //     return fun (a) { return n + a; };
        // }
        // var addTwo = makeAdder(2);
        // addTwo(5)
        let statements: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "makeAdder", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "n", line: 1),
                    ],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .lambda(
                                [
                                    Token(type: .identifier, lexeme: "a", line: 2)
                                ],
                                [
                                    .return(
                                        Token(type: .return, lexeme: "return", line: 2),
                                        .binary(
                                            .variable(
                                                Token(type: .identifier, lexeme: "n", line: 2),
                                                1),
                                            Token(type: .plus, lexeme: "+", line: 2),
                                            .variable(
                                                Token(type: .identifier, lexeme: "a", line: 2),
                                                0)))
                                ]))
                    ])),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "addTwo", line: 4),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "makeAdder", line: 4),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 4),
                    [
                        .literal(.number(2))
                    ])),
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "addTwo", line: 5),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 5),
                    [.literal(.number(5))]))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(7)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariablesReferencedInsideFunctionDeclarationDoNotLeakOut() throws {
        // fun add(a, b) { return a + b; }
        // add(2, 3)
        // a
        let statements: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 1),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "a", line: 1),
                                    0),
                                Token(type: .plus, lexeme: "+", line: 1),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 1),
                                    0)))
                    ])),
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "add", line: 2),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 2),
                    [
                        .literal(.number(1)),
                        .literal(.number(2)),
                    ])),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "a", line: 3),
                    0))
        ]

        let interpreter = Interpreter()
        let expectedError = RuntimeError.undefinedVariable("a")
        XCTAssertThrowsError(try interpreter.interpretRepl(statements: statements)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretClassDeclarationAndInstantiation() throws {
        // class Person {}
        // var person = Person();
        // person.name = "Danielle";
        // person.name
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "person", line: 2),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 2),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 2),
                    [])),
            .expression(
                .set(
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 3),
                        0),
                    Token(type: .identifier, lexeme: "name", line: 3),
                    .literal(.string("Danielle")))),
            .expression(
                .get(
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 4),
                        0),
                    Token(type: .identifier, lexeme: "name", line: 4))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .string("Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMethodInvocation() throws {
        // class Person {
        //     sayHello(name) {
        //         return "Hello, " + name;
        //     }
        // }
        // var me = Person();
        // me.sayHello("Becca")
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayHello", line: 2),
                        .lambda(
                            [
                                Token(type: .identifier, lexeme: "name", line: 2)
                            ],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .literal(.string("Hello, ")),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "name", line: 3),
                                            0))),
                            ])),
                ],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "me", line: 6),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 6),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 6),
                    [])),
            .expression(
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "me", line: 7),
                            0),
                        Token(type: .identifier, lexeme: "sayHello", line: 7)),
                    Token(type: .rightParen, lexeme: ")", line: 7),
                    [
                        .literal(.string("Becca"))
                    ])),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .string("Hello, Becca")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStatementsInvolvingThis() throws {
        // class Person {
        //     greeting() {
        //         return "My name is " + this.name;
        //     }
        // }
        // var me = Person();
        // me.name = "Danielle";
        // me.greeting()
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "greeting", line: 2),
                        .lambda(
                            [],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .literal(.string("My name is ")),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .get(
                                            .this(
                                                Token(type: .this, lexeme: "this", line: 3),
                                                1),
                                            Token(type: .identifier, lexeme: "name", line: 3)))),
                            ])),
                ],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "me", line: 6),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 6),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 6),
                    [])),
            .expression(
                .set(
                    .variable(
                        Token(type: .identifier, lexeme: "me", line: 7),
                        0),
                    Token(type: .identifier, lexeme: "name", line: 7),
                    .literal(.string("Danielle")))),
            .expression(
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "me", line: 8),
                            0),
                        Token(type: .identifier, lexeme: "greeting", line: 8)),
                    Token(type: .rightParen, lexeme: ")", line: 8),
                    [])),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .string("My name is Danielle")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInstancePropertyHasNotYetBeenSet() throws {
        // class Person {}
        // var person = Person();
        // person.name
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "person", line: 2),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 2),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 2),
                    [])),
            .expression(
                .get(
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 4),
                        0),
                    Token(type: .identifier, lexeme: "name", line: 4))),
        ]

        let interpreter = Interpreter()
        let expectedError = RuntimeError.undefinedProperty("name")
        XCTAssertThrowsError(try interpreter.interpretRepl(statements: statements)!) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretClassWithInitializerWithNonzeroArity() throws {
        // class Person {
        //     init(name, age) {
        //         this.name = name;
        //         this.age = age;
        //     }
        // }
        // var me = Person("Danielle", 55);
        // me.age
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "init", line: 2),
                        .lambda(
                            [
                                Token(type: .identifier, lexeme: "name", line: 2),
                                Token(type: .identifier, lexeme: "age", line: 2),
                            ],
                            [
                                .expression(
                                    .set(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            1),
                                        Token(type: .identifier, lexeme: "name", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "name", line: 3),
                                            0))),
                                .expression(
                                    .set(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 4),
                                            1),
                                        Token(type: .identifier, lexeme: "age", line: 4),
                                        .variable(
                                            Token(type: .identifier, lexeme: "age", line: 4),
                                            0))),
                            ]))
                ],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "person", line: 7),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 7),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 7),
                    [
                        .literal(.string("Danielle")),
                        .literal(.number(55)),
                    ])),
            .expression(
                .get(
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 8),
                        0),
                    Token(type: .identifier, lexeme: "age", line: 8))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(55)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallingInitDirectlyOnAnInstance() throws {
        // class Person {
        //     init(name) {
        //         this.name = name;
        //     }
        // }
        // var me = Person("Danielle");
        // var becca = me.init("Becca");
        // becca.name
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "init", line: 2),
                        .lambda(
                            [
                                Token(type: .identifier, lexeme: "name", line: 2),
                            ],
                            [
                                .expression(
                                    .set(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            1),
                                        Token(type: .identifier, lexeme: "name", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "name", line: 3),
                                            0))),
                            ]))
                ],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "me", line: 6),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Person", line: 6),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 6),
                    [
                        .literal(.string("Danielle")),
                    ])),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "becca", line: 6),
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "me", line: 6),
                            0),
                        Token(type: .identifier, lexeme: "init", line: 6)),
                    Token(type: .rightParen, lexeme: ")", line: 6),
                    [
                        .literal(.string("Becca"))
                    ])),
            .expression(
                .get(
                    .variable(
                        Token(type: .identifier, lexeme: "becca", line: 8),
                        0),
                    Token(type: .identifier, lexeme: "name", line: 8))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .string("Becca")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretClassWithStaticMethod() throws {
        // class Math {
        //     class add(a, b) {
        //         return a + b;
        //     }
        // }
        // Math.add(2, 3)
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Math", line: 1),
                nil,
                [],
                [
                    .function(
                        Token(type: .identifier, lexeme: "add", line: 2),
                        .lambda(
                            [
                                Token(type: .identifier, lexeme: "a", line: 2),
                                Token(type: .identifier, lexeme: "b", line: 2),
                            ],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .variable(
                                            Token(type: .identifier, lexeme: "a", line: 3),
                                            0),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "b", line: 3),
                                            0)))
                            ]))
                ]),
            .expression(
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "Math", line: 6),
                            0),
                        Token(type: .identifier, lexeme: "add", line: 6)),
                    Token(type: .rightParen, lexeme: ")", line: 6),
                    [
                        .literal(.number(2)),
                        .literal(.number(3)),
                    ])),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(5)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallToMethodOnSuperclass() throws {
        // class A {
        //     getTheAnswer() {
        //         return 42;
        //     }
        // }
        // class B < A {}
        // var b = B();
        // b.getTheAnswer()
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "A", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "getTheAnswer", line: 2),
                        .lambda(
                            [],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .literal(.number(42)))
                            ]))
                ],
                []),
            .class(
                Token(type: .identifier, lexeme: "B", line: 6),
                .variable(
                    Token(type: .identifier, lexeme: "A", line: 6),
                    0),
                [],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "b", line: 7),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "B", line: 7),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 7),
                    [])),
            .expression(
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "b", line: 8),
                            0),
                        Token(type: .identifier, lexeme: "getTheAnswer", line: 8)),
                    Token(type: .rightParen, lexeme: ")", line: 8),
                    []))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCallingMethodInSuperclassResolvesProperly() throws {
        // class A {
        //     method() {
        //         return 21;
        //     }
        // }
        // class B < A {
        //     method() {
        //         return 2*super.someMethod();
        //     }
        // }
        // var b = B();
        // b.method()
        let statements: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "A", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "method", line: 2),
                        .lambda(
                            [],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .literal(.number(21)))
                            ]))
                ],
                []),
            .class(
                Token(type: .identifier, lexeme: "B", line: 6),
                .variable(
                    Token(type: .identifier, lexeme: "A", line: 6),
                    0),
                [
                    .function(
                        Token(type: .identifier, lexeme: "method", line: 7),
                        .lambda(
                            [],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 8),
                                    .binary(
                                        .literal(.number(2)),
                                        Token(type: .star, lexeme: "*", line: 8),
                                        .call(
                                            .super(
                                                Token(type: .super, lexeme: "super", line: 8),
                                                Token(type: .identifier, lexeme: "method", line: 8),
                                                2),
                                            Token(type: .rightParen, lexeme: ")", line: 8),
                                            []))),
                            ]))
                ],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "b", line: 9),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "B", line: 9),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 9),
                    [])),
            .expression(
                .call(
                    .get(
                        .variable(
                            Token(type: .identifier, lexeme: "b", line: 10),
                            0),
                        Token(type: .identifier, lexeme: "method", line: 10)),
                    Token(type: .rightParen, lexeme: ")", line: 10),
                    [])),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfList() throws {
        // var foo = [1, 2, 3, 4, 5];
        // foo[2]
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "foo", line: 1),
                .list([
                    .literal(.number(1)),
                    .literal(.number(2)),
                    .literal(.number(3)),
                    .literal(.number(4)),
                    .literal(.number(5)),
                ])),
            .expression(
                .subscriptGet(
                    .variable(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        0),
                    .literal(.number(2)))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretMutationOfList() throws {
        // var foo = [1, 2, 3, 4, 5];
        // foo[2] = 6
        // foo
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "foo", line: 1),
                .list([
                    .literal(.number(1)),
                    .literal(.number(2)),
                    .literal(.number(3)),
                    .literal(.number(4)),
                    .literal(.number(5)),
                ])),
            .expression(
                .subscriptSet(
                    .variable(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        0),
                    .literal(.number(2)),
                    .literal(.number(6)))),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "foo", line: 3),
                    0)),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .list(
            LoxList(elements: [
                .number(1),
                .number(2),
                .number(6),
                .number(4),
                .number(5),
            ]))
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementOfListReturnedByFunction() throws {
        // fun foo() {
        //     return [1, 2, 3];
        // }
        // foo()[1]
        let statements: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "foo", line: 1),
                .lambda(
                    [],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .list([
                                .literal(.number(1)),
                                .literal(.number(2)),
                                .literal(.number(3)),
                            ]))
                    ])),
            .expression(
                .subscriptGet(
                    .call(
                        .variable(
                            Token(type: .identifier, lexeme: "foo", line: 4),
                            0),
                        Token(type: .rightParen, lexeme: ")", line: 4),
                        []),
                    .literal(.number(1)))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(2)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvokingFunctionReturnedAsElementOfList() throws {
        // var bar = [fun() { return "not called!"; }, fun () { return "forty-two"; }]
        // bar[1]()
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "bar", line: 1),
                .list([
                    .lambda(
                        [],
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 1),
                                .literal(.string("not called!")))
                        ]),
                    .lambda(
                        [],
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 1),
                                .literal(.string("forty-two")))
                        ]),
                ])),
            .expression(
                .call(
                    .subscriptGet(
                        .variable(
                            Token(type: .identifier, lexeme: "bar", line: 2),
                            0),
                        .literal(.number(1))),
                    Token(type: .rightParen, lexeme: ")", line: 2),
                    []))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretAccessingElementInMultidimensionalList() throws {
        // var baz = [[1, 2], [3, 4]];
        // baz[1][1]
        let statements: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "baz", line: 1),
                .list([
                    .list([.literal(.number(1)), .literal(.number(2))]),
                    .list([.literal(.number(3)), .literal(.number(4))]),
                ])),
            .expression(
                .subscriptGet(
                    .subscriptGet(
                        .variable(
                            Token(type: .identifier, lexeme: "baz", line: 2),
                            0),
                        .literal(.number(1))),
                    .literal(.number(1))))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(4)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretExpressionWithListSubscriptingMethodInvocationAndPropertyGetting() throws {
        // class Foo { }
        // var foo = Foo();
        // foo.bar = fun() { return [1, 2, 3]; }
        // foo.bar()[1]
        let statements:[ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Foo", line: 1),
                nil,
                [],
                []),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "foo", line: 2),
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "Foo", line: 2),
                        0),
                    Token(type: .rightParen, lexeme: ")", line: 2),
                    [])),
            .expression(
                .set(
                    .variable(
                        Token(type: .identifier, lexeme: "foo", line: 3),
                        0),
                    Token(type: .identifier, lexeme: "bar", line: 3),
                    .lambda(
                        [],
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 3),
                                .list([
                                    .literal(.number(1)),
                                    .literal(.number(2)),
                                    .literal(.number(3)),
                                ]))
                        ]))),
            .expression(
                .subscriptGet(
                    .call(
                        .get(
                            .variable(
                                Token(type: .identifier, lexeme: "foo", line: 4),
                                0),
                            Token(type: .identifier, lexeme: "bar", line: 4)),
                        Token(type: .rightParen, lexeme: ")", line: 4),
                        []),
                    .literal(.number(1)))),
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(2)
        XCTAssertEqual(actual, expected)
    }
}
