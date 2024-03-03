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

    func getValue(name: String) throws -> LoxValue {
        if let value = values[name] {
            return value
        }

        if let enclosingEnvironment = enclosingEnvironment {
            return try enclosingEnvironment.getValue(name: name)
        }

        throw RuntimeError.undefinedVariable(name)
    }

    static func == (lhs: Environment, rhs: Environment) -> Bool {
        return lhs === rhs
    }
}
