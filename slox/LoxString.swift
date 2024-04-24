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

    override func get(propertyName: String) throws -> LoxValue {
        switch propertyName {
        case "count":
            return .int(string.count)
        default:
            return try super.get(propertyName: propertyName)
        }
    }

    override func set(propertyName: String, propertyValue: LoxValue) throws {
        throw RuntimeError.onlyInstancesHaveProperties
    }
}
