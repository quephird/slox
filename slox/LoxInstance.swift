//
//  LoxInstance.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxInstance: Equatable {
    var klass: LoxClass
    var properties: [String: LoxValue] = [:]

    init(klass: LoxClass) {
        self.klass = klass
    }

    func get(propertyName: String) throws -> LoxValue {
        if let propertyValue = self.properties[propertyName] {
            return propertyValue
        }

        throw RuntimeError.undefinedProperty(propertyName)
    }

    static func == (lhs: LoxInstance, rhs: LoxInstance) -> Bool {
        return lhs === rhs
    }
}
