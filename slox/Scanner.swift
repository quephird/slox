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
        "enum": .enum,
        "case": .case,
        "switch": .switch,
        "default": .default,
        "private": .private,
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

    mutating private func tryNotScan(_ char: Character) -> Bool {
        tryScan(where: { actualChar in
            actualChar != char
        })
    }

    mutating private func tryNotScan(string: String) throws -> Bool {
        precondition(!string.dropFirst().contains("\n"), "newlines in `string` would mess with line counting")
        let oldIndex = currentIndex

        for char in string {
            guard currentIndex < self.source.endIndex else {
                throw ScanError.unterminatedComment(self.line)
            }

            if self.source[self.currentIndex] == "\n" {
                self.line += 1
            }

            if !tryScan(char) {
                self.currentIndex = self.source.index(after: oldIndex)
                return true
            }
        }

        return false
    }

    mutating private func tryScan(_ chars: Character...) -> Bool {
        tryScan(where: chars.contains(_:))
    }

    mutating private func tryScan<Value>(_ charTable: KeyValuePairs<Character, Value>) -> Value? {
        for (char, value) in charTable {
            if tryScan(char) {
                return value
            }
        }
        return nil
    }

    private func repeatedly(_ tryScanFn: () throws -> Bool) throws {
        var scanned: Bool
        repeat {
            do {
                scanned = try tryScanFn()
            } catch {
                throw error
            }
        } while scanned
    }

    mutating private func scanToken() throws {
        if let type = tryScan([
            "(": TokenType.leftParen,
            ")": .rightParen,
            "{": .leftBrace,
            "}": .rightBrace,
            "[": .leftBracket,
            "]": .rightBracket,
            ",": .comma,
            ".": .dot,
            ";": .semicolon,
            "%": .modulus,
            ":": .colon,
        ]) {
            return handleSingleCharacterLexeme(type: type)
        }

        if let (oneCharType, twoCharType) = tryScan([
            "!": (TokenType.bang, TokenType.bangEqual),
            "=": (.equal, .equalEqual),
            "<": (.less, .lessEqual),
            ">": (.greater, .greaterEqual),
            "-": (.minus, .minusEqual),
            "+": (.plus, .plusEqual),
            "*": (.star, .starEqual),
        ]) {
            return handleOneOrTwoCharacterLexeme(oneCharType: oneCharType, twoCharType: twoCharType)
        }

        if tryScan("/") {
            return try handleSlash()
        }

        if tryScan(" ", "\r", "\t") {
            return
        }
        if tryScan("\n") {
            line += 1
            return
        }

        if tryScan("\"") {
            return try handleString()
        }

        if tryScan(where: \.isLoxDigit) {
            return try handleNumber()
        }

        if tryScan(where: { $0.isLetter || $0 == "_" }) {
            return try handleIdentifier()
        }

        throw ScanError.unexpectedCharacter(line)
    }

    mutating private func handleSingleCharacterLexeme(type: TokenType) {
        addToken(type: type)
    }

    mutating private func handleSlash() throws {
        if tryScan("/") {
            try repeatedly {
                tryNotScan("\n")
            }
        } else if tryScan("*") {
            try repeatedly {
                try tryNotScan(string: "*/")
            }
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
        try repeatedly { tryNotScan("\"") }

        guard tryScan("\"") else {
            throw ScanError.unterminatedString(line)
        }

        addToken(type: .string)
    }

    mutating private func handleNumber() throws {
        try repeatedly { tryScan(where: \.isLoxDigit) }

        var tokenType: TokenType = .int
        if tryScan(".") {
            tokenType = .double

            try repeatedly { tryScan(where: \.isLoxDigit) }
        }

        addToken(type: tokenType)
    }

    mutating private func handleIdentifier() throws {
        try repeatedly { tryScan(where: { $0.isLetter || $0.isNumber || $0 == "_" }) }

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

extension Character {
    var isLoxDigit: Bool {
        return self.isASCII && self.isNumber
    }
}
