//
//  sloxTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 2/23/24.
//

import XCTest

final class ScannerTests: XCTestCase {
    func testScanningOfOneCharacterLexemes() throws {
        let source = "( ) { } [ ] , . ; %"
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .leftParen, lexeme: "(", line: 1),
            Token(type: .rightParen, lexeme: ")", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),
            Token(type: .rightBrace, lexeme: "}", line: 1),
            Token(type: .leftBracket, lexeme: "[", line: 1),
            Token(type: .rightBracket, lexeme: "]", line: 1),
            Token(type: .comma, lexeme: ",", line: 1),
            Token(type: .dot, lexeme: ".", line: 1),
            Token(type: .semicolon, lexeme: ";", line: 1),
            Token(type: .modulus, lexeme: "%", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfOneOrTwoCharacterLexemes() throws {
        let source = "! != = == < <= > >= + += - -= * *="
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .bang, lexeme: "!", line: 1),
            Token(type: .bangEqual, lexeme: "!=", line: 1),
            Token(type: .equal, lexeme: "=", line: 1),
            Token(type: .equalEqual, lexeme: "==", line: 1),
            Token(type: .less, lexeme: "<", line: 1),
            Token(type: .lessEqual, lexeme: "<=", line: 1),
            Token(type: .greater, lexeme: ">", line: 1),
            Token(type: .greaterEqual, lexeme: ">=", line: 1),
            Token(type: .plus, lexeme: "+", line: 1),
            Token(type: .plusEqual, lexeme: "+=", line: 1),
            Token(type: .minus, lexeme: "-", line: 1),
            Token(type: .minusEqual, lexeme: "-=", line: 1),
            Token(type: .star, lexeme: "*", line: 1),
            Token(type: .starEqual, lexeme: "*=", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfSlashAndComment() throws {
        let source = "/ /= // This should not be lexed"
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .slash, lexeme: "/", line: 1),
            Token(type: .slashEqual, lexeme: "/=", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfStrings() throws {
        let source = "\"foo\" \"bar\""
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .string, lexeme: "\"foo\"", line: 1),
            Token(type: .string, lexeme: "\"bar\"", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfUnterminatedString() throws {
        let source = "\"foo"
        var scanner = Scanner(source: source)
        let expectedError = ScanError.unterminatedString(1)
        XCTAssertThrowsError(try scanner.scanTokens()) { actualError in
            XCTAssertEqual(actualError as! ScanError, expectedError)
        }
    }

    func testScanningOfNumbers() throws {
        let source = "123 456.789"
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .int, lexeme: "123", line: 1),
            Token(type: .double, lexeme: "456.789", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfEmojiNumbersResultsInError() throws {
        let source = "1️⃣"
        var scanner = Scanner(source: source)
        let expectedError = ScanError.unexpectedCharacter(1)
        XCTAssertThrowsError(try scanner.scanTokens()) { actualError in
            XCTAssertEqual(actualError as! ScanError, expectedError)
        }
    }

    func testScanningOfKeywords() throws {
        let source = "and class else false for fun if nil or print return super this true var while break continue"
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .and, lexeme: "and", line: 1),
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .else, lexeme: "else", line: 1),
            Token(type: .false, lexeme: "false", line: 1),
            Token(type: .for, lexeme: "for", line: 1),
            Token(type: .fun, lexeme: "fun", line: 1),
            Token(type: .if, lexeme: "if", line: 1),
            Token(type: .nil, lexeme: "nil", line: 1),
            Token(type: .or, lexeme: "or", line: 1),
            Token(type: .print, lexeme: "print", line: 1),
            Token(type: .return, lexeme: "return", line: 1),
            Token(type: .super, lexeme: "super", line: 1),
            Token(type: .this, lexeme: "this", line: 1),
            Token(type: .true, lexeme: "true", line: 1),
            Token(type: .var, lexeme: "var", line: 1),
            Token(type: .while, lexeme: "while", line: 1),
            Token(type: .break, lexeme: "break", line: 1),
            Token(type: .continue, lexeme: "continue", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfIdentifiers() throws {
        let source = "foo bar baz"
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .identifier, lexeme: "foo", line: 1),
            Token(type: .identifier, lexeme: "bar", line: 1),
            Token(type: .identifier, lexeme: "baz", line: 1),
            Token(type: .eof, lexeme: "", line: 1),
        ]

        XCTAssertEqual(actual, expected)
    }

    func testScanningOfMultilineBlockWithMixtureOfTokenTypes() throws {
        let source = """
class Foo < Bar {
    init(baz) {
        this.baz = baz;
    }

    quux(xyzzy) {
        print xyzzy + "corge";
    }
}
"""
        var scanner = Scanner(source: source)
        let actual = try! scanner.scanTokens()
        let expected: [Token] = [
            Token(type: .class, lexeme: "class", line: 1),
            Token(type: .identifier, lexeme: "Foo", line: 1),
            Token(type: .less, lexeme: "<", line: 1),
            Token(type: .identifier, lexeme: "Bar", line: 1),
            Token(type: .leftBrace, lexeme: "{", line: 1),

            Token(type: .identifier, lexeme: "init", line: 2),
            Token(type: .leftParen, lexeme: "(", line: 2),
            Token(type: .identifier, lexeme: "baz", line: 2),
            Token(type: .rightParen, lexeme: ")", line: 2),
            Token(type: .leftBrace, lexeme: "{", line: 2),

            Token(type: .this, lexeme: "this", line: 3),
            Token(type: .dot, lexeme: ".", line: 3),
            Token(type: .identifier, lexeme: "baz", line: 3),
            Token(type: .equal, lexeme: "=", line: 3),
            Token(type: .identifier, lexeme: "baz", line: 3),
            Token(type: .semicolon, lexeme: ";", line: 3),

            Token(type: .rightBrace, lexeme: "}", line: 4),

            Token(type: .identifier, lexeme: "quux", line: 6),
            Token(type: .leftParen, lexeme: "(", line: 6),
            Token(type: .identifier, lexeme: "xyzzy", line: 6),
            Token(type: .rightParen, lexeme: ")", line: 6),
            Token(type: .leftBrace, lexeme: "{", line: 6),

            Token(type: .print, lexeme: "print", line: 7),
            Token(type: .identifier, lexeme: "xyzzy", line: 7),
            Token(type: .plus, lexeme: "+", line: 7),
            Token(type: .string, lexeme: "\"corge\"", line: 7),
            Token(type: .semicolon, lexeme: ";", line: 7),

            Token(type: .rightBrace, lexeme: "}", line: 8),

            Token(type: .rightBrace, lexeme: "}", line: 9),
            Token(type: .eof, lexeme: "", line: 9),
        ]

        XCTAssertEqual(actual, expected)
    }
}
