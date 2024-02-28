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

    private static func runRepl() {
        print("slox>", terminator: " ")
        while let input = readLine() {
            do {
                var scanner = Scanner(source: input)
                let tokens = try scanner.scanTokens()
                var parser = Parser(tokens: tokens)
                let statements = try parser.parse()
                if let result = try interpreter.interpretRepl(statements: statements) {
                    print(result)
                }
            } catch {
                print(error)
            }

            print("> ", terminator: "")
        }
    }

    private static func run(input: String) throws {
        var scanner = Scanner(source: input)
        let tokens = try scanner.scanTokens()
        var parser = Parser(tokens: tokens)
        let statements = try parser.parse()
        try interpreter.interpret(statements: statements)
    }
}
