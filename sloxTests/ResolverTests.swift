//
//  ResolverTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 3/3/24.
//

import XCTest

final class ResolverTests: XCTestCase {
    func testResolveLiteralExpression() throws {
        // "forty-two"
        let statements: [Statement] = [
            .expression(
                .literal(
                    .string("forty-two"))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [ResolvedStatement] = [
            .expression(
                .literal(
                    .string("forty-two")))
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveVariableDeclaration() throws {
        // var answer = 42;
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(.number(42))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(.number(42))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveFunctionDeclaration() throws {
        // fun add(a, b) {
        //     return a + b;
        // }
        let statements: [Statement] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "a", line: 2)),
                                Token(type: .plus, lexeme: "+", line: 2),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 2)))),
                    ])),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [ResolvedStatement] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "a", line: 2),
                                    0),
                                Token(type: .plus, lexeme: "+", line: 2),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 2),
                                    0))),
                    ])),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveVariableExpressionInDeeplyNestedBlock() throws {
        // var becca; {{{ becca = "awesome"; }}}
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "becca", line: 1),
                nil),
            .block([
                .block([
                    .block([
                        .expression(
                            .assignment(
                                Token(type: .identifier, lexeme: "becca", line: 1),
                                .literal(.string("awesome"))))
                    ])
                ])
            ])
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [ResolvedStatement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "becca", line: 1),
                nil),
            .block([
                .block([
                    .block([
                        .expression(
                            .assignment(
                                Token(type: .identifier, lexeme: "becca", line: 1),
                                .literal(.string("awesome")),
                                3))
                    ])
                ])
            ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveReturnStatementOutsideFunctionBody() throws {
        // { return 42; }
        let statements: [Statement] = [
            .block([
                .return(
                    Token(type: .return, lexeme: "return", line: 1),
                    .literal(.number(42))),
            ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotReturnOutsideFunction
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveVariableReferencedInItsOwnInitializer() throws {
        // var a = "outer";
        // {
        //     var a = a;
        // }
        let statements: [Statement] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "x", line: 1),
                .literal(.string("outer"))),
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "x", line: 3),
                    .variable(
                        Token(type: .identifier, lexeme: "x", line: 3))),
            ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.variableAccessedBeforeInitialization
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveVariableBeingDeclaredTwiceInTheSameScope() throws {
        // {
        //     var a = "first";
        //     var a = "second";
        // }
        let statements: [Statement] = [
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "a", line: 2),
                    .literal(.string("first"))),
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "a", line: 3),
                    .literal(.string("second"))),
            ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.variableAlreadyDefined("a")
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveClassDeclaration() throws {
        let statements: [Statement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        .lambda(
                            [],
                            [
                                .print(
                                    .get(
                                        .this(Token(type: .this, lexeme: "this", line: 3)),
                                        Token(type: .identifier, lexeme: "name", line: 3)))
                            ]))
                ],
                [])
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [ResolvedStatement] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        .lambda(
                            [],
                            [
                                .print(
                                    .get(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            1),
                                        Token(type: .identifier, lexeme: "name", line: 3)))
                            ]))
                ],
                [])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveIllegalUseOfThis() throws {
        // fun foo() {
        //     return this;
        // }
        let statements: [Statement] = [
            .function(
                Token(type: .identifier, lexeme: "foo", line: 1),
                .lambda(
                    [],
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .this(Token(type: .this, lexeme: "this", line: 2)))
                    ])),
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotReferenceThisOutsideClass
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveClassWithInitializerThatReturnsExplicitValue() throws {
        // class Answer {
        //     init() {
        //         return 42;
        //     }
        // }
        let statements: [Statement] = [
            .class(
                Token(type: .identifier, lexeme: "Answer", line: 1),
                [
                    .function(
                        Token(type: .identifier, lexeme: "init", line: 2),
                        .lambda(
                            [],
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .literal(.number(42)))
                            ]))
                ],
                [])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotReturnValueFromInitializer
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }

    }
}
