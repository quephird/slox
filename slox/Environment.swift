//
//  Environment.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

struct Environment {
    private var values: [String: Literal] = [:]

    mutating func define(name: String, value: Literal) {
        values[name] = value
    }

    func getValue(name: String) throws -> Literal {
        if let value = values[name] {
            return value
        }

        throw RuntimeError.undefinedVariable(name)
    }
}
