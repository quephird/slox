//
//  LoxDictionary.swift
//  slox
//
//  Created by Danielle Kefford on 3/25/24.
//

class LoxDictionary: LoxInstance {
    var kvPairs: [LoxValue: LoxValue]

    convenience init(kvPairs: [LoxValue: LoxValue], klass: LoxClass) {
        self.init(klass: klass)
        self.kvPairs = kvPairs
    }

    required init(klass: LoxClass?) {
        self.kvPairs = [:]
        super.init(klass: klass)
    }

    override func get(propertyName: Token, includePrivate: Bool) throws -> LoxValue {
        switch propertyName.lexeme {
        case "count":
            return .int(self.kvPairs.count)
        default:
            return try super.get(propertyName: propertyName, includePrivate: includePrivate)
        }
    }

    override func set(propertyName: Token, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties(propertyName)
    }

    subscript(key: LoxValue) -> LoxValue {
        get {
            return kvPairs[key] ?? .nil
        }
        set(newValue) {
            kvPairs[key] = newValue
        }
    }
}
