//
//  LoxString.swift
//  slox
//
//  Created by Danielle Kefford on 4/17/24.
//

import Foundation

class LoxString: LoxInstance {
    var string: String

    convenience init(string: String, klass: LoxClass) {
        self.init(klass: klass)
        self.string = string
    }

    required init(klass: LoxClass?) {
        self.string = ""
        super.init(klass: klass)
    }

    override func get(propertyName: Token) throws -> LoxValue {
        switch propertyName.lexeme {
        case "count":
            return .int(string.count)
        default:
            return try super.get(propertyName: propertyName)
        }
    }

    override func set(propertyName: Token, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties(propertyName)
    }
}
