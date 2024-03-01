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
        var interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        let stmt: Statement = .expression(.literal(.number(42)))
        var interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])!
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        let stmt: Statement = .expression(.grouping(.literal(.number(42))))
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()

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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()

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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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

        var interpreter = Interpreter()
        let actual = try interpreter.interpretRepl(statements: [stmt])
        let expected: LoxValue = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretVariableDeclaration() throws {
        let stmt: Statement =
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.number(42)))

        var interpreter = Interpreter()
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

        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
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
        var interpreter = Interpreter()
        let _ = try interpreter.interpretRepl(statements: statements)
        let environment = interpreter.environment
        let actual = try environment.getValue(name: "theAnswer")
        let expected: LoxValue = .number(42)
        XCTAssertEqual(actual, expected)
    }
}
