//
//  Environment.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

class Environment {
    private var enclosingEnvironment: Environment?
    private var values: [String: Literal] = [:]

    init(enclosingEnvironment: Environment? = nil) {
        self.enclosingEnvironment = enclosingEnvironment
    }

    func define(name: String, value: Literal) {
        values[name] = value
    }

    func assign(name: String, value: Literal) throws {
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

    func getValue(name: String) throws -> Literal {
        if let value = values[name] {
            return value
        }

        if let enclosingEnvironment = enclosingEnvironment {
            return try enclosingEnvironment.getValue(name: name)
        }

        throw RuntimeError.undefinedVariable(name)
    }
}
