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

    func assign(name: String, value: LoxValue) throws {
        if values.keys.contains(name) {
            values[name] = value
            return
        }

        if let enclosingEnvironment = enclosingEnvironment {
            try enclosingEnvironment.assign(name: name, value: value)
            return
        }

        throw RuntimeError.undefinedVariable(name)
    }

    func assignAtDepth(name: String, value: LoxValue, depth: Int) throws {
        let ancestor = ancestor(depth: depth)

        if ancestor.values.keys.contains(name) {
            ancestor.values[name] = value
            return
        }

        throw RuntimeError.undefinedVariable(name)
    }

    func getValue(name: String) throws -> LoxValue {
        if let value = values[name] {
            return value
        }

        if let enclosingEnvironment = enclosingEnvironment {
            return try enclosingEnvironment.getValue(name: name)
        }

        throw RuntimeError.undefinedVariable(name)
    }

    func getValueAtDepth(name: String, depth: Int) throws -> LoxValue {
        let ancestor = ancestor(depth: depth)

        if let value = ancestor.values[name] {
            return value
        }

        throw RuntimeError.undefinedVariable(name)
    }

    private func ancestor(depth: Int) -> Environment {
        var i = 0
        var ancestor: Environment = self
        while i < depth {
            if let parent = ancestor.enclosingEnvironment {
                ancestor = parent
            } else {
                // TODO: Need to decide what to do here
            }

            i = i + 1
        }

        return ancestor
    }

    static func == (lhs: Environment, rhs: Environment) -> Bool {
        return lhs === rhs
    }
}
