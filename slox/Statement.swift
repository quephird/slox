//
//  Statement.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

indirect enum Statement: Equatable {
    case expression(Expression)
    case `if`(Expression, Statement, Statement?)
    case print(Expression)
    case variableDeclaration(Token, Expression?)
    case block([Statement])
    case `while`(Expression, Statement)
    case function(Token, [Token], [Statement])
}
