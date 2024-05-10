//
//  LoxEnum.swift
//  slox
//
//  Created by Danielle Kefford on 4/23/24.
//

class LoxEnum: LoxClass {
    override var parameterList: ParameterList? {
        let parameters = [
            Token(type: .identifier, lexeme: "caseName", line: 0),
        ]
        return ParameterList(normalParameters: parameters)
    }

    override func set(propertyName: Token, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties(propertyName)
    }
}
