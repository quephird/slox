//
//  LoxList.swift
//  slox
//
//  Created by Danielle Kefford on 3/12/24.
//

class LoxList: LoxInstance {
    var elements: [LoxValue]
    var count: Int {
        return elements.count
    }

    convenience init(elements: [LoxValue], klass: LoxClass) {
        self.init(klass: klass)
        self.elements = elements
    }

    required init(klass: LoxClass?) {
        self.elements = []
        super.init(klass: klass)
    }

    override func get(propertyName: String) throws -> LoxValue {
        switch propertyName {
        case "count":
            return .int(elements.count)
        default:
            return try super.get(propertyName: propertyName)
        }
    }

    override func set(propertyName: String, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties
    }

    // TODO: Need to think about how to handle invalid indices!!!
    subscript(index: Int) -> LoxValue {
        get {
            return elements[index]
        }
        set(newValue) {
            elements[index] = newValue
        }
    }
}
