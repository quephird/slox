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
}
