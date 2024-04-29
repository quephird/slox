//
//  ResolvedStatement.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

indirect enum ResolvedStatement: Equatable {
    case expression(ResolvedExpression)
    case `if`(ResolvedExpression, ResolvedStatement, ResolvedStatement?)
    case `switch`(ResolvedExpression, [ResolvedSwitchCaseDeclaration])
    case print(ResolvedExpression)
    case variableDeclaration(Token, ResolvedExpression?)
    case block([ResolvedStatement])
    case `while`(ResolvedExpression, ResolvedStatement)
    case `for`(ResolvedStatement?, ResolvedExpression, ResolvedExpression?, ResolvedStatement)
    case function(Token, ResolvedExpression)
    case `return`(Token, ResolvedExpression?)
    case `class`(Token, ResolvedExpression?, [ResolvedStatement], [ResolvedStatement])
    case `enum`(Token, [Token], [ResolvedStatement], [ResolvedStatement])
    case `break`(Token)
    case `continue`(Token)
}
