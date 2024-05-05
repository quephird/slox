//
//  Expression.swift
//  slox
//
//  Created by Danielle Kefford on 2/25/24.
//

indirect enum Expression<Depth: Equatable>: Equatable {
    case binary(Expression, Token, Expression)
    case unary(Token, Expression)
    case literal(Token, LoxValue)
    case grouping(Token, Expression)
    case variable(Token, Depth)
    case assignment(Token, Expression, Depth)
    case logical(Expression, Token, Expression)
    case call(Expression, Token, [Expression])
    case lambda(Token, ParameterList?, [Statement<Depth>])
    case get(Token, Expression, Token)
    case set(Token, Expression, Token, Expression)
    case this(Token, Depth)
    case `super`(Token, Token, Depth)
    case string(Token)
    case list(Token, [Expression])
    case subscriptGet(Expression, Expression)
    case subscriptSet(Expression, Expression, Expression)
    case dictionary(Token, [(Expression, Expression)])
    case splat(Token, Expression)

    var locToken: Token {
        switch self {
        case .binary(_, let operToken, _):
            return operToken
        case .unary(let locToken, _):
            return locToken
        case .literal(let valueToken, _):
            return valueToken
        case .grouping(let leftParenToken, _):
            return leftParenToken
        case .variable(let nameToken, _):
            return nameToken
        case .assignment(let nameToken, _, _):
            return nameToken
        case .logical(_, let operToken, _):
            return operToken
        case .call(_, let rightParenToken, _):
            return rightParenToken
        case .lambda(let locToken, _, _):
            return locToken
        case .get(let dotToken, _, _):
            return dotToken
        case .set(let dotToken, _, _, _):
            return dotToken
        case .this(let thisToken, _):
            return thisToken
        case .super(let superToken, _, _):
            return superToken
        case .string(let stringToken):
            return stringToken
        case .list(let leftBracketToken, _):
            return leftBracketToken
        case .dictionary(let leftBracketToken, _):
            return leftBracketToken
        case .splat(let starToken, _):
            return starToken
        default:
            return Token(type: .eof, lexeme: "", line: 0)
        }
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        switch (lhs, rhs) {
        case (.binary(let lhsExpr1, let lhsOper, let lhsExpr2), .binary(let rhsExpr1, let rhsOper, let rhsExpr2)):
            return lhsExpr1 == rhsExpr1 && lhsOper == rhsOper && lhsExpr2 == rhsExpr2
        case (.unary(let lhsOper, let lhsExpr), .unary(let rhsOper, let rhsExpr)):
            return lhsOper == rhsOper && lhsExpr == rhsExpr
        case (.literal(let lhsValueToken, let lhsValue), .literal(let rhsValueToken, let rhsValue)):
            return lhsValueToken == rhsValueToken && lhsValue == rhsValue
        case (.grouping(let lhsParenToken, let lhsExpr), .grouping(let rhsParenToken, let rhsExpr)):
            return lhsParenToken == rhsParenToken && lhsExpr == rhsExpr
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
        case (.get(let lhsLocToken, let lhsExpr, let lhsName), .get(let rhsLocToken, let rhsExpr, let rhsName)):
            return lhsLocToken == rhsLocToken && lhsExpr == rhsExpr && lhsName == rhsName
        case (.set(let lhsLocToken, let lhsExpr1, let lhsName, let lhsExpr2), .set(let rhsLocToken, let rhsExpr1, let rhsName, let rhsExpr2)):
            return lhsLocToken == rhsLocToken && lhsExpr1 == rhsExpr1 && lhsName == rhsName && lhsExpr2 == rhsExpr2
        case (.this(let lhsToken, let lhsDepth), .this(let rhsToken, let rhsDepth)):
            return lhsToken == rhsToken && lhsDepth == rhsDepth
        case (.super(let lhsSuper, let lhsMethod, let lhsDepth), .super(let rhsSuper, let rhsMethod, let rhsDepth)):
            return lhsSuper == rhsSuper && lhsMethod == rhsMethod && lhsDepth == rhsDepth
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.list(let lhsBracketToken, let lhsExprs), .list(let rhsBracketToken, let rhsExprs)):
            return lhsBracketToken == rhsBracketToken && lhsExprs == rhsExprs
        case (.subscriptGet(let lhsList, let lhsIdx), .subscriptGet(let rhsList, let rhsIdx)):
            return lhsList == rhsList && lhsIdx == rhsIdx
        case (.subscriptSet(let lhsList, let lhsIdx, let lhsExpr), .subscriptSet(let rhsList, let rhsIdx, let rhsExpr)):
            return lhsList == rhsList && lhsIdx == rhsIdx && lhsExpr == rhsExpr
        case (.dictionary(let lhsBracketToken, let lhsKVPairs), .dictionary(let rhsBracketToken, let rhsKVPairs)):
            if lhsBracketToken != rhsBracketToken {
                return false
            }

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
