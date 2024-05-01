//
//  Statement.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

indirect enum Statement<Depth: Equatable>: Equatable {
    case expression(Expression<Depth>)
    case `if`(Expression<Depth>, Statement, Statement?)
    case `switch`(Token, Expression<Depth>, [SwitchCaseDeclaration<Depth>])
    case print(Expression<Depth>)
    case variableDeclaration(Token, Expression<Depth>?)
    case block([Statement])
    case `while`(Expression<Depth>, Statement)
    case `for`(Statement?, Expression<Depth>, Expression<Depth>?, Statement)
    case function(Token, Expression<Depth>)
    case `return`(Token, Expression<Depth>?)
    case `class`(Token, Expression<Depth>?, [Statement], [Statement])
    case `enum`(Token, [Token], [Statement], [Statement])
    case `break`(Token)
    case `continue`(Token)
}
