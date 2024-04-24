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

    // NOTA BENE: This allows us to get back the case associated with its name
    override func call(interpreter: Interpreter, args: [LoxValue]) throws -> LoxValue {
        precondition(args.count == 1)
        guard case .string(let caseName)? = args.first else {
            return .nil
        }

        return self.properties[caseName] ?? LoxValue.nil
    }
}
