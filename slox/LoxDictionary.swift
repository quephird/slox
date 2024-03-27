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

    override func get(propertyName: String) throws -> LoxValue {
        switch propertyName {
        case "count":
            return .int(self.kvPairs.count)
        default:
            return try super.get(propertyName: propertyName)
        }
    }

    override func set(propertyName: String, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties
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