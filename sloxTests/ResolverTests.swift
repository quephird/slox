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
        let statements: [Statement<UnresolvedDepth>] = [
            .expression(
                .literal(
                    .int(42))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .expression(
                .literal(
                    .int(42))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveVariableDeclaration() throws {
        // var answer = 42;
        let statements: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(.int(42))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(.int(42))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveFunctionDeclaration() throws {
        // fun add(a, b) {
        //     return a + b;
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    ParameterList(normalParameters: [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ]),
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .binary(
                                .variable(
                                    Token(type: .identifier, lexeme: "a", line: 2),
                                    UnresolvedDepth()),
                                Token(type: .plus, lexeme: "+", line: 2),
                                .variable(
                                    Token(type: .identifier, lexeme: "b", line: 2),
                                    UnresolvedDepth()))),
                    ])),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .function(
                Token(type: .identifier, lexeme: "add", line: 1),
                .lambda(
                    ParameterList(normalParameters: [
                        Token(type: .identifier, lexeme: "a", line: 1),
                        Token(type: .identifier, lexeme: "b", line: 1),
                    ]),
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

    func testResolveFunctionDeclarationWithoutParameterList() throws {
        // fun answer {
        //     return 42;
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .lambda(
                    nil,
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .literal(.int(42)))
                    ])),
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.functionsMustHaveAParameterList
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveVariableExpressionInDeeplyNestedBlock() throws {
        // var becca; {{{ becca = "awesome"; }}}
        let statements: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "becca", line: 1),
                nil),
            .block([
                .block([
                    .block([
                        .expression(
                            .assignment(
                                Token(type: .identifier, lexeme: "becca", line: 1),
                                .string(Token(type: .string, lexeme: "\"answer\"", line: 1)),
                                UnresolvedDepth()))
                    ])
                ])
            ])
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "becca", line: 1),
                nil),
            .block([
                .block([
                    .block([
                        .expression(
                            .assignment(
                                Token(type: .identifier, lexeme: "becca", line: 1),
                                .string(Token(type: .string, lexeme: "\"answer\"", line: 1)),
                                3))
                    ])
                ])
            ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveReturnStatementOutsideFunctionBody() throws {
        // { return 42; }
        let statements: [Statement<UnresolvedDepth>] = [
            .block([
                .return(
                    Token(type: .return, lexeme: "return", line: 1),
                    .literal(.int(42))),
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
        let statements: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "x", line: 1),
                .string(Token(type: .string, lexeme: "\"outer\"", line: 1))),
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "x", line: 3),
                    .variable(
                        Token(type: .identifier, lexeme: "x", line: 3),
                        UnresolvedDepth())),
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
        let statements: [Statement<UnresolvedDepth>] = [
            .block([
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "a", line: 2),
                    .string(Token(type: .string, lexeme: "\"first\"", line: 1))),
                .variableDeclaration(
                    Token(type: .identifier, lexeme: "a", line: 3),
                    .string(Token(type: .string, lexeme: "\"second\"", line: 1))),
            ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.variableAlreadyDefined("a")
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveClassDeclaration() throws {
        // class Person {
        //     sayName() {
        //         print this.name;
        //     }
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
                            [
                                .print(
                                    .get(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            UnresolvedDepth()),
                                        Token(type: .identifier, lexeme: "name", line: 3)))
                            ]))
                ],
                [])
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .class(
                Token(type: .identifier, lexeme: "Person", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "sayName", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
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
        let statements: [Statement<UnresolvedDepth>] = [
            .function(
                Token(type: .identifier, lexeme: "foo", line: 1),
                .lambda(
                    ParameterList(normalParameters: []),
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .this(
                                Token(type: .this, lexeme: "this", line: 2),
                                UnresolvedDepth()))
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
        let statements: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Answer", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "init", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .literal(.int(42)))
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

    func testResolveClassWithStaticMethod() throws {
        // class Math {
        //     class add(a, b) {
        //         return a + b;
        //     }
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Math", line: 1),
                nil,
                [],
                [
                    .function(
                        Token(type: .identifier, lexeme: "add", line: 2),
                        .lambda(
                            ParameterList(normalParameters: [
                                Token(type: .identifier, lexeme: "a", line: 2),
                                Token(type: .identifier, lexeme: "b", line: 2),
                            ]),
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .variable(
                                            Token(type: .identifier, lexeme: "a", line: 3),
                                            UnresolvedDepth()),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "b", line: 3),
                                            UnresolvedDepth())))
                            ]))
                ])
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .class(
                Token(type: .identifier, lexeme: "Math", line: 1),
                nil,
                [],
                [
                    .function(
                        Token(type: .identifier, lexeme: "add", line: 2),
                        .lambda(
                            ParameterList(normalParameters: [
                                Token(type: .identifier, lexeme: "a", line: 2),
                                Token(type: .identifier, lexeme: "b", line: 2),
                            ]),
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .binary(
                                        .variable(
                                            Token(type: .identifier, lexeme: "a", line: 3),
                                            0),
                                        Token(type: .plus, lexeme: "+", line: 3),
                                        .variable(
                                            Token(type: .identifier, lexeme: "b", line: 3),
                                            0)))
                            ]))
                ])
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveClassWithStaticInitMethod() throws {
        // class BadClass {
        //     class init() {
        //         this.name = "bad";
        //     }
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "Math", line: 1),
                nil,
                [],
                [
                    .function(
                        Token(type: .identifier, lexeme: "init", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
                            [
                                .expression(
                                    .set(
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            UnresolvedDepth()),
                                        Token(type: .identifier, lexeme: "name", line: 3),
                                        .string(Token(type: .string, lexeme: "\"bad\"", line: 1))))
                            ]))
                ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.staticInitsNotAllowed
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveInvocationOfSuperAtTopLevel() throws {
        // super.someMethod()
        let statements: [Statement<UnresolvedDepth>] = [
            .expression(
                .super(
                    Token(type: .super, lexeme: "super", line: 1),
                    Token(type: .identifier, lexeme: "someMethod", line: 1),
                    UnresolvedDepth()))
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotReferenceSuperOutsideClass
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveInvocationOfSuperFromWithinClassThatDoesNotSubclassAnother() throws {
        // class A {
        //     someMethod() {
        //         super.someMethod();
        //     }
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .class(
                Token(type: .identifier, lexeme: "A", line: 1),
                nil,
                [
                    .function(
                        Token(type: .identifier, lexeme: "someMethod", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
                            [
                                .expression(
                                    .call(
                                        .super(
                                            Token(type: .super, lexeme: "super", line: 3),
                                            Token(type: .identifier, lexeme: "someMethod", line: 3),
                                            UnresolvedDepth()),
                                        Token(type: .rightParen, lexeme: ")", line: 3),
                                        [])
                                )
                            ]))
                ],
                [])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotReferenceSuperWithoutSubclassing
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveBreakStatementOutsideLoop() throws {
        // if (true) {
        //     break;
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .if(
                .literal(.boolean(true)),
                .break(Token(type: .break, lexeme: "break", line: 2)),
                nil)
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotBreakOutsideLoopOrSwitch
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveBreakStatementFunctionInsideWhileLoop() throws {
        // while (true) {
        //     fun foo() {
        //         break;
        //     }
        //     foo();
        //}
        let statements: [Statement<UnresolvedDepth>] = [
            .while(
                .literal(.boolean(true)),
                .block([
                    .function(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        .lambda(
                            ParameterList(normalParameters: []),
                            [
                                .break(Token(type: .break, lexeme: "break", line: 3))
                            ])),
                    .expression(
                        .call(
                            .variable(
                                Token(type: .identifier, lexeme: "foo", line: 5),
                                UnresolvedDepth()),
                            Token(type: .rightParen, lexeme: ")", line: 5),
                            []))
                ]))
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotBreakOutsideLoopOrSwitch
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveTopLevelExpressionWithSplatOperator() throws {
        // *[1, 2, 3]
        let statements: [Statement<UnresolvedDepth>] = [
            .expression(
                .splat(
                    .list([
                        .literal(.int(1)),
                        .literal(.int(2)),
                        .literal(.int(3)),
                    ])))
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.cannotUseSplatOperatorOutOfContext
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveEnumWithDuplicateCaseNames() throws {
        // enum Color {
        //     case red, green, blue, violet;
        //     case orange, yellow, green, indigo;
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .enum(
                Token(type: .identifier, lexeme: "color", line: 1),
                [
                    Token(type: .identifier, lexeme: "red", line: 2),
                    Token(type: .identifier, lexeme: "green", line: 2),
                    Token(type: .identifier, lexeme: "blue", line: 2),
                    Token(type: .identifier, lexeme: "violet", line: 2),
                    Token(type: .identifier, lexeme: "orange", line: 3),
                    Token(type: .identifier, lexeme: "yellow", line: 3),
                    Token(type: .identifier, lexeme: "green", line: 3),
                    Token(type: .identifier, lexeme: "indigo", line: 3),
                ],
                [],
                [])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.duplicateCaseNamesNotAllowed(
            Token(type: .identifier, lexeme: "green", line: 3)
        )
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveSwitchWithEmptyBody() throws {
        // switch (42) {
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .switch(.literal(.int(42)), [])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.switchMustHaveAtLeastOneCaseOrDefault
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveSwitchWithEmptyCase() throws {
        // switch (42) {
        // case 42:
        // }
        let statements: [Statement<UnresolvedDepth>] = [
            .switch(
                .literal(.int(42)),
                [
                    SwitchCaseDeclaration(
                        valueExpressions: [
                            .literal(.int(42))
                        ],
                        statement: .block([]))
                ])
        ]

        var resolver = Resolver()
        let expectedError = ResolverError.switchMustHaveAtLeastOneStatementPerCaseOrDefault
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }
}
