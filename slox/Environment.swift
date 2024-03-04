//
//  Environment.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

class Environment: Equatable {
    private var enclosingEnvironment: Environment?
    private var values: [String: LoxValue] = [:]

    init(enclosingEnvironment: Environment? = nil) {
        self.enclosingEnvironment = enclosingEnvironment
    }

    func define(name: String, value: LoxValue) {
        values[name] = value
    }

    func assignAtDepth(name: String, value: LoxValue, depth: Int) throws {
        let ancestor = try ancestor(depth: depth)

        if ancestor.values.keys.contains(name) {
            ancestor.values[name] = value
            return
        }

        throw RuntimeError.undefinedVariable(name)
    }

    func getValueAtDepth(name: String, depth: Int) throws -> LoxValue {
        let ancestor = try ancestor(depth: depth)

        if let value = ancestor.values[name] {
            return value
        }

        throw RuntimeError.undefinedVariable(name)
    }

    private func ancestor(depth: Int) throws -> Environment {
        var i = 0
        var ancestor: Environment = self
        while i < depth {
            guard let parent = ancestor.enclosingEnvironment else {
                // NOTA BENE: This should not happen but it _is_ possible
                throw RuntimeError.couldNotFindAncestorEnvironmentAtDepth(depth)
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
