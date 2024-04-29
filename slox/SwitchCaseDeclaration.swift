//
//  SwitchCaseDeclaration.swift
//  slox
//
//  Created by Danielle Kefford on 4/26/24.
//

struct SwitchCaseDeclaration<Depth>: Equatable {
    var valueExpressions: [Expression<Depth>]?
    var statement: Statement<Depth>
}
