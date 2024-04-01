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
    case lambda([Token]?, [ResolvedStatement])
    case get(ResolvedExpression, Token)
    case set(ResolvedExpression, Token, ResolvedExpression)
    case this(Token, Int)
    case `super`(Token, Token, Int)
    case list([ResolvedExpression])
    case subscriptGet(ResolvedExpression, ResolvedExpression)
    case subscriptSet(ResolvedExpression, ResolvedExpression, ResolvedExpression)
    case dictionary([(ResolvedExpression, ResolvedExpression)])

    static func == (lhs: ResolvedExpression, rhs: ResolvedExpression) -> Bool {
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
        case (.lambda(let lhsParams, let lhsBody), .lambda(let rhsParams, let rhsBody)):
            return lhsParams == rhsParams && lhsBody == rhsBody
        case (.get(let lhsExpr, let lhsName), .get(let rhsExpr, let rhsName)):
            return lhsExpr == rhsExpr && lhsName == rhsName
        case (.set(let lhsExpr1, let lhsName, let lhsExpr2), .set(let rhsExpr1, let rhsName, let rhsExpr2)):
            return lhsExpr1 == rhsExpr1 && lhsName == rhsName && lhsExpr2 == rhsExpr2
        case (.this(let lhsToken, let lhsDepth), .this(let rhsToken, let rhsDepth)):
            return lhsToken == rhsToken && lhsDepth == rhsDepth
        case (.super(let lhsSuper, let lhsMethod, let lhsDepth), .super(let rhsSuper, let rhsMethod, let rhsDepth)):
            return lhsSuper == rhsSuper && lhsMethod == rhsMethod && lhsDepth == rhsDepth
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
        default:
            return false
        }
    }
}
