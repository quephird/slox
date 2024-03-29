//
//  Expression.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

indirect enum Expression: Equatable {
    case binary(Expression, Token, Expression)
    case unary(Token, Expression)
    case literal(LoxValue)
    case grouping(Expression)
    case variable(Token)
    case assignment(Token, Expression)
    case logical(Expression, Token, Expression)
    case call(Expression, Token, [Expression])
    case lambda([Token], [Statement])
    case get(Expression, Token)
    case set(Expression, Token, Expression)
    case this(Token)
    case `super`(Token, Token)
    case list([Expression])
    case subscriptGet(Expression, Expression)
    case subscriptSet(Expression, Expression, Expression)
}
