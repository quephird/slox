//
//  ResolvedSwitchCaseDeclaration.swift
//  slox
//
//  Created by Danielle Kefford on 4/26/24.
//

struct ResolvedSwitchCaseDeclaration: Equatable {
    var valueExpressions: [ResolvedExpression]
    var statement: ResolvedStatement
}
