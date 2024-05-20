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
            try interpreter.interpretFile(fileName: fileName)
        } catch {
            print(error)
            exit(65)
        }
    }

    private static func runRepl() {
        print("slox>", terminator: " ")
        while let input = readLine() {
            do {
                if let result = try interpreter.interpretRepl(source: input) {
                    print(String(reflecting: result))
                }
            } catch {
                print(error)
            }

            print("> ", terminator: "")
        }
    }
}
