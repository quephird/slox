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

    init(elements: [LoxValue]) {
        self.elements = elements
        super.init(klass: nil)
    }

    override func get(propertyName: String) throws -> LoxValue {
        switch propertyName {
        case "count":
            return .number(Double(elements.count))
        case "append":
            // TODO: Need to return an object that:
            //
            // * conforms to LoxCallable so that it can be invoked
            // * conforms to Equatable so that it can be a member of a LoxValue case
            // * can mutate self.elements
            //
            // It can't be a UserDefinedFunction because we have no reference to
            // an Environment instance by the time we get here
            // It also can't be a NativeFunction because there is no way to access
            // a reference to the relevant LoxList instance from from within it
            fatalError()
        default:
            throw RuntimeError.onlyInstancesHaveProperties
        }
    }

    override func set(propertyName: String, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties
    }

    static func == (lhs: LoxList, rhs: LoxList) -> Bool {
        return lhs.elements == rhs.elements
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
