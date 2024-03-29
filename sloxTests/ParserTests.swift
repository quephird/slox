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
        let expected: [Statement] = [
            .expression(.literal(.string("forty-two")))
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
        let expected: [Statement] = [
            .expression(.literal(.double(123.456)))
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
        let expected: [Statement] = [
            .expression(.literal(.boolean(true)))
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
        let expected: [Statement] = [
            .expression(.literal(.nil))
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
        let expected: [Statement] = [
            .expression(.grouping(.literal(.int(42))))
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
        let expected: [Statement] = [
            .expression(
                .unary(
                    Token(type: .bang, lexeme: "!", line: 1),
                    .literal(.boolean(true))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .literal(.int(21)),
                    Token(type: .star, lexeme: "*", line: 1),
                    .literal(.int(2))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .literal(.int(5)),
                    Token(type: .modulus, lexeme: "%", line: 1),
                    .literal(.int(3))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .literal(.string("forty-")),
                    Token(type: .plus, lexeme: "+", line: 1),
                    .literal(.string("two"))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .literal(.int(1)),
                    Token(type: .lessEqual, lexeme: "<=", line: 1),
                    .literal(.int(2))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .literal(.string("forty-two")),
                    Token(type: .equalEqual, lexeme: "==", line: 1),
                    .literal(.nil)))
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
        let expected: [Statement] = [
            .expression(
                .logical(.literal(.boolean(true)),
                         Token(type: .or, lexeme: "or", line: 1),
                         .literal(.boolean(false))))
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
        let expected: [Statement] = [
            .expression(
                .logical(.literal(.boolean(true)),
                         Token(type: .and, lexeme: "and", line: 1),
                         .literal(.boolean(false))))
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
        let expected: [Statement] = [
            .expression(
                .logical(.logical(.literal(.boolean(true)),
                                  Token(type: .and, lexeme: "and", line: 1),
                                  .literal(.boolean(false))),
                         Token(type: .or, lexeme: "or", line: 1),
                         .literal(.boolean(true))))
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
        let expected: [Statement] = [
            .expression(
                .assignment(
                    Token(type: .identifier, lexeme: "theAnswer", line: 1),
                    .literal(.int(42))))
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
        let expected: [Statement] = [
            .expression(
                .binary(
                    .grouping(.unary(
                        Token(type: .minus, lexeme: "-", line: 1),
                        .literal(.int(2)))),
                    Token(type: .star, lexeme: "*", line: 1),
                    .grouping(.binary(
                        .literal(.int(3)),
                        Token(type: .plus, lexeme: "+", line: 1),
                        .literal(.int(4))))))
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
        let expected: [Statement] = [
            .for(
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "i", line: 1),
                    .literal(.int(0))),
                .binary(
                    .variable(Token(type: .identifier, lexeme: "i", line: 1)),
                    Token(type: .less, lexeme: "<", line: 1),
                    .literal(.int(5))),
                .assignment(
                    Token(type: .identifier, lexeme: "i", line: 1),
                    .binary(
                        .variable(Token(type: .identifier, lexeme: "i", line: 1)),
                        Token(type: .plus, lexeme: "+", line: 1),
                        .literal(.int(1)))),
                .print(
                    .variable(Token(type: .identifier, lexeme: "i", line: 2)))),
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
        let expected: [Statement] = [
            .for(
                nil,
                .literal(.boolean(true)),
                nil,
                .print(
                    .variable(Token(type: .identifier, lexeme: "i", line: 2))))
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
        let expected: [Statement] = [
            .if(
                .literal(.boolean(true)),
                .print(.literal(.string("Hello!"))),
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
        let expected: [Statement] = [
            .if(
                .literal(.boolean(true)),
                .print(.literal(.string("Hello!"))),
                .print(.literal(.string("Goodbye"))))
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
        let expected: [Statement] = [
            .print(
                .literal(.string("forty-two")))
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
        let expected: [Statement] = [
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
        let expected: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .literal(.int(42)))
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
        let expected: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "the", line: 1),
                .literal(.int(2))),
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 2),
                .literal(.int(21))),
            .print(
                .binary(
                    .variable(Token(type: .identifier, lexeme: "the", line: 3)),
                    Token(type: .star, lexeme: "*", line: 3),
                    .variable(Token(type: .identifier, lexeme: "answer", line: 3)))),
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
        let expected: [Statement] = [
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "theAnswer", line: 2),
                    .literal(.int(42))),
                .print(
                    .variable(Token(type: .identifier, lexeme: "theAnswer", line: 3))),
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
        let expected: [Statement] = [
            .while(
                .binary(
                    .variable(Token(type: .identifier, lexeme: "x", line: 1)),
                    Token(type: .lessEqual, lexeme: "<=", line: 1),
                    .literal(.int(5))),
                .block([
                    .print(.variable(Token(type: .identifier, lexeme: "x", line: 2))),
                    .expression(
                        .assignment(
                            Token(type: .identifier, lexeme: "x", line: 3),
                            .binary(
                                .variable(Token(type: .identifier, lexeme: "x", line: 3)),
                                Token(type: .plus, lexeme: "+", line: 3),
                                .literal(.int(1))))),
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
        let expected: [Statement] = [
            .function(
                Token(type: .identifier, lexeme: "theAnswer", line: 1),
                .lambda(
                    [],
                    [
                        .print(.literal(.int(42)))
                    ])),
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
        let expected: [Statement] = [
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
            )
        ]
        XCTAssertEqual(actual, expected)
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
        let expected: [Statement] = [
            .expression(
                .call(
                    .variable(Token(type: .identifier, lexeme: "add", line: 1)),
                    Token(type: .rightParen, lexeme: ")", line: 1),
                    [
                        .literal(.int(1)),
                        .literal(.int(2)),
                    ]))
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
        let expected: [Statement] = [
            .expression(
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
                                .variable(Token(type: .identifier, lexeme: "b", line: 1)))),
                    ]))
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
        let expected: [Statement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        .lambda(
                            [],
                            [
                                .print(
                                    .get(
                                        .this(Token(type: .this, lexeme: "this", line: 3)),
                                        Token(type: .identifier, lexeme: "name", line: 3)))
                            ]))
                ],
                [])
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
        let expected: [Statement] = [
            .expression(
                .get(
                    .variable(Token(type: .identifier, lexeme: "person", line: 1)),
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
        let expected: [Statement] = [
            .expression(
                .set(
                    .variable(Token(type: .identifier, lexeme: "person", line: 1)),
                    Token(type: .identifier, lexeme: "name", line: 1),
                    .literal(.string("Danielle")))),
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
        let expected: [Statement] = [
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
                                        .variable(Token(type: .identifier, lexeme: "a", line: 3)),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .variable(Token(type: .identifier, lexeme: "b", line: 3))))
                            ]))
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
        let expected: [Statement] = [
            .class(
                Token(type: .identifier, lexeme: "B", line: 1),
                .variable(Token(type: .identifier, lexeme: "A", line: 1)),
                [
                    .function(
                        Token(type: .identifier, lexeme: "someMethod", line: 2),
                        .lambda(
                            [
                                Token(type: .identifier, lexeme: "arg", line: 2)
                            ],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .call(
                                        .super(
                                            Token(type: .super, lexeme: "super", line: 3),
                                            Token(type: .identifier, lexeme: "someMethod", line: 3)),
                                        Token(type: .rightParen, lexeme: ")", line: 3),
                                        [
                                            .variable(Token(type: .identifier, lexeme: "arg", line: 3))
                                        ]))
                            ]))
                ],
                []),
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
        let expected: [Statement] = [
            .class(
                Token(type: .identifier, lexeme: "Circle", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "area", line: 2),
                        .lambda(
                            nil,
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .binary(
                                            .literal(.double(3.14159)),
                                            Token(type: .star, lexeme: "*", line: 3),
                                            .get(
                                                .this(Token(type: .this, lexeme: "this", line: 3)),
                                                Token(type: .identifier, lexeme: "radius", line: 3))),
                                        Token(type: .star, lexeme: "*", line: 3),
                                        .get(
                                            .this(Token(type: .this, lexeme: "this", line: 3)),
                                            Token(type: .identifier, lexeme: "radius", line: 3)))),
                            ]))
                ],
                [])
        ]
        XCTAssertEqual(actual, expected)
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
        let expected: [Statement] = [
            .expression(
                .list([
                    .literal(.int(1)),
                    .literal(.string("one")),
                    .literal(.boolean(true))
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
        let expected: [Statement] = [
            .expression(
                .list([
                ]))
        ]
        XCTAssertEqual(actual, expected)
    }
}
