//
//  ResolvedExpression.swift
//  slox
//
//  Created by Danielle Kefford on 3/3/24.
//

indirect enum ResolvedExpression: Equatable {
    case binary(ResolvedExpression, Token, ResolvedExpression)
    case unary(Token, ResolvedExpression)
    case literal(LoxValue)
    case grouping(ResolvedExpression)
    case variable(Token, Int)
    case assignment(Token, ResolvedExpression, Int)
    case logical(ResolvedExpression, Token, ResolvedExpression)
    case call(ResolvedExpression, Token, [ResolvedExpression])
    case lambda([Token], [ResolvedStatement])
    case get(ResolvedExpression, Token)
    case set(ResolvedExpression, Token, ResolvedExpression)
    case this(Token, Int)
    case `super`(Token, Token, Int)
    case list([ResolvedExpression])
    case subscriptGet(ResolvedExpression, ResolvedExpression)
    case subscriptSet(ResolvedExpression, ResolvedExpression, ResolvedExpression)
}
