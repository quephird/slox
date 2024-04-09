//
//  ParameterList.swift
//  slox
//
//  Created by Danielle Kefford on 4/6/24.
//

struct ParameterList: Equatable {
    var normalParameters: [Token]
    var variadicParameter: Token?

    func checkArity(argCount: Int) throws {
        let normalParameterCount = normalParameters.count
        if let variadicParameter {
            guard argCount >= normalParameterCount else {
                throw RuntimeError.wrongArity(normalParameterCount, argCount)
            }

            return
        }

        guard argCount == normalParameterCount else {
            throw RuntimeError.wrongArity(normalParameterCount, argCount)
        }
    }
}
