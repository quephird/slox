//
//  NativeFunction.swift
//  slox
//
//  Created by Danielle Kefford on 3/2/24.
//

import Foundation

enum NativeFunction: LoxCallable, Equatable, CaseIterable {
    case clock

    var arity: Int {
        switch self {
        case .clock:
            return 0
        }
    }

    func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        switch self {
        case .clock:
            return .number(Date().timeIntervalSince1970)
        }
    }
}
