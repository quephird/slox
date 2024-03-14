//
//  Lox.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

@main
struct Lox {
    static var interpreter = Interpreter()

    static func main() {
        let args = CommandLine.arguments.dropFirst()

        if args.count > 1 {
            usage()
            exit(64)
        } else if let fileName = args.first {
            runFile(fileName: fileName)
        } else {
            runRepl()
        }
    }

    private static func usage() {
        print("Usage: slox [script]")
    }

    private static func runFile(fileName: String) {
        do {
            let input = try String(contentsOfFile: fileName)
            try run(input: input)
        } catch {
            print(error)
            exit(65)
        }
    }

    // TODO: Need to move pipeline of instantiation and invocations to centralized function
    private static func runRepl() {
        print("slox>", terminator: " ")
        while let input = readLine() {
            do {
                var scanner = Scanner(source: input)
                let tokens = try scanner.scanTokens()
                var parser = Parser(tokens: tokens)
                let statements = try parser.parse()
                var resolver = Resolver()
                let resolvedStatements = try resolver.resolve(statements: statements)
                if let result = try interpreter.interpretRepl(statements: resolvedStatements) {
                    print(result)
                }
            } catch {
                print(error)
            }

            print("> ", terminator: "")
        }
    }

    // TODO: Need to move pipeline of instantiations and invocations to centralized function
    private static func run(input: String) throws {
        var scanner = Scanner(source: input)
        let tokens = try scanner.scanTokens()
        var parser = Parser(tokens: tokens)
        let statements = try parser.parse()
        var resolver = Resolver()
        let resolvedStatements = try resolver.resolve(statements: statements)
        try interpreter.interpret(statements: resolvedStatements)
    }
}
