//
//  ParserTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/27/24.
//

import XCTest

final class ParserTests: XCTestCase {
    func testParseStringLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .string, lexeme: "\"forty-two\"", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .literal(.string("forty-two"))
        XCTAssertEqual(actual, expected)
    }

    func testParseNumericLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .number, lexeme: "123.456", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .literal(.number(123.456))
        XCTAssertEqual(actual, expected)
    }

    func testParseBooleanLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .literal(.boolean(true))
        XCTAssertEqual(actual, expected)
    }

    func testParseNilLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .nil, lexeme: "nil", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .literal(.nil)
        XCTAssertEqual(actual, expected)
    }

    func testParseGroupingExpression() throws {
        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .number, lexeme: "42", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .grouping(.literal(.number(42)))
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidGroupingExpression() throws {
        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .number, lexeme: "42", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .eof, lexeme: "", line: 1)
        let expectedError = ParseError.missingClosingParenthesis(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseInvalidExpression() throws {
        let tokens: [Token] = [
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .number, lexeme: "42", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .rightParen, lexeme: ")", line: 1)
        let expectedError = ParseError.expectedPrimaryExpression(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseUnaryExpression() throws {
        let tokens: [Token] = [
            Token(type: .bang, lexeme: "!", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .unary(
            Token(type: .bang, lexeme: "!", line: 1),
            .literal(.boolean(true)))
        XCTAssertEqual(actual, expected)
    }

    func testParseFactorExpression() throws {
        let tokens: [Token] = [
            Token(type: .number, lexeme: "21", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .number, lexeme: "2", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .binary(
            .literal(.number(21)),
            Token(type: .star, lexeme: "*", line: 1),
            .literal(.number(2)))
        XCTAssertEqual(actual, expected)
    }

    func testParseTermExpression() throws {
        let tokens: [Token] = [
            Token(type: .string, lexeme: "\"forty-\"", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .string, lexeme: "\"two\"", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .binary(
            .literal(.string("forty-")),
            Token(type: .plus, lexeme: "+", line: 1),
            .literal(.string("two")))
        XCTAssertEqual(actual, expected)
    }

    func testParseComparisonExpression() throws {
        let tokens: [Token] = [
            Token(type: .number, lexeme: "1", line: 1),
            Token(type: .lessEqual, lexeme: "<=", line: 1),
            Token(type: .number, lexeme: "2", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .binary(
            .literal(.number(1)),
            Token(type: .lessEqual, lexeme: "<=", line: 1),
            .literal(.number(2)))
        XCTAssertEqual(actual, expected)
    }

    func testParseEqualityExpression() throws {
        let tokens: [Token] = [
            Token(type: .string, lexeme: "\"forty-two\"", line: 1),
            Token(type: .equalEqual, lexeme: "==", line: 1),
            Token(type: .nil, lexeme: "nil", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .binary(
            .literal(.string("forty-two")),
            Token(type: .equalEqual, lexeme: "==", line: 1),
            .literal(.nil))
        XCTAssertEqual(actual, expected)
    }

    func testParseComplexExpression() throws {
        // (-2) * (3 + 4)
        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .minus, lexeme: "-", line: 1),
            Token(type: .number, lexeme: "2", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .number, lexeme: "3", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .number, lexeme: "4", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: Expression = .binary(
            .grouping(.unary(
                Token(type: .minus, lexeme: "-", line: 1),
                .literal(.number(2)))),
            Token(type: .star, lexeme: "*", line: 1),
            .grouping(.binary(
                .literal(.number(3)),
                Token(type: .plus, lexeme: "+", line: 1),
                .literal(.number(4)))))

        XCTAssertEqual(actual, expected)
    }
}
