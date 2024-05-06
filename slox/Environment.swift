//
//  Environment.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

class Environment: Equatable {
    var enclosingEnvironment: Environment?
    private var values: [String: LoxValue] = [:]

    init(enclosingEnvironment: Environment? = nil) {
        self.enclosingEnvironment = enclosingEnvironment
    }

    func define(name: String, value: LoxValue) {
        values[name] = value
    }

    func assignAtDepth(nameToken: Token, value: LoxValue, depth: Int) throws {
        let ancestor = try ancestor(depth: depth)

        if ancestor.values.keys.contains(nameToken.lexeme) {
            ancestor.values[nameToken.lexeme] = value
            return
        }

        throw RuntimeError.undefinedVariable(nameToken)
    }

    func getValueAtDepth(nameToken: Token, depth: Int) throws -> LoxValue {
        let ancestor = try ancestor(depth: depth)

        if let value = ancestor.values[nameToken.lexeme] {
            return value
        }

        throw RuntimeError.undefinedVariable(nameToken)
    }

    func getValue(nameToken: Token) throws -> LoxValue {
        if let value = values[nameToken.lexeme] {
            return value
        }

        if let enclosingEnvironment {
            return try enclosingEnvironment.getValue(nameToken: nameToken)
        }

        throw RuntimeError.undefinedVariable(nameToken)
    }

    private func ancestor(depth: Int) throws -> Environment {
        var i = 0
        var ancestor: Environment = self
        while i < depth {
            guard let parent = ancestor.enclosingEnvironment else {
                // NOTA BENE: This should not happen but it _is_ possible
                fatalError("Fatal error: could not find ancestor environment at depth \(depth).")
            }

            ancestor = parent
            i = i + 1
        }

        return ancestor
    }

    static func == (lhs: Environment, rhs: Environment) -> Bool {
        return lhs === rhs
    }
}
