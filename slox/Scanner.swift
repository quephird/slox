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
        "break": .break,
        "continue": .continue,
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

    private var scannedToken: String {
        String(source[startIndex..<currentIndex])
    }

    mutating private func tryScan(where predicate: (Character) -> Bool) -> Bool {
        guard currentIndex < source.endIndex && predicate(source[currentIndex]) else {
            return false
        }

        currentIndex = source.index(after: currentIndex)
        return true
    }

    mutating private func tryScan(_ charRanges: ClosedRange<Character>...) -> Bool {
        tryScan(where: { char in
            charRanges.contains(where: { charRange in
                charRange.contains(char)
            })
        })
    }

    mutating private func tryNotScan(_ char: Character) -> Bool {
        tryScan(where: { actualChar in
            actualChar != char
        })
    }

    mutating private func tryScan(_ chars: Character...) -> Bool {
        tryScan(where: chars.contains(_:))
    }

    private func repeatedly(_ tryScanFn: () -> Bool) {
        var scanned: Bool
        repeat {
            scanned = tryScanFn()
        } while scanned
    }

    mutating private func scanToken() throws {
        for (lexeme, type) in [
            ("(", .leftParen),
            (")", .rightParen),
            ("{", .leftBrace),
            ("}", .rightBrace),
            ("[", .leftBracket),
            ("]", .rightBracket),
            (",", .comma),
            (".", .dot),
            (";", .semicolon),
            ("%", .modulus),
            (":", .colon),
        ] as [(Character, TokenType)] {
            if tryScan(lexeme) {
                handleSingleCharacterLexeme(type: type)
                return
            }
        }

        for (lexeme, oneCharType, twoCharType) in [
            ("!", .bang, .bangEqual),
            ("=", .equal, .equalEqual),
            ("<", .less, .lessEqual),
            (">", .greater, .greaterEqual),
            ("-", .minus, .minusEqual),
            ("+", .plus, .plusEqual),
            ("*", .star, .starEqual),
        ] as [(Character, TokenType, TokenType)] {
            if tryScan(lexeme) {
                handleOneOrTwoCharacterLexeme(oneCharType: oneCharType, twoCharType: twoCharType)
                return
            }
        }

        if tryScan("/") {
            handleSlash()
        }

        else if tryScan(" ", "\r", "\t") {
            // do nothing
        }
        else if tryScan("\n") {
            line += 1
        }

        else if tryScan("\"") {
            try handleString()
        }

        else if tryScan("0"..."9") {
            handleNumber()
        }

        else if tryScan("a"..."z", "A"..."Z") {
            handleIdentifier()
        }
        else {
            throw ScanError.unexpectedCharacter(line)
        }
    }

    mutating private func handleSingleCharacterLexeme(type: TokenType) {
        addToken(type: type)
    }

    mutating private func handleSlash() {
        if tryScan("/") {
            repeatedly { tryNotScan("\n") }
        } else {
            handleOneOrTwoCharacterLexeme(oneCharType: .slash, twoCharType: .slashEqual)
        }
    }

    mutating private func handleOneOrTwoCharacterLexeme(oneCharType: TokenType, twoCharType: TokenType) {
        if tryScan("=") {
            addToken(type: twoCharType)
        } else {
            addToken(type: oneCharType)
        }
    }

    mutating private func handleString() throws {
        repeatedly { tryNotScan("\"") }

        guard tryScan("\"") else {
            throw ScanError.unterminatedString(line)
        }

        addToken(type: .string)
    }

    mutating private func handleNumber() {
        repeatedly { tryScan(where: \.isNumber) }

        var tokenType: TokenType = .int
        if tryScan(".") {
            tokenType = .double

            repeatedly { tryScan(where: \.isNumber) }
        }

        addToken(type: tokenType)
    }

    mutating private func handleIdentifier() {
        repeatedly { tryScan(where: { $0.isLetter || $0.isNumber || $0 == "_" }) }

        if let type = keywords[scannedToken] {
            addToken(type: type)
        } else {
            addToken(type: .identifier)
        }
    }

    mutating private func addToken(type: TokenType) {
        let text = scannedToken
        let newToken = Token(type: type, lexeme: text, line: line)
        tokens.append(newToken)
    }
}
