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

    override func get(propertyName: Token, includePrivate: Bool) throws -> LoxValue {
        switch propertyName.lexeme {
        case "count":
            return .int(elements.count)
        default:
            return try super.get(propertyName: propertyName, includePrivate: includePrivate)
        }
    }

    override func set(propertyName: Token, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties(propertyName)
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
