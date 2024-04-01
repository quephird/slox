//
//  NativeFunction.swift
//  slox
//
//  Created by Danielle Kefford on 3/2/24.
//

import Foundation

enum NativeFunction: LoxCallable, Equatable, CaseIterable {
    case clock
    case appendNative
    case deleteAtNative
    case removeValueNative
    case keysNative
    case valuesNative

    var arity: Int {
        switch self {
        case .clock:
            return 0
        case .appendNative:
            return 2
        case .deleteAtNative:
            return 2
        case .removeValueNative:
            return 2
        case .keysNative:
            return 1
        case .valuesNative:
            return 1
        }
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        switch self {
        case .clock:
            return .double(Date().timeIntervalSince1970)
        case .appendNative:
            guard case .instance(let loxList as LoxList) = args[0] else {
                throw RuntimeError.notAList
            }

            let element = args[1]
            loxList.elements.append(element)

            return .nil
        case .deleteAtNative:
            guard case .instance(let loxList as LoxList) = args[0] else {
                throw RuntimeError.notAList
            }

            guard case .int(let index) = args[1] else {
                throw RuntimeError.indexMustBeAnInteger
            }

            return loxList.elements.remove(at: Int(index))
        case .removeValueNative:
            guard case .instance(let loxDictionary as LoxDictionary) = args[0] else {
                throw RuntimeError.notADictionary
            }

            let key = args[1]

            return loxDictionary.kvPairs.removeValue(forKey: key) ?? .nil
        case .keysNative:
            guard case .instance(let loxDictionary as LoxDictionary) = args[0] else {
                throw RuntimeError.notADictionary
            }

            let keys = Array(loxDictionary.kvPairs.keys)

            return try! interpreter.makeList(elements: keys)
        case .valuesNative:
            guard case .instance(let loxDictionary as LoxDictionary) = args[0] else {
                throw RuntimeError.notADictionary
            }

            let values = Array(loxDictionary.kvPairs.values)

            return try! interpreter.makeList(elements: values)
        }
    }
}
