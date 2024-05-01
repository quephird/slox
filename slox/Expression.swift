//
//  Expression.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

indirect enum Expression<Depth: Equatable>: Equatable {
    case binary(Expression, Token, Expression)
    case unary(Token, Expression)
    case literal(LoxValue)
    case grouping(Expression)
    case variable(Token, Depth)
    case assignment(Token, Expression, Depth)
    case logical(Expression, Token, Expression)
    case call(Expression, Token, [Expression])
    case lambda(Token, ParameterList?, [Statement<Depth>])
    case get(Expression, Token)
    case set(Expression, Token, Expression)
    case this(Token, Depth)
    case `super`(Token, Token, Depth)
    case string(Token)
    case list([Expression])
    case subscriptGet(Expression, Expression)
    case subscriptSet(Expression, Expression, Expression)
    case dictionary([(Expression, Expression)])
    case splat(Token, Expression)

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        switch (lhs, rhs) {
        case (.binary(let lhsExpr1, let lhsOper, let lhsExpr2), .binary(let rhsExpr1, let rhsOper, let rhsExpr2)):
            return lhsExpr1 == rhsExpr1 && lhsOper == rhsOper && lhsExpr2 == rhsExpr2
        case (.unary(let lhsOper, let lhsExpr), .unary(let rhsOper, let rhsExpr)):
            return lhsOper == rhsOper && lhsExpr == rhsExpr
        case (.literal(let lhsValue), .literal(let rhsValue)):
            return lhsValue == rhsValue
        case (.grouping(let lhsExpr), .grouping(let rhsExpr)):
            return lhsExpr == rhsExpr
        case (.variable(let lhsToken, let lhsDepth), .variable(let rhsToken, let rhsDepth)):
            return lhsToken == rhsToken && lhsDepth == rhsDepth
        case (.assignment(let lhsName, let lhsExpr, let lhsDepth), .assignment(let rhsName, let rhsExpr, let rhsDepth)):
            return lhsName == rhsName && lhsExpr == rhsExpr && lhsDepth == rhsDepth
        case (.logical(let lhsExpr1, let lhsOper, let lhsExpr2), .logical(let rhsExpr1, let rhsOper, let rhsExpr2)):
            return lhsExpr1 == rhsExpr1 && lhsOper == rhsOper && lhsExpr2 == rhsExpr2
        case (.call(let lhsCallee, let lhsToken, let lhsArgs), .call(let rhsCallee, let rhsToken, let rhsArgs)):
            return lhsCallee == rhsCallee && lhsToken == rhsToken && lhsArgs == rhsArgs
        case (.lambda(let lhsLocToken, let lhsParams, let lhsBody), .lambda(let rhsLocToken, let rhsParams, let rhsBody)):
            return lhsParams == rhsParams && lhsBody == rhsBody && lhsLocToken == rhsLocToken
        case (.get(let lhsExpr, let lhsName), .get(let rhsExpr, let rhsName)):
            return lhsExpr == rhsExpr && lhsName == rhsName
        case (.set(let lhsExpr1, let lhsName, let lhsExpr2), .set(let rhsExpr1, let rhsName, let rhsExpr2)):
            return lhsExpr1 == rhsExpr1 && lhsName == rhsName && lhsExpr2 == rhsExpr2
        case (.this(let lhsToken, let lhsDepth), .this(let rhsToken, let rhsDepth)):
            return lhsToken == rhsToken && lhsDepth == rhsDepth
        case (.super(let lhsSuper, let lhsMethod, let lhsDepth), .super(let rhsSuper, let rhsMethod, let rhsDepth)):
            return lhsSuper == rhsSuper && lhsMethod == rhsMethod && lhsDepth == rhsDepth
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.list(let lhsExprs), .list(let rhsExprs)):
            return lhsExprs == rhsExprs
        case (.subscriptGet(let lhsList, let lhsIdx), .subscriptGet(let rhsList, let rhsIdx)):
            return lhsList == rhsList && lhsIdx == rhsIdx
        case (.subscriptSet(let lhsList, let lhsIdx, let lhsExpr), .subscriptSet(let rhsList, let rhsIdx, let rhsExpr)):
            return lhsList == rhsList && lhsIdx == rhsIdx && lhsExpr == rhsExpr
        case (.dictionary(let lhsKVPairs), .dictionary(let rhsKVPairs)):
            if lhsKVPairs.count != rhsKVPairs.count {
                return false
            }

            for ((lhsKey, lhsValue), (rhsKey, rhsValue)) in zip(lhsKVPairs, rhsKVPairs) {
                if lhsKey != rhsKey || lhsValue != rhsValue {
                    return false
                }
            }

            return true
        case (.splat(let lhsStarToken, let lhsList), .splat(let rhsStarToken, let rhsList)):
            return lhsStarToken == rhsStarToken && lhsList == rhsList
        default:
            return false
        }
    }
}
