//
//  Scanner.swift
//  slox
//
//  Created by Danielle Kefford on 2/22/24.
//

struct Scanner {
    private var source: String
    private var tokens: [Token] = []

    private var startIndex: String.Index
    private var currentIndex: String.Index
    private var nextIndex: String.Index {
        return source.index(after: currentIndex)
    }
    private var line = 1

    let keywords: [String: TokenType] = [
        "and": .and,
        "class": .class,
        "else": .else,
        "false": .false,
        "for": .for,
        "fun": .fun,
        "if": .if,
        "nil": .nil,
        "or": .or,
        "print": .print,
        "return": .return,
        "super": .super,
        "this": .this,
        "true": .true,
        "var": .var,
        "while": .while,
    ]

    init(source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self.currentIndex = self.startIndex
    }

    mutating func scanTokens() throws -> [Token] {
        while currentIndex < source.endIndex {
            startIndex = currentIndex
            try scanToken()
        }

        let newToken = Token(type: .eof, lexeme: "", line: line)
        tokens.append(newToken)

        return tokens
    }

    mutating private func scanToken() throws {
        switch source[currentIndex] {
        // One character lexemes
        case "(":
            handleSingleCharacterLexeme(type: .leftParen)
        case ")":
            handleSingleCharacterLexeme(type: .rightParen)
        case "{":
            handleSingleCharacterLexeme(type: .leftBrace)
        case "}":
            handleSingleCharacterLexeme(type: .rightBrace)
        case "[":
            handleSingleCharacterLexeme(type: .leftBracket)
        case "]":
            handleSingleCharacterLexeme(type: .rightBracket)
        case ",":
            handleSingleCharacterLexeme(type: .comma)
        case ".":
            handleSingleCharacterLexeme(type: .dot)
        case "-":
            handleSingleCharacterLexeme(type: .minus)
        case "+":
            handleSingleCharacterLexeme(type: .plus)
        case ";":
            handleSingleCharacterLexeme(type: .semicolon)
        case "*":
            handleSingleCharacterLexeme(type: .star)
        case "/":
            handleSlash()

        // Lexemes that can be one or two characters
        case "!":
            handleOneOrTwoCharacterLexeme(oneCharLexeme: .bang, twoCharLexeme: .bangEqual)
        case "=":
            handleOneOrTwoCharacterLexeme(oneCharLexeme: .equal, twoCharLexeme: .equalEqual)
        case "<":
            handleOneOrTwoCharacterLexeme(oneCharLexeme: .less, twoCharLexeme: .lessEqual)
        case ">":
            handleOneOrTwoCharacterLexeme(oneCharLexeme: .greater, twoCharLexeme: .greaterEqual)

        // Whitespace
        case " ", "\r", "\t":
            break
        case "\n":
            line += 1

        case "\"":
            try handleString()

        case "0"..."9":
            handleNumber()

        case "a"..."z", "A"..."Z":
            handleIdentifier()

        default:
            throw ScanError.unexpectedCharacter(line)
        }

        advanceCursor()
    }

    mutating private func handleSingleCharacterLexeme(type: TokenType) {
        addToken(type: type)
    }

    mutating private func handleSlash() {
        if nextIndex < source.endIndex,
           source[nextIndex] == "/" {
            while nextIndex < source.endIndex,
                  source[nextIndex] != "\n" {
                advanceCursor()
            }
        } else {
            addToken(type: .slash)
        }
    }

    mutating private func handleOneOrTwoCharacterLexeme(oneCharLexeme: TokenType, twoCharLexeme: TokenType) {
        if nextIndex < source.endIndex, source[nextIndex] == "=" {
            advanceCursor()
            addToken(type: twoCharLexeme)
        } else {
            addToken(type: oneCharLexeme)
        }
    }

    mutating private func handleString() throws {
        advanceCursor()
        while currentIndex < source.endIndex,
              source[currentIndex] != "\"" {
            advanceCursor()
        }

        if currentIndex == source.endIndex {
            throw ScanError.unterminatedString(line)
        }

        addToken(type: .string)
    }

    mutating private func handleNumber() {
        while nextIndex < source.endIndex,
              source[nextIndex].isNumber {
            advanceCursor()
        }

        if nextIndex < source.endIndex,
           source[nextIndex] == "." {
            advanceCursor()

            while nextIndex < source.endIndex,
                  source[nextIndex].isNumber {
                advanceCursor()
            }
        }

        addToken(type: .number)
    }

    mutating private func handleIdentifier() {
        while nextIndex < source.endIndex &&
                (source[nextIndex].isLetter ||
                 source[nextIndex].isNumber ||
                 source[nextIndex] == "_") {
            advanceCursor()
        }

        if let type = keywords[String(source[startIndex...currentIndex])] {
            addToken(type: type)
        } else {
            addToken(type: .identifier)
        }
    }

    mutating private func advanceCursor() {
        currentIndex = source.index(after: currentIndex)
    }

    mutating private func addToken(type: TokenType) {
        let text = String(source[startIndex...currentIndex])
        let newToken = Token(type: type, lexeme: text, line: line)
        tokens.append(newToken)
    }
}
