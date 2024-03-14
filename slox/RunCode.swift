//
//  RunCode.swift
//  slox
//
//  Created by Danielle Kefford on 3/14/24.
//

func prepareCode(source: String) throws -> [ResolvedStatement] {
    var scanner = Scanner(source: source)
    let tokens = try scanner.scanTokens()
    var parser = Parser(tokens: tokens)
    let statements = try parser.parse()
    var resolver = Resolver()

    return try resolver.resolve(statements: statements)
}
