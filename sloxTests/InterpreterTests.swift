//
//  InterpreterTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/27/24.
//

import XCTest

final class InterpreterTests: XCTestCase {
    func testInterpretStringLiteralExpression() throws {
        let expr: Expression = .literal(.string("forty-two"))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretNumericLiteralExpression() throws {
        let expr: Expression = .literal(.number(42))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretGroupingExpression() throws {
        let expr: Expression = .grouping(.literal(.number(42)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretUnaryExpression() throws {
        let expr: Expression = .unary(
            Token(type: .bang, lexeme: "!", line: 1),
            .literal(.boolean(true)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .boolean(false)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidUnaryExpression() throws {
        let expr: Expression = .unary(
            Token(type: .minus, lexeme: "-", line: 1),
            .literal(.string("forty-two")))
        let interpreter = Interpreter()

        let expectedError = RuntimeError.unaryOperandMustBeNumber
        XCTAssertThrowsError(try interpreter.interpret(expr: expr)) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretNumericBinaryExpression() throws {
        let expr: Expression = .binary(
            .literal(.number(21)),
            Token(type: .star, lexeme: "*", line: 1),
            .literal(.number(2)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .number(42)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretStringlyBinaryExpression() throws {
        let expr: Expression = .binary(
            .literal(.string("forty")),
            Token(type: .plus, lexeme: "+", line: 1),
            .literal(.string("-two")))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .string("forty-two")
        XCTAssertEqual(actual, expected)
    }

    func testInterpretEqualityExpression() throws {
        let expr: Expression = .binary(
            .literal(.boolean(true)),
            Token(type: .bangEqual, lexeme: "!=", line: 1),
            .literal(.boolean(false)))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .boolean(true)
        XCTAssertEqual(actual, expected)
    }

    func testInterpretInvalidBinaryExpression() throws {
        let expr: Expression = .binary(
            .literal(.string("twenty-one")),
            Token(type: .star, lexeme: "*", line: 1),
            .literal(.number(2)))
        let interpreter = Interpreter()

        let expectedError = RuntimeError.binaryOperandsMustBeNumbers
        XCTAssertThrowsError(try interpreter.interpret(expr: expr)) { actualError in
            XCTAssertEqual(actualError as! RuntimeError, expectedError)
        }
    }

    func testInterpretComplexExpression() throws {
        let expr: Expression = .binary(
            .grouping(.unary(
                Token(type: .minus, lexeme: "-", line: 1),
                .literal(.number(2)))),
            Token(type: .star, lexeme: "*", line: 1),
            .grouping(.binary(
                .literal(.number(3)),
                Token(type: .plus, lexeme: "+", line: 1),
                .literal(.number(4)))))
        let interpreter = Interpreter()
        let actual = try interpreter.interpret(expr: expr)
        let expected: Literal = .number(-14)
        XCTAssertEqual(actual, expected)
    }
}
