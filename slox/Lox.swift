//
//  Lox.swift
//  slox
//
//  Created by Danielle Kefford on 2/26/24.
//

import Foundation

@main
struct Lox {
    static let interpreter = Interpreter()

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
                try run(input: input)
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
        let firstExpr = try parser.parse()
        let value = try interpreter.interpret(expr: firstExpr)
        print(value)
    }
}
