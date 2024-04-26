//
//  Statement.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

indirect enum Statement: Equatable {
    case expression(Expression)
    case `if`(Expression, Statement, Statement?)
    case `switch`(Expression, [SwitchCaseDeclaration], [Statement]?)
    case print(Expression)
    case variableDeclaration(Token, Expression?)
    case block([Statement])
    case `while`(Expression, Statement)
    case `for`(Statement?, Expression, Expression?, Statement)
    case function(Token, Expression)
    case `return`(Token, Expression?)
    case `class`(Token, Expression?, [Statement], [Statement])
    case `enum`(Token, [Token], [Statement], [Statement])
    case `break`(Token)
    case `continue`(Token)
}
