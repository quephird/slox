//
//  ParameterList.swift
//  slox
//
//  Created by Danielle Kefford on 4/6/24.
//

struct ParameterList: Equatable {
    var normalParameters: [Token]
    var variadicParameter: Token?

    func checkArity(argCount: Int) -> Bool {
        let normalParameterCount = normalParameters.count
        if variadicParameter != nil {
            return argCount >= normalParameterCount
        }

        return argCount == normalParameterCount
    }
}
