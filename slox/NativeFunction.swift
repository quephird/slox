//
//  NativeFunction.swift
//  slox
//
//  Created by Danielle Kefford on 3/2/24.
//

import Foundation

enum NativeFunction: LoxCallable, Equatable, CaseIterable {
    case clock
    case getInputNative
    case appendNative
    case deleteAtNative
    case removeValueNative
    case keysNative
    case valuesNative

    var parameterList: ParameterList? {
        let normalParameters: [String] = switch self {
        case .clock:
            []
        case .getInputNative:
            ["prompt"]
        case .appendNative:
            ["this", "element"]
        case .deleteAtNative:
            ["this", "index"]
        case .removeValueNative:
            ["this", "index"]
        case .keysNative:
            ["this"]
        case .valuesNative:
            ["this"]
        }

        return ParameterList(
            normalParameters: normalParameters.map { paramName in
                Token(type: .identifier, lexeme: paramName, line: 0)
            }
        )
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        switch self {
        case .clock:
            return .double(Date().timeIntervalSince1970)
        case .getInputNative:
            let prompt = args[0]
            print(prompt, terminator: " ")
            if let input = readLine() {
                return .string(input)
            }

            return .nil
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
