//
//  LoxInstance.swift
//  slox
//
//  Created by Danielle Kefford on 3/4/24.
//

class LoxInstance: Equatable {
    var klass: LoxClass?
    var properties: [String: LoxValue] = [:]

    init(klass: LoxClass?) {
        self.klass = klass
    }

    func get(propertyName: String) throws -> LoxValue {
        if let klass {
            if let propertyValue = self.properties[propertyName] {
                return propertyValue
            }

            if let method = klass.methods[propertyName] {
                let boundMethod = method.bind(instance: self)
                return .userDefinedFunction(boundMethod)
            }

            throw RuntimeError.undefinedProperty(propertyName)
        }

        fatalError()
    }

    func set(propertyName: String, propertyValue: LoxValue) {
        self.properties[propertyName] = propertyValue
    }

    static func == (lhs: LoxInstance, rhs: LoxInstance) -> Bool {
        return lhs === rhs
    }
}
