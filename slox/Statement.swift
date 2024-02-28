//
//  Statement.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

enum Statement: Equatable {
    case expression(Expression)
    case print(Expression)
    case variableDeclaration(Token, Expression?)
    case block([Statement])
}
