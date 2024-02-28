//
//  Expression.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

indirect enum Expression: Equatable {
    case binary(Expression, Token, Expression)
    case unary(Token, Expression)
    case literal(Literal)
    case grouping(Expression)
    case variable(Token)
    case assignment(Token, Expression)
}
