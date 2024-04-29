//
//  SwitchCaseDeclaration.swift
//  slox
//
//  Created by Danielle Kefford on 4/26/24.
//

struct SwitchCaseDeclaration: Equatable {
    var valueExpressions: [Expression]?
    var statement: Statement
}
