//
//  Statement.swift
//  slox
//
//  Created by Danielle Kefford on 2/27/24.
//

indirect enum Statement<Depth: Equatable>: Equatable {
    case expression(Expression<Depth>)
    case `if`(Token, Expression<Depth>, Statement, Statement?)
    case `switch`(Token, Expression<Depth>, [SwitchCaseDeclaration<Depth>])
    case print(Token, Expression<Depth>)
    case variableDeclaration(Token, Expression<Depth>?)
    case block(Token, [Statement])
    case `while`(Token, Expression<Depth>, Statement)
    case `for`(Statement?, Expression<Depth>, Expression<Depth>?, Statement)
    case function(Token, Expression<Depth>)
    case `return`(Token, Expression<Depth>?)
    case `class`(Token, Expression<Depth>?, [Statement], [Statement])
    case `enum`(Token, [Token], [Statement], [Statement])
    case `break`(Token)
    case `continue`(Token)

    var locToken: Token {
        switch self {
        case .expression(let expr):
            return expr.locToken
        case .if(let ifToken, _, _, _):
            return ifToken
        case .switch(let switchToken, _, _):
            return switchToken
        case .print(let printToken, _):
            return printToken
        case .variableDeclaration(let nameToken, _):
            return nameToken
        case .block(let beginBlockToken, _):
            return beginBlockToken
        case .while(let whileToken, _, _):
            return whileToken
        case .function(let nameToken, _):
            return nameToken
        case .return(let returnToken, _):
            return returnToken
        case .class(let nameToken, _, _, _):
            return nameToken
        case .enum(let nameToken, _, _, _):
            return nameToken
        case .break(let breakToken):
            return breakToken
        case .continue(let continueToken):
            return continueToken
        default:
            return Token(type: .eof, lexeme: "", line: 0)
        }
    }
}
