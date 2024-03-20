//
//  LoxList.swift
//  slox
//
//  Created by Danielle Kefford on 3/12/24.
//

class LoxList: LoxInstance {
    var elements: [LoxValue]

    private class AppendImpl: LoxCallable {
        var arity: Int = 1
        var listInstance: LoxList

        init(listInstance: LoxList) {
            self.listInstance = listInstance
        }

        func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
            let element = args[0]
            self.listInstance.elements.append(element)
            return .nil
        }
    }

    private class DeleteAtImpl: LoxCallable {
        var arity: Int = 1
        var listInstance: LoxList

        init(listInstance: LoxList) {
            self.listInstance = listInstance
        }

        func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
            guard case .number(let index) = args[0] else {
                throw RuntimeError.indexMustBeANumber
            }

            return self.listInstance.elements.remove(at: Int(index))
        }
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
            return .callable(AppendImpl(listInstance: self))
        case "deleteAt":
            return .callable(DeleteAtImpl(listInstance: self))
        default:
            throw RuntimeError.undefinedProperty(propertyName)
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
