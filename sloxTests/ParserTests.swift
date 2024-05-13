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
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(.string(Token(type: .string, lexeme: "\"forty-two\"", line: 1))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseNumericLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .double, lexeme: "123.456", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .literal(
                    Token(type: .double, lexeme: "123.456", line: 1),
                    .double(123.456)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseBooleanLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .literal(
                    Token(type: .true, lexeme: "true", line: 1),
                    .boolean(true)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseNilLiteralExpression() throws {
        let tokens: [Token] = [
            Token(type: .nil, lexeme: "nil", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .literal(
                    Token(type: .nil, lexeme: "nil", line: 1),
                    .nil))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseGroupingExpression() throws {
        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .grouping(
                    Token(type: .leftParen, lexeme: "(", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "42", line: 1),
                        .int(42))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidGroupingExpression() throws {
        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .semicolon, lexeme: ";", line: 1)
        let expectedError = ParseError.missingClosingParenthesis(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseInvalidExpression() throws {
        let tokens: [Token] = [
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
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
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .unary(
                    Token(type: .bang, lexeme: "!", line: 1),
                    .literal(
                        Token(type: .true, lexeme: "true", line: 1),
                        .boolean(true))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseFactorExpression() throws {
        let tokens: [Token] = [
            Token(type: .int, lexeme: "21", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .literal(
                        Token(type: .int, lexeme: "21", line: 1),
                        .int(21)),
                    Token(type: .star, lexeme: "*", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "2", line: 1),
                        .int(2))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseFactorExpressionWithModulusOperator() throws {
        let tokens: [Token] = [
            Token(type: .int, lexeme: "5", line: 1),
            Token(type: .modulus, lexeme: "%", line: 1),
            Token(type: .int, lexeme: "3", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .literal(
                        Token(type: .int, lexeme: "5", line: 1),
                        .int(5)),
                    Token(type: .modulus, lexeme: "%", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "3", line: 1),
                        .int(3))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseTermExpression() throws {
        let tokens: [Token] = [
            Token(type: .string, lexeme: "\"forty-\"", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .string, lexeme: "\"two\"", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .string(Token(type: .string, lexeme: "\"forty-\"", line: 1)),
                    Token(type: .plus, lexeme: "+", line: 1),
                    .string(Token(type: .string, lexeme: "\"two\"", line: 1))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseComparisonExpression() throws {
        let tokens: [Token] = [
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .lessEqual, lexeme: "<=", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .literal(
                        Token(type: .int, lexeme: "1", line: 1),
                        .int(1)),
                    Token(type: .lessEqual, lexeme: "<=", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "2", line: 1),
                        .int(2))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseEqualityExpression() throws {
        let tokens: [Token] = [
            Token(type: .string, lexeme: "\"forty-two\"", line: 1),
            Token(type: .equalEqual, lexeme: "==", line: 1),
            Token(type: .nil, lexeme: "nil", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .string(Token(type: .string, lexeme: "\"forty-two\"", line: 1)),
                    Token(type: .equalEqual, lexeme: "==", line: 1),
                    .literal(
                        Token(type: .nil, lexeme: "nil", line: 1),
                        .nil)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseOrExpression() throws {
        let tokens: [Token] = [
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .or, lexeme: "or", line: 1),
            Token(type: .false, lexeme: "false", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .logical(
                    .literal(
                        Token(type: .true, lexeme: "true", line: 1),
                        .boolean(true)),
                    Token(type: .or, lexeme: "or", line: 1),
                    .literal(
                        Token(type: .false, lexeme: "false", line: 1),
                        .boolean(false))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseAndExpression() throws {
        let tokens: [Token] = [
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .and, lexeme: "and", line: 1),
            Token(type: .false, lexeme: "false", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .logical(
                    .literal(
                        Token(type: .true, lexeme: "true", line: 1),
                        .boolean(true)),
                    Token(type: .and, lexeme: "and", line: 1),
                    .literal(
                        Token(type: .false, lexeme: "false", line: 1),
                        .boolean(false))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseMixedLogicalExpression() throws {
        let tokens: [Token] = [
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .and, lexeme: "and", line: 1),
            Token(type: .false, lexeme: "false", line: 1),
            Token(type: .or, lexeme: "or", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .logical(
                    .logical(
                        .literal(
                            Token(type: .true, lexeme: "true", line: 1),
                            .boolean(true)),
                        Token(type: .and, lexeme: "and", line: 1),
                        .literal(
                            Token(type: .false, lexeme: "false", line: 1),
                            .boolean(false))),
                    Token(type: .or, lexeme: "or", line: 1),
                    .literal(
                        Token(type: .true, lexeme: "true", line: 1),
                        .boolean(true))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseAssignmentExpression() throws {
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "theAnswer", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .assignment(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "42", line: 1),
                        .int(42)),
                    UnresolvedDepth()))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseCompoundAssignmentExpression() throws {
        // foo += 42;
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .plusEqual, lexeme: "+=", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .assignment(
                    Token(type: .identifier, lexeme: "foo", line: 1),
                    .binary(
                        .variable(
                            Token(type: .identifier, lexeme: "foo", line: 1),
                            UnresolvedDepth()),
                        Token(type: .plus, lexeme: "+", line: 1),
                        .literal(
                            Token(type: .int, lexeme: "42", line: 1),
                            .int(42))),
                    UnresolvedDepth()))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseComplexExpression() throws {
        // (-2) * (3 + 4);

        let tokens: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .minus, lexeme: "-", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .int, lexeme: "3", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .int, lexeme: "4", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .binary(
                    .grouping(
                        Token(type: .leftParen, lexeme: "(", line: 1),
                        .unary(
                            Token(type: .minus, lexeme: "-", line: 1),
                            .literal(
                                Token(type: .int, lexeme: "2", line: 1),
                                .int(2)))),
                    Token(type: .star, lexeme: "*", line: 1),
                    .grouping(
                        Token(type: .leftParen, lexeme: "(", line: 1),
                            .binary(
                            .literal(
                                Token(type: .int, lexeme: "3", line: 1),
                                .int(3)),
                            Token(type: .plus, lexeme: "+", line: 1),
                            .literal(
                                Token(type: .int, lexeme: "4", line: 1),
                                .int(4))))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseTypicalForStatement() throws {
        // for (var i = 0; i < 5; i = i + 1)
        //     print i;
        //
        let tokens: [Token] = [
            Token(type: .for, lexeme: "for", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),

            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "0", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),

            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .less, lexeme: "<", line: 1),
            Token(type: .int, lexeme: "5", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),

            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .identifier, lexeme: "i", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .for(
                Token(type: .for, lexeme: "for", line: 1),
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "i", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "0", line: 1),
                        .int(0))),
                .binary(
                    .variable(
                        Token(type: .identifier, lexeme: "i", line: 1),
                        UnresolvedDepth()),
                    Token(type: .less, lexeme: "<", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "5", line: 1),
                        .int(5))),
                .assignment(
                    Token(type: .identifier, lexeme: "i", line: 1),
                    .binary(
                        .variable(
                            Token(type: .identifier, lexeme: "i", line: 1),
                            UnresolvedDepth()),
                        Token(type: .plus, lexeme: "+", line: 1),
                        .literal(
                            Token(type: .int, lexeme: "1", line: 1),
                            .int(1))),
                    UnresolvedDepth()),
                .print(
                    Token(type: .print, lexeme: "print", line: 2),
                    .variable(
                        Token(type: .identifier, lexeme: "i", line: 2),
                        UnresolvedDepth()))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInfiniteForStatement() throws {
        // for (;;)
        //     print i;
        //
        let tokens: [Token] = [
            Token(type: .for, lexeme: "for", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .identifier, lexeme: "i", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),
            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .for(
                Token(type: .for, lexeme: "for", line: 1),
                nil,
                .literal(
                    Token(type: .true, lexeme: "true", line: 0),
                    .boolean(true)),
                nil,
                .print(
                    Token(type: .print, lexeme: "print", line: 2),
                    .variable(
                        Token(type: .identifier, lexeme: "i", line: 2),
                        UnresolvedDepth())))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidForStatement() throws {
        let tokens: [Token] = [
            Token(type: .for, lexeme: "for", line: 1),

            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "0", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),

            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .less, lexeme: "<", line: 1),
            Token(type: .int, lexeme: "5", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),

            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .identifier, lexeme: "i", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .int, lexeme: "1", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .identifier, lexeme: "i", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .var, lexeme: "var", line: 1)
        let expectedError = ParseError.missingOpenParenForForStatement(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseIfStatement() throws {
        // if (true)
        //     print "Hello!"
        //
        let tokens: [Token] = [
            Token(type: .if, lexeme: "if", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .string, lexeme: "\"Hello!\"", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .if(
                Token(type: .if, lexeme: "if", line: 1),
                .literal(
                    Token(type: .true, lexeme: "true", line: 1),
                    .boolean(true)),
                .print(
                    Token(type: .print, lexeme: "print", line: 2),
                    .string(Token(type: .string, lexeme: "\"Hello!\"", line: 2))),
                nil)
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseIfStatementWithAlternative() throws {
        // if (true)
        //     print "Hello!"
        // else
        //     print "Goodbye"
        //
        let tokens: [Token] = [
            Token(type: .if, lexeme: "if", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .string, lexeme: "\"Hello!\"", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .else, lexeme: "else", line: 3),

            Token(type: .print, lexeme: "print", line: 4),
            Token(type: .string, lexeme: "\"Goodbye\"", line: 4),
            Token(type: .semicolon, lexeme: ";", line: 4),

            Token(type: .eof, lexeme: "", line: 4),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .if(
                Token(type: .if, lexeme: "if", line: 1),
                .literal(
                    Token(type: .true, lexeme: "true", line: 1),
                    .boolean(true)),
                .print(
                    Token(type: .print, lexeme: "print", line: 2),
                    .string(Token(type: .string, lexeme: "\"Hello!\"", line: 2))),
                .print(
                    Token(type: .print, lexeme: "print", line: 4),
                    .string(Token(type: .string, lexeme: "\"Goodbye\"", line: 4))))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidIfStatement() throws {
        // if true
        //     print "Hello!"
        //
        let tokens: [Token] = [
            Token(type: .if, lexeme: "if", line: 1),
            Token(type: .true, lexeme: "true", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .string, lexeme: "\"Hello!\"", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .true, lexeme: "true", line: 1)
        let expectedError = ParseError.missingOpenParenForIfStatement(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParsePrintStatement() throws {
        let tokens: [Token] = [
            Token(type: .print, lexeme: "print", line: 1),
            Token(type: .string, lexeme: "\"forty-two\"", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .print(
                Token(type: .print, lexeme: "print", line: 1),
                .string(Token(type: .string, lexeme: "\"forty-two\"", line: 1)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseVariableDeclarationWithoutInitialization() throws {
        let tokens: [Token] = [
            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .identifier, lexeme: "theAnswer", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                nil)
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseVariableDeclarationWithInitialization() throws {
        let tokens: [Token] = [
            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .identifier, lexeme: "theAnswer", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidVariableDeclaration() throws {
        let tokens: [Token] = [
            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "42", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .equal, lexeme: "=", line: 1)
        let expectedError = ParseError.missingVariableName(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSetOfStatements() throws {
        // var the = 2;
        // var answer = 21;
        // print the * answer;

        let tokens: [Token] = [
            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .identifier, lexeme: "the", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),

            Token(type: .var, lexeme: "var", line: 2),
            Token(type: .identifier, lexeme: "answer", line: 2),
            Token(type: .equal, lexeme: "=", line: 2),
            Token(type: .int, lexeme: "21", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .identifier, lexeme: "the", line: 3),
            Token(type: .star, lexeme: "*", line: 3),
            Token(type: .identifier, lexeme: "answer", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .eof, lexeme: "", line: 3),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "the", line: 1),
                .literal(
                    Token(type: .int, lexeme: "2", line: 1),
                    .int(2))),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 2),
                .literal(
                    Token(type: .int, lexeme: "21", line: 2),
                    .int(21))),
            .print(
                Token(type: .print, lexeme: "print", line: 3),
                .binary(
                    .variable(
                        Token(type: .identifier, lexeme: "the", line: 3),
                        UnresolvedDepth()),
                    Token(type: .star, lexeme: "*", line: 3),
                    .variable(
                        Token(type: .identifier, lexeme: "answer", line: 3),
                        UnresolvedDepth()))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseBlock() throws {
        // {
        //     var theAnswer = 42;
        //     print theAnswer;
        // }

        let tokens: [Token] = [
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .var, lexeme: "var", line: 2),
            Token(type: .identifier, lexeme: "theAnswer", line: 2),
            Token(type: .equal, lexeme: "=", line: 2),
            Token(type: .int, lexeme: "42", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .identifier, lexeme: "theAnswer", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .eof, lexeme: "", line: 4),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .block(
                Token(type: .leftBrace, lexeme: "{", line: 1),
                [
                    .variableDeclaration(
                        Token(type: .identifier, lexeme: "theAnswer", line: 2),
                        .literal(
                            Token(type: .int, lexeme: "42", line: 2),
                            .int(42))),
                    .print(
                        Token(type: .print, lexeme: "print", line: 3),
                        .variable(
                            Token(type: .identifier, lexeme: "theAnswer", line: 3),
                            UnresolvedDepth())),
                ]),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidBlock() throws {
        let tokens: [Token] = [
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .var, lexeme: "var", line: 2),
            Token(type: .identifier, lexeme: "theAnswer", line: 2),
            Token(type: .equal, lexeme: "=", line: 2),
            Token(type: .int, lexeme: "42", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .identifier, lexeme: "theAnswer", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .eof, lexeme: "", line: 4),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .semicolon, lexeme: ";", line: 3)
        let expectedError = ParseError.missingClosingBrace(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseWhileStatement() throws {
        // while (x <= 5) {
        //     print x;
        //     x = x + 1;
        // }
        //
        let tokens: [Token] = [
            Token(type: .while, lexeme: "while", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "x", line: 1),
            Token(type: .lessEqual, lexeme: "<=", line: 1),
            Token(type: .int, lexeme: "5", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .identifier, lexeme: "x", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .identifier, lexeme: "x", line: 3),
            Token(type: .equal, lexeme: "=", line: 3),
            Token(type: .identifier, lexeme: "x", line: 3),
            Token(type: .plus, lexeme: "+", line: 3),
            Token(type: .int, lexeme: "1", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),
            Token(type: .eof, lexeme: "", line: 4),
        ]
        var parser = Parser(tokens: tokens)

        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .while(
                Token(type: .while, lexeme: "while", line: 1),
                .binary(
                    .variable(
                        Token(type: .identifier, lexeme: "x", line: 1),
                        UnresolvedDepth()),
                    Token(type: .lessEqual, lexeme: "<=", line: 1),
                    .literal(
                        Token(type: .int, lexeme: "5", line: 1),
                        .int(5))),
                .block(
                    Token(type: .leftBrace, lexeme: "{", line: 1),
                    [
                        .print(
                            Token(type: .print, lexeme: "print", line: 2),
                            .variable(
                                Token(type: .identifier, lexeme: "x", line: 2),
                                UnresolvedDepth())),
                        .expression(
                            .assignment(
                                Token(type: .identifier, lexeme: "x", line: 3),
                                .binary(
                                    .variable(
                                        Token(type: .identifier, lexeme: "x", line: 3),
                                        UnresolvedDepth()),
                                    Token(type: .plus, lexeme: "+", line: 3),
                                    .literal(
                                        Token(type: .int, lexeme: "1", line: 3),
                                        .int(1))),
                                UnresolvedDepth())),
                    ]))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseInvalidWhileStatement() throws {
        // while true
        //     print x;
        //
        let tokens: [Token] = [
            Token(type: .while, lexeme: "while", line: 1),
            Token(type: .true, lexeme: "true", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .identifier, lexeme: "x", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .eof, lexeme: "", line: 2),
        ]
        var parser = Parser(tokens: tokens)

        let lastToken = Token(type: .true, lexeme: "true", line: 1)
        let expectedError = ParseError.missingOpenParenForWhileStatement(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseFunctionDeclaration() throws {
        // fun theAnswer() {
        //     print 42;
        // }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .identifier, lexeme: "theAnswer", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .int, lexeme: "42", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 3),
            Token(type: .eof, lexeme: "", line: 3),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                [],
                .lambda(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    ParameterList(normalParameters: []),
                    .block(
                        Token(type: .leftBrace, lexeme: "{", line: 1),
                        [
                            .print(
                                Token(type: .print, lexeme: "print", line: 2),
                                .literal(
                                    Token(type: .int, lexeme: "42", line: 2),
                                    .int(42)))
                        ]))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseFunctionDeclarationWithArgumentsAndReturn() throws {
        // fun add(a, b) {
        //     return a + b;
        // }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .identifier, lexeme: "add", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .return, lexeme: "return", line: 2),
            Token(type: .identifier, lexeme: "a", line: 2),
            Token(type: .plus, lexeme: "+", line: 2),
            Token(type: .identifier, lexeme: "b", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 3),
            Token(type: .eof, lexeme: "", line: 3),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                [],
                .lambda(
                    Token(type: .identifier, lexeme: "add", line: 1),
                    ParameterList(normalParameters: [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ]),
                    .block(
                        Token(type: .leftBrace, lexeme: "{", line: 1),
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 2),
                                .binary(
                                    .variable(
                                        Token(type: .identifier, lexeme: "a", line: 2),
                                        UnresolvedDepth()),
                                    Token(type: .plus, lexeme: "+", line: 2),
                                    .variable(
                                        Token(type: .identifier, lexeme: "b", line: 2),
                                        UnresolvedDepth())))
                        ]))
            )
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseVariadicFunction() throws {
        // fun foo(a, *b) {
        //     return b;
        // }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .return, lexeme: "return", line: 2),
            Token(type: .identifier, lexeme: "b", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "foo", line: 1),
                [],
                .lambda(
                    Token(type: .identifier, lexeme: "foo", line: 1),
                    ParameterList(
                        normalParameters: [
                            Token(type: .identifier, lexeme: "a", line: 1),
                        ],
                        variadicParameter: Token(type: .identifier, lexeme: "b", line: 1)),
                    .block(
                        Token(type: .leftBrace, lexeme: "{", line: 1),
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 2),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 2),
                                    UnresolvedDepth()))
                        ]))
            )
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseFunctionWithTwoVariadicParameters() throws {
        // fun foo(a, *b, *c) {
        //     return a;
        // }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .identifier, lexeme: "c", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .return, lexeme: "return", line: 2),
            Token(type: .identifier, lexeme: "a", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .comma, lexeme: ",", line: 1)
        let expectedError = ParseError.onlyOneTrailingVariadicParameterAllowed(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseFunctionWithOneMoreRegularParameterFollowingVariadicParameter() throws {
        // fun foo(a, *b, c) {
        //     return a;
        // }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .identifier, lexeme: "c", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .return, lexeme: "return", line: 2),
            Token(type: .identifier, lexeme: "a", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .comma, lexeme: ",", line: 1)
        let expectedError = ParseError.onlyOneTrailingVariadicParameterAllowed(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseFunctionCall() throws {
        // add(1, 2)
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "add", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "add", line: 1),
                        UnresolvedDepth()),
                    Token(type: .rightParen, lexeme: ")", line: 1),
                    [
                        .literal(
                            Token(type: .int, lexeme: "1", line: 1),
                            .int(1)),
                        .literal(
                            Token(type: .int, lexeme: "2", line: 1),
                            .int(2)),
                    ]))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseFunctionCallWithSplattedArgument() throws {
        // add(*[1, 2, 3])
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "add", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .int, lexeme: "3", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .call(
                    .variable(
                        Token(type: .identifier, lexeme: "add", line: 1),
                        UnresolvedDepth()),
                    Token(type: .rightParen, lexeme: ")", line: 1),
                    [
                        .splat(
                            Token(type: .star, lexeme: "*", line: 1),
                            .list(
                                Token(type: .leftBracket, lexeme: "[", line: 1),
                                [
                                    .literal(
                                        Token(type: .int, lexeme: "1", line: 1),
                                        .int(1)),
                                    .literal(
                                        Token(type: .int, lexeme: "2", line: 1),
                                        .int(2)),
                                    .literal(
                                        Token(type: .int, lexeme: "3", line: 1),
                                        .int(3)),
                                ])),
                    ])),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseLambdaExpression() throws {
        // fun (a, b) { return a + b; }
        let tokens: [Token] = [
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .leftBrace, lexeme: "{", line: 1),
            Token(type: .return, lexeme: "return", line: 1),
            Token(type: .identifier, lexeme: "a", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .identifier, lexeme: "b", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .rightBrace, lexeme: "}", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .lambda(
                    Token(type: .fun, lexeme: "fun", line: 1),
                    ParameterList(normalParameters: [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ]),
                    .block(
                        Token(type: .leftBrace, lexeme: "{", line: 1),
                        [
                            .return(
                                Token(type: .return, lexeme: "return", line: 1),
                                .binary(
                                    .variable(
                                        Token(type: .identifier, lexeme: "a", line: 1),
                                        UnresolvedDepth()),
                                    Token(type: .plus, lexeme: "+", line: 1),
                                    .variable(
                                        Token(type: .identifier, lexeme: "b", line: 1),
                                        UnresolvedDepth()))),
                        ])))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassDeclarationWithMethods() throws {
        // class Person {
        //     sayName() {
        //         print this.name;
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Person", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .identifier, lexeme: "sayName", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .this, lexeme: "this", line: 3),
            Token(type: .dot, lexeme: ".", line: 3),
            Token(type: .identifier, lexeme: "name", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        [],
                        .lambda(
                            Token(type: .identifier, lexeme: "sayName", line: 2),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 3),
                                        .get(
                                            Token(type: .dot, lexeme: ".", line: 3),
                                            .this(
                                                Token(type: .this, lexeme: "this", line: 3),
                                                UnresolvedDepth()),
                                            Token(type: .identifier, lexeme: "name", line: 3)))
                                ])))
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseGetExpression() throws {
        // person.name;
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "person", line: 1),
            Token(type: .dot, lexeme: ".", line: 1),
            Token(type: .identifier, lexeme: "name", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .get(
                    Token(type: .dot, lexeme: ".", line: 1),
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 1),
                        UnresolvedDepth()),
                    Token(type: .identifier, lexeme: "name", line: 1)))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseSetExpression() throws {
        // person.name = "Danielle";
        let tokens: [Token] = [
            Token(type: .identifier, lexeme: "person", line: 1),
            Token(type: .dot, lexeme: ".", line: 1),
            Token(type: .identifier, lexeme: "name", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .string, lexeme: "\"Danielle\"", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .set(
                    Token(type: .dot, lexeme: ".", line: 1),
                    .variable(
                        Token(type: .identifier, lexeme: "person", line: 1),
                        UnresolvedDepth()),
                    Token(type: .identifier, lexeme: "name", line: 1),
                    .string(Token(type: .string, lexeme: "\"Danielle\"", line: 1)))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithStaticMethod() throws {
        // class Math {
        //     class add(a, b) {
        //         return a + b;
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Math", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .class, lexeme: "class", line: 2),
            Token(type: .identifier, lexeme: "add", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .identifier, lexeme: "a", line: 2),
            Token(type: .comma, lexeme: ",", line: 2),
            Token(type: .identifier, lexeme: "b", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .return, lexeme: "return", line: 3),
            Token(type: .identifier, lexeme: "a", line: 3),
            Token(type: .plus, lexeme: "+", line: 3),
            Token(type: .identifier, lexeme: "b", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Math", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "add", line: 2),
                        [
                            Token(type: .class, lexeme: "class", line: 2),
                        ],
                        .lambda(
                            Token(type: .identifier, lexeme: "add", line: 2),
                            ParameterList(normalParameters: [
                                Token(type: .identifier, lexeme: "a", line: 2),
                                Token(type: .identifier, lexeme: "b", line: 2),
                            ]),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .return(
                                        Token(type: .return, lexeme: "return", line: 3),
                                        .binary(
                                            .variable(
                                                Token(type: .identifier, lexeme: "a", line: 3),
                                                UnresolvedDepth()),
                                            Token(type: .plus, lexeme: "+", line: 3),
                                            .variable(
                                                Token(type: .identifier, lexeme: "b", line: 3),
                                                UnresolvedDepth())))
                                ])))
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithInstanceAndStaticMethods() throws {
        // class Foo {
        //     class foo() {
        //         print "foo!";
        //     }
        //
        //     bar() {
        //         print "bar!";
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .class, lexeme: "class", line: 2),
            Token(type: .identifier, lexeme: "foo", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"foo!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .identifier, lexeme: "bar", line: 6),
            Token(type: .leftParen, lexeme: "(", line: 6),
            Token(type: .rightParen, lexeme: ")", line: 6),
            Token(type: .leftBrace, lexeme: "{", line: 6),

            Token(type: .print, lexeme: "print", line: 7),
            Token(type: .string, lexeme: "\"bar!\"", line: 7),
            Token(type: .semicolon, lexeme: ";", line: 7),

            Token(type: .rightBrace, lexeme: "}", line: 8),

            Token(type: .rightBrace, lexeme: "}", line: 9),
            Token(type: .eof, lexeme: "", line: 9),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Foo", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        [
                            Token(type: .class, lexeme: "class", line: 2),
                        ],
                        .lambda(
                            Token(type: .identifier, lexeme: "foo", line: 2),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 3),
                                        .string(Token(type: .string, lexeme: "\"foo!\"", line: 3))),
                                ]))),
                    .function(
                        Token(type: .identifier, lexeme: "bar", line: 6),
                        [],
                        .lambda(
                            Token(type: .identifier, lexeme: "bar", line: 6),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 6),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 7),
                                        .string(Token(type: .string, lexeme: "\"bar!\"", line: 7))),
                                ]))),
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassThatInheritsFromAnotherAndCallsSuper() throws {
        // class B < A {
        //     someMethod(arg) {
        //         return super.someMethod(arg);
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "B", line: 1),
            Token(type: .less, lexeme: "<", line: 1),
            Token(type: .identifier, lexeme: "A", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .identifier, lexeme: "someMethod", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .identifier, lexeme: "arg", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .return, lexeme: "return", line: 3),
            Token(type: .super, lexeme: "super", line: 3),
            Token(type: .dot, lexeme: ".", line: 3),
            Token(type: .identifier, lexeme: "someMethod", line: 3),
            Token(type: .leftParen, lexeme: "(", line: 3),
            Token(type: .identifier, lexeme: "arg", line: 3),
            Token(type: .rightParen, lexeme: ")", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "B", line: 1),
                .variable(
                    Token(type: .identifier, lexeme: "A", line: 1),
                    UnresolvedDepth()),
                [
                    .function(
                        Token(type: .identifier, lexeme: "someMethod", line: 2),
                        [],
                        .lambda(
                            Token(type: .identifier, lexeme: "someMethod", line: 2),
                            ParameterList(normalParameters: [
                                Token(type: .identifier, lexeme: "arg", line: 2)
                            ]),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .return(
                                        Token(type: .return, lexeme: "return", line: 3),
                                        .call(
                                            .super(
                                                Token(type: .super, lexeme: "super", line: 3),
                                                Token(type: .identifier, lexeme: "someMethod", line: 3),
                                                UnresolvedDepth()),
                                            Token(type: .rightParen, lexeme: ")", line: 3),
                                            [
                                                .variable(
                                                    Token(type: .identifier, lexeme: "arg", line: 3),
                                                    UnresolvedDepth())
                                            ]))
                                ])))
                ]),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithComputedProperty() throws {
        // class Circle {
        //     area {
        //         return 3.14159 * this.radius * this.radius;
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Circle", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .identifier, lexeme: "area", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .return, lexeme: "return", line: 3),
            Token(type: .double, lexeme: "3.14159", line: 3),
            Token(type: .star, lexeme: "*", line: 3),
            Token(type: .this, lexeme: "this", line: 3),
            Token(type: .dot, lexeme: ".", line: 3),
            Token(type: .identifier, lexeme: "radius", line: 3),
            Token(type: .star, lexeme: "*", line: 3),
            Token(type: .this, lexeme: "this", line: 3),
            Token(type: .dot, lexeme: ".", line: 3),
            Token(type: .identifier, lexeme: "radius", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Circle", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "area", line: 2),
                        [],
                        .lambda(
                            Token(type: .identifier, lexeme: "area", line: 2),
                            nil,
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .return(
                                        Token(type: .return, lexeme: "return", line: 3),
                                        .binary(
                                            .binary(
                                                .literal(
                                                    Token(type: .double, lexeme: "3.14159", line: 3),
                                                    .double(3.14159)),
                                                Token(type: .star, lexeme: "*", line: 3),
                                                .get(
                                                    Token(type: .dot, lexeme: ".", line: 3),
                                                    .this(
                                                        Token(type: .this, lexeme: "this", line: 3),
                                                        UnresolvedDepth()),
                                                    Token(type: .identifier, lexeme: "radius", line: 3))),
                                            Token(type: .star, lexeme: "*", line: 3),
                                            .get(
                                                Token(type: .dot, lexeme: ".", line: 3),
                                                .this(
                                                    Token(type: .this, lexeme: "this", line: 3),
                                                    UnresolvedDepth()),
                                                Token(type: .identifier, lexeme: "radius", line: 3)))),
                                ])))
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithPrivateMethod() throws {
        // class Foo {
        //     private foo() {
        //         print "foo!";
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .private, lexeme: "private", line: 2),
            Token(type: .identifier, lexeme: "foo", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"foo!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Foo", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        [
                            Token(type: .private, lexeme: "private", line: 2),
                        ],
                        .lambda(
                            Token(type: .identifier, lexeme: "foo", line: 2),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 3),
                                        .string(Token(type: .string, lexeme: "\"foo!\"", line: 3))),
                                ]))),
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithTwoPrivateStaticMethods() throws {
        // class Foo {
        //     class private foo() {
        //         print "foo!";
        //     }
        //
        //     private class bar() {
        //         print "bar!";
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .class, lexeme: "class", line: 2),
            Token(type: .private, lexeme: "private", line: 2),
            Token(type: .identifier, lexeme: "foo", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"foo!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .private, lexeme: "private", line: 6),
            Token(type: .class, lexeme: "class", line: 6),
            Token(type: .identifier, lexeme: "bar", line: 6),
            Token(type: .leftParen, lexeme: "(", line: 6),
            Token(type: .rightParen, lexeme: ")", line: 6),
            Token(type: .leftBrace, lexeme: "{", line: 6),

            Token(type: .print, lexeme: "print", line: 7),
            Token(type: .string, lexeme: "\"bar!\"", line: 7),
            Token(type: .semicolon, lexeme: ";", line: 7),

            Token(type: .rightBrace, lexeme: "}", line: 8),

            Token(type: .rightBrace, lexeme: "}", line: 9),
            Token(type: .eof, lexeme: "", line: 9),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Foo", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        [
                            Token(type: .class, lexeme: "class", line: 2),
                            Token(type: .private, lexeme: "private", line: 2),
                        ],
                        .lambda(
                            Token(type: .identifier, lexeme: "foo", line: 2),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 2),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 3),
                                        .string(Token(type: .string, lexeme: "\"foo!\"", line: 3))),
                                ]))),
                    .function(
                        Token(type: .identifier, lexeme: "bar", line: 6),
                        [
                            Token(type: .private, lexeme: "private", line: 6),
                            Token(type: .class, lexeme: "class", line: 6),
                        ],
                        .lambda(
                            Token(type: .identifier, lexeme: "bar", line: 6),
                            ParameterList(normalParameters: []),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 6),
                                [
                                    .print(
                                        Token(type: .print, lexeme: "print", line: 7),
                                        .string(Token(type: .string, lexeme: "\"bar!\"", line: 7))),
                                ]))),
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseClassWithMethodWithDuplicateModifiers() throws {
        // class Foo {
        //     private class private foo() {
        //         print "foo!";
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .private, lexeme: "private", line: 2),
            Token(type: .class, lexeme: "class", line: 2),
            Token(type: .private, lexeme: "private", line: 2),
            Token(type: .identifier, lexeme: "foo", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"foo!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .rightBrace, lexeme: "}", line: 5),
            Token(type: .eof, lexeme: "", line: 5),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .private, lexeme: "private", line: 2)
        let expectedError = ParseError.duplicateModifier(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseListOfValues() throws {
        // [1, "one", true]
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .string, lexeme: "\"one\"", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .list(
                    Token(type: .leftBracket, lexeme: "[", line: 1),
                    [
                        .literal(
                            Token(type: .int, lexeme: "1", line: 1),
                            .int(1)),
                        .string(Token(type: .string, lexeme: "\"one\"", line: 1)),
                        .literal(
                            Token(type: .true, lexeme: "true", line: 1),
                            .boolean(true))
                    ]))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseOfInvalidListExpression() throws {
        // [1, "one", true
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .string, lexeme: "\"one\"", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .true, lexeme: "true", line: 1)
        let expectedError = ParseError.missingClosingBracket(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseAnEmptyList() throws {
        // [ ]
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .list(
                    Token(type: .leftBracket, lexeme: "[", line: 1),
                    []))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseAnEmptyDictionary() throws {
        // [:]
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .colon, lexeme: ":", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .dictionary(
                    Token(type: .leftBracket, lexeme: "[", line: 1),
                    []))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseADictionaryWithOneKeyValuePair() throws {
        // ["a": 1]
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .string, lexeme: "\"a\"", line: 1),
            Token(type: .colon, lexeme: ":", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .dictionary(
                    Token(type: .leftBracket, lexeme: "[", line: 1),
                    [
                        (.string(Token(type: .string, lexeme: "\"a\"", line: 1)), .literal(Token(type: .int, lexeme: "1", line: 1),.int(1))),
                    ]))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseADictionaryWithMultipleValuePairs() throws {
        // ["a": 1, "b": 2, "c": 3]
        let tokens: [Token] = [
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .string, lexeme: "\"a\"", line: 1),
            Token(type: .colon, lexeme: ":", line: 1),
            Token(type: .int, lexeme: "1", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .string, lexeme: "\"b\"", line: 1),
            Token(type: .colon, lexeme: ":", line: 1),
            Token(type: .int, lexeme: "2", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .string, lexeme: "\"c\"", line: 1),
            Token(type: .colon, lexeme: ":", line: 1),
            Token(type: .int, lexeme: "3", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .eof, lexeme: "", line: 1)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .expression(
                .dictionary(
                    Token(type: .leftBracket, lexeme: "[", line: 1),
                    [
                        (.string(Token(type: .string, lexeme: "\"a\"", line: 1)), .literal(Token(type: .int, lexeme: "1", line: 1),.int(1))),
                        (.string(Token(type: .string, lexeme: "\"b\"", line: 1)), .literal(Token(type: .int, lexeme: "2", line: 1),.int(2))),
                        (.string(Token(type: .string, lexeme: "\"c\"", line: 1)), .literal(Token(type: .int, lexeme: "3", line: 1),.int(3))),
                    ]))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseEnumDeclarationWithMethods() throws {
        // enum Foo {
        //     case foo, bar, baz;
        //     isBar() {
        //         if (this == Foo.bar) {
        //             return true;
        //         }
        //         return false;
        //     }
        // }
        let tokens: [Token] = [
            Token(type: .enum, lexeme: "enum", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .case, lexeme: "case", line: 2),
            Token(type: .identifier, lexeme: "foo", line: 2),
            Token(type: .comma, lexeme: ",", line: 2),
            Token(type: .identifier, lexeme: "bar", line: 2),
            Token(type: .comma, lexeme: ",", line: 2),
            Token(type: .identifier, lexeme: "baz", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .identifier, lexeme: "isBar", line: 3),
            Token(type: .leftParen, lexeme: "(", line: 3),
            Token(type: .rightParen, lexeme: ")", line: 3),
            Token(type: .leftBrace, lexeme: "{", line: 3),

            Token(type: .if, lexeme: "if", line: 4),
            Token(type: .leftParen, lexeme: "(", line: 4),
            Token(type: .this, lexeme: "this", line: 4),
            Token(type: .equalEqual, lexeme: "==", line: 4),
            Token(type: .identifier, lexeme: "Foo", line: 4),
            Token(type: .dot, lexeme: ".", line: 4),
            Token(type: .identifier, lexeme: "bar", line: 4),
            Token(type: .rightParen, lexeme: ")", line: 4),
            Token(type: .leftBrace, lexeme: "{", line: 4),

            Token(type: .return, lexeme: "return", line: 5),
            Token(type: .true, lexeme: "true", line: 5),
            Token(type: .semicolon, lexeme: ";", line: 5),

            Token(type: .rightBrace, lexeme: "}", line: 6),

            Token(type: .return, lexeme: "return", line: 7),
            Token(type: .false, lexeme: "false", line: 7),
            Token(type: .semicolon, lexeme: ";", line: 7),

            Token(type: .rightBrace, lexeme: "}", line: 8),

            Token(type: .rightBrace, lexeme: "}", line: 9),
            Token(type: .eof, lexeme: "", line: 9)
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .enum(
                Token(type: .identifier, lexeme: "Foo", line: 1),
                [
                    Token(type: .identifier, lexeme: "foo", line: 2),
                    Token(type: .identifier, lexeme: "bar", line: 2),
                    Token(type: .identifier, lexeme: "baz", line: 2),
                ],
                [
                    .function(
                        Token(type: .identifier, lexeme: "isBar", line: 3),
                        [],
                        .lambda(
                            Token(type: .identifier, lexeme: "isBar", line: 3),
                            ParameterList(
                                normalParameters: [],
                                variadicParameter: nil),
                            .block(
                                Token(type: .leftBrace, lexeme: "{", line: 3),
                                [
                                    .if(
                                        Token(type: .if, lexeme: "if", line: 4),
                                        .binary(
                                            .this(
                                                Token(type: .this, lexeme: "this", line: 4),
                                                UnresolvedDepth()),
                                            Token(type: .equalEqual, lexeme: "==", line: 4),
                                            .get(
                                                Token(type: .dot, lexeme: ".", line: 4),
                                                .variable(
                                                    Token(type: .identifier, lexeme: "Foo", line: 4),
                                                    UnresolvedDepth()),
                                                Token(type: .identifier, lexeme: "bar", line: 4))),
                                        .block(
                                            Token(type: .leftBrace, lexeme: "{", line: 4),
                                            [
                                                .return(
                                                    Token(type: .return, lexeme: "return", line: 5),
                                                    .literal(
                                                        Token(type: .true, lexeme: "true", line: 5),
                                                        .boolean(true))),
                                            ]),
                                        nil),
                                    .return(
                                        Token(type: .return, lexeme: "return", line: 7),
                                        .literal(
                                            Token(type: .false, lexeme: "false", line: 7),
                                            .boolean(false)))
                                ])))
                ]),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseSwitchStatement() throws {
        // switch (foo) {
        // case 1:
        //     print "one";
        // case 2, 3, 4:
        //     print "two";
        //     print "three";
        //     print "or four";
        // default:
        //     print "unhandled";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .case, lexeme: "case", line: 2),
            Token(type: .int, lexeme: "1", line: 2),
            Token(type: .colon, lexeme: ":", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"one\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .case, lexeme: "case", line: 4),
            Token(type: .int, lexeme: "2", line: 4),
            Token(type: .comma, lexeme: ",", line: 4),
            Token(type: .int, lexeme: "3", line: 4),
            Token(type: .comma, lexeme: ",", line: 4),
            Token(type: .int, lexeme: "4", line: 4),
            Token(type: .colon, lexeme: ":", line: 4),

            Token(type: .print, lexeme: "print", line: 5),
            Token(type: .string, lexeme: "\"two\"", line: 5),
            Token(type: .semicolon, lexeme: ";", line: 5),

            Token(type: .print, lexeme: "print", line: 6),
            Token(type: .string, lexeme: "\"three\"", line: 6),
            Token(type: .semicolon, lexeme: ";", line: 6),

            Token(type: .print, lexeme: "print", line: 7),
            Token(type: .string, lexeme: "\"or four\"", line: 7),
            Token(type: .semicolon, lexeme: ";", line: 7),

            Token(type: .default, lexeme: "default", line: 8),
            Token(type: .colon, lexeme: ":", line: 8),

            Token(type: .print, lexeme: "print", line: 9),
            Token(type: .string, lexeme: "\"unhandled\"", line: 9),
            Token(type: .semicolon, lexeme: ";", line: 9),

            Token(type: .rightBrace, lexeme: "}", line: 10),
            Token(type: .eof, lexeme: "", line: 10),
        ]

        var parser = Parser(tokens: tokens)
        let actual = try parser.parse()
        let expected: [Statement<UnresolvedDepth>] = [
            .switch(
                Token(type: .switch, lexeme: "switch", line: 1),
                .variable(
                    Token(type: .identifier, lexeme: "foo", line: 1),
                    UnresolvedDepth()),
                [
                    SwitchCaseDeclaration(
                        caseToken: Token(type: .case, lexeme: "case", line: 2),
                        valueExpressions: [
                            .literal(
                                Token(type: .int, lexeme: "1", line: 2),
                                .int(1))
                        ],
                        statement: .block(
                            Token(type: .colon, lexeme: ":", line: 2),
                            [
                                .print(
                                    Token(type: .print, lexeme: "print", line: 3),
                                    .string(Token(type: .string, lexeme: "\"one\"", line: 3)))
                            ])),
                    SwitchCaseDeclaration(
                        caseToken: Token(type: .case, lexeme: "case", line: 4),
                        valueExpressions: [
                            .literal(
                                Token(type: .int, lexeme: "2", line: 4),
                                .int(2)),
                            .literal(
                                Token(type: .int, lexeme: "3", line: 4),
                                .int(3)),
                            .literal(
                                Token(type: .int, lexeme: "4", line: 4),
                                .int(4)),
                        ],
                        statement: .block(
                            Token(type: .colon, lexeme: ":", line: 4),
                            [
                                .print(
                                    Token(type: .print, lexeme: "print", line: 5),
                                    .string(Token(type: .string, lexeme: "\"two\"", line: 5))),
                                .print(
                                    Token(type: .print, lexeme: "print", line: 6),
                                    .string(Token(type: .string, lexeme: "\"three\"", line: 6))),
                                .print(
                                    Token(type: .print, lexeme: "print", line: 7),
                                    .string(Token(type: .string, lexeme: "\"or four\"", line: 7)))
                            ])),
                    SwitchCaseDeclaration(
                        caseToken: Token(type: .default, lexeme: "default", line: 8),
                        statement: .block(
                            Token(type: .colon, lexeme: ":", line: 8),
                            [
                                .print(
                                    Token(type: .print, lexeme: "print", line: 9),
                                    .string(Token(type: .string, lexeme: "\"unhandled\"", line: 9))),
                            ])),
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testParseSwitchStatementMissingOpenParen() throws {
        // switch foo {
        // default:
        //     print "boom!";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .default, lexeme: "default", line: 2),
            Token(type: .colon, lexeme: ":", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"boom!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),
            Token(type: .eof, lexeme: "", line: 4),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .identifier, lexeme: "foo", line: 1)
        let expectedError = ParseError.missingOpenParenForSwitchStatement(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSwitchStatementMissingCloseParen() throws {
        // switch (foo {
        // default:
        //     print "boom!";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .default, lexeme: "default", line: 2),
            Token(type: .colon, lexeme: ":", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"boom!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),
            Token(type: .eof, lexeme: "", line: 4),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .leftBrace, lexeme: "{", line: 1)
        let expectedError = ParseError.missingCloseParenForSwitchStatement(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSwitchStatementMissingOpenBrace() throws {
        // switch (foo)
        // default:
        //     print "boom!";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),

            Token(type: .default, lexeme: "default", line: 2),
            Token(type: .colon, lexeme: ":", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"boom!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),
            Token(type: .eof, lexeme: "", line: 4),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .default, lexeme: "default", line: 2)
        let expectedError = ParseError.missingOpenBraceBeforeSwitchBody(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSwitchStatementMissingColon() throws {
        // switch (foo) {
        // default
        //     print "boom!";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .default, lexeme: "default", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"boom!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),
            Token(type: .eof, lexeme: "", line: 4),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .print, lexeme: "print", line: 3)
        let expectedError = ParseError.missingColon(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSwitchStatementMissingCloseBrace() throws {
        // switch (foo) {
        // default:
        //     print "boom!";
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .default, lexeme: "default", line: 2),
            Token(type: .colon, lexeme: ":", line: 2),

            Token(type: .print, lexeme: "print", line: 3),
            Token(type: .string, lexeme: "\"boom!\"", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),
            Token(type: .eof, lexeme: "", line: 3),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .eof, lexeme: "", line: 3)
        let expectedError = ParseError.missingClosingBrace(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }

    func testParseSwitchStatementWithStatementInsteadOfCase() throws {
        // switch (foo) {
        //     print "boom!";
        // }
        let tokens: [Token] = [
            Token(type: .switch, lexeme: "switch", line: 1),
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .print, lexeme: "print", line: 2),
            Token(type: .string, lexeme: "\"boom!\"", line: 2),
            Token(type: .semicolon, lexeme: ";", line: 2),

            Token(type: .rightBrace, lexeme: "}", line: 3),
            Token(type: .eof, lexeme: "", line: 3),
        ]

        var parser = Parser(tokens: tokens)
        let lastToken = Token(type: .print, lexeme: "print", line: 2)
        let expectedError = ParseError.missingCaseOrDefault(lastToken)
        XCTAssertThrowsError(try parser.parse()) { actualError in
            XCTAssertEqual(actualError as! ParseError, expectedError)
        }
    }
}
