//
//  InterpreterTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/27/24.
//

import XCTest

final class InterpreterTests: XCTestCase {
    func testInterpretStringLiteralExpression() throws {
        let stmt: Statement = .expression(.literal(.string("forty-two")))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        let stmt: Statement = .expression(.literal(.number(42)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        let stmt: Statement = .expression(.grouping(.literal(.number(42))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretUnaryExpression() throws {
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
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
        let stmt: Statement =
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(42)))

        let interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: [stmt])
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "theAnswer")
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretCompoundStatementInvolvingAVariable() throws {
        // var theAnswer; theAnswer = 42; theAnswer
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.nil)),
            .expression(
                .assignment(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(.number(42)))),
            .expression(
                .variable(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1)))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretWhileStatement() throws {
        // var i = 0;
        // while (i < 3) {
        //    i = i + 1;
        // }
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "i", line: 1),
                .literal(.number(0))),
            .while(
                .binary(
                    .variable(Token(type: .identifier, lexeme: "i", line: 2)),
                    Token(type: .less, lexeme: "<", line: 2),
                    .literal(.number(3))),
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "i", line: 3),
                        .binary(
                            .variable(Token(type: .identifier, lexeme: "i", line: 3)),
                            Token(type: .plus, lexeme: "+", line: 3),
                            .literal(.number(1)))))),
        ]

        let interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: statements)
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "i")
        let expected: LoxValue = .number(3)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretIfStatement() throws {
        // var x;
        // if (true)
        //     x = 42;
        // else
        //     x = 0;
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                nil),
            .if(
                .literal(.boolean(true)),
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .literal(.number(42)))),
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .literal(.number(0))))),
        ]

        let interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: statements)
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "theAnswer")
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretBlockStatement() throws {
        // var theAnswer = 21
        // {
        //     theAnswer = theAnswer * 2;
        // }
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(21))),
            .block([
                .expression(
                    .assignment(
                        Token(type: .identifier, lexeme: "theAnswer", line: 3),
                        .binary(
                            .variable(Token(type: .identifier, lexeme: "theAnswer", line: 3)),
                            Token(type: .star, lexeme: "*", line: 3),
                            .literal(.number(2))))),
            ])
        ]

        let interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: statements)
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "theAnswer")
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretShadowingInBlockStatement() throws {
        // var theAnswer = 42
        // {
        //     var theAnswer = "forty-two";
        // }
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(42))),
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(.string("forty-two"))),
            ])
        ]

        let interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: statements)
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "theAnswer")
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretFunctionDeclarationAndInvocation() throws {
        // fun add(a, b) {
        //     return a + b;
        // }
        // add(1, 2)
        let statements: [Statement] = [
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
                                .variable(Token(type: .identifier, lexeme: "a", line: 2)),
                                Token(type: .plus, lexeme: "+", line: 2),
                                .variable(Token(type: .identifier, lexeme: "b", line: 2))))
                    ])
                ),
            .expression(
                .call(
                    .variable(Token(type: .identifier, lexeme: "add", line: 4)),
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
        let statements: [Statement] = [
            .function(
                Token(type: .identifier, lexeme: "fact", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "n", line: 1),
                    ],
                    [
                        .if(
                            .binary(
                                .variable(Token(type: .identifier, lexeme: "n", line: 2)),
                                Token(type: .lessEqual, lexeme: "<=", line: 2),
                                .literal(.number(1))),
                            .return(
                                Token(type: .return, lexeme: "return", line: 3),
                                .literal(.number(1))),
                            nil),
                        .return(
                            Token(type: .return, lexeme: "return", line: 4),
                            .binary(
                                .variable(Token(type: .identifier, lexeme: "n", line: 4)),
                                Token(type: .star, lexeme: "*", line: 4),
                                .call(
                                    .variable(Token(type: .identifier, lexeme: "fact", line: 4)),
                                    Token(type: .rightParen, lexeme: ")", line: 4),
                                    [
                                        .binary(
                                            .variable(Token(type: .identifier, lexeme: "n", line: 4)),
                                            Token(type: .minus, lexeme: "-", line: 4),
                                            .literal(.number(1)))
                                    ])))
                    ])),
            .expression(
                .call(
                    .variable(Token(type: .identifier, lexeme: "fact", line: 5)),
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
        let statements: [Statement] = [
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
                                    .variable(Token(type: .identifier, lexeme: "a", line: 1)),
                                    Token(type: .plus, lexeme: "+", line: 1),
                                    .variable(Token(type: .identifier, lexeme: "b", line: 1))))
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
        let statements: [Statement] = [
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
                                            .variable(Token(type: .identifier, lexeme: "n", line: 2)),
                                            Token(type: .plus, lexeme: "+", line: 2),
                                            .variable(Token(type: .identifier, lexeme: "a", line: 2))))
                                ]))
                    ])),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "addTwo", line: 4),
                .call(
                    .variable(Token(type: .identifier, lexeme: "makeAdder", line: 4)),
                    Token(type: .rightParen, lexeme: ")", line: 4),
                    [
                        .literal(.number(2))
                    ])),
            .expression(
                .call(
                    .variable(Token(type: .identifier, lexeme: "addTwo", line: 5)),
                    Token(type: .rightParen, lexeme: ")", line: 5),
                    [.literal(.number(5))]))
        ]

        let interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: statements)
        let expected: LoxValue = .number(7)
        XCTAssertEqual(actual, expected)
    }
}
