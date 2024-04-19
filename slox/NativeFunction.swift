//
//  NativeFunction.swift
//  slox
//
//  Created by Danielle Kefford on 3/2/24.
//

import Foundation

enum NativeFunction: LoxCallable, Equatable, CaseIterable {
    case clock
    case toInt
    case toDouble
    case getInput
    case appendNative
    case deleteAtNative
    case removeValueNative
    case keysNative
    case valuesNative
    case randInt
    case randDouble
    case charsNative

    var parameterList: ParameterList? {
        let normalParameters: [String] = switch self {
        case .clock:
            []
        case .toInt:
            ["input"]
        case .toDouble:
            ["input"]
        case .getInput:
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
        case .randInt:
            ["start", "end"]
        case .randDouble:
            ["start", "end"]
        case .charsNative:
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
        case .toInt:
            guard case .instance(let loxString as LoxString) = args[0] else {
                throw RuntimeError.notAString
            }

            if let integer = Int(loxString.string) {
                return .int(integer)
            }

            return .nil
        case .toDouble:
            guard case .instance(let loxString as LoxString) = args[0] else {
                throw RuntimeError.notAString
            }

            if let double = Double(loxString.string) {
                return .double(double)
            }

            return .nil
        case .getInput:
            let prompt = args[0]
            print(prompt, terminator: " ")
            if let input = readLine() {
                return try interpreter.makeString(string: input)
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
        case .randInt:
            guard case .int(let start) = args[0] else {
                throw RuntimeError.notAnInt
            }

            guard case .int(let end) = args[1] else {
                throw RuntimeError.notAnInt
            }

            return .int(Int.random(in: start...end))
        case .randDouble:
            guard case .double(let start) = args[0] else {
                throw RuntimeError.notADouble
            }

            guard case .double(let end) = args[1] else {
                throw RuntimeError.notADouble
            }

            return .double(Double.random(in: start...end))
        case .charsNative:
            guard case .instance(let loxString as LoxString) = args[0] else {
                throw RuntimeError.notAString
            }

            let characters = try loxString.string.unicodeScalars.map { unicodeScalar in
                try interpreter.makeString(string: String(unicodeScalar))
            }

            return try interpreter.makeList(elements: characters)
        }
    }
}
