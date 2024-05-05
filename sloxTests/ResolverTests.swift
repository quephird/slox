//
//  ResolverTests.swift
//  sloxTests
//
//  Created by Danielle Kefford on 3/3/24.
//

import XCTest

final class ResolverTests: XCTestCase {
    func testResolveLiteralExpression() throws {
        // 42
        let statements: [Statement<UnresolvedDepth>] = [
            .expression(
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .expression(
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42))),
        ]
        XCTAssertEqual(actual, expected)
    }

    func testResolveVariableDeclaration() throws {
        // var answer = 42;
        let statements: [Statement<UnresolvedDepth>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42))),
        ]

        var resolver = Resolver()
        let actual = try resolver.resolve(statements: statements)
        let expected: [Statement<Int>] = [
            .variableDeclaration(
                Token(type: .identifier, lexeme: "answer", line: 1),
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42))),
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
                    Token(type: .identifier, lexeme: "add", line: 1),
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
                    Token(type: .identifier, lexeme: "add", line: 1),
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
                    Token(type: .identifier, lexeme: "answer", line: 1),
                    nil,
                    [
                        .return(
                            Token(type: .return, lexeme: "return", line: 2),
                            .literal(
                                Token(type: .int, lexeme: "42", line: 2),
                                .int(42)))
                    ])),
        ]

        var resolver = Resolver()
        let locToken = Token(type: .identifier, lexeme: "answer", line: 1)
        let expectedError = ResolverError.functionsMustHaveAParameterList(locToken)
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
                    .literal(
                        Token(type: .int, lexeme: "42", line: 1),
                        .int(42))),
            ])
        ]

        var resolver = Resolver()
        let locToken = Token(type: .return, lexeme: "return", line: 1)
        let expectedError = ResolverError.cannotReturnOutsideFunction(locToken)
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveVariableReferencedInItsOwnInitializer() throws {
        // var x = "outer";
        // {
        //     var x = x;
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
        let locToken = Token(type: .identifier, lexeme: "x", line: 3)
        let expectedError = ResolverError.variableAccessedBeforeInitialization(locToken)
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
        let nameToken = Token(type: .identifier, lexeme: "a", line: 3)
        let expectedError = ResolverError.variableAlreadyDefined(nameToken)
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
                            Token(type: .identifier, lexeme: "sayName", line: 2),
                            ParameterList(normalParameters: []),
                            [
                                .print(
                                    .get(
                                        Token(type: .dot, lexeme: ".", line: 3),
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
                            Token(type: .identifier, lexeme: "sayName", line: 2),
                            ParameterList(normalParameters: []),
                            [
                                .print(
                                    .get(
                                        Token(type: .dot, lexeme: ".", line: 3),
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
                    Token(type: .identifier, lexeme: "foo", line: 1),
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
        let locToken = Token(type: .this, lexeme: "this", line: 2)
        let expectedError = ResolverError.cannotReferenceThisOutsideClass(locToken)
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
                            Token(type: .identifier, lexeme: "init", line: 2),
                            ParameterList(normalParameters: []),
                            [
                                .return(
                                    Token(type: .return, lexeme: "return", line: 3),
                                    .literal(
                                        Token(type: .int, lexeme: "42", line: 3),
                                        .int(42)))
                            ]))
                ],
                [])
        ]

        var resolver = Resolver()
        let locToken = Token(type: .return, lexeme: "return", line: 3)
        let expectedError = ResolverError.cannotReturnValueFromInitializer(locToken)
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
                            Token(type: .identifier, lexeme: "add", line: 2),
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
                            Token(type: .identifier, lexeme: "add", line: 2),
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
                            Token(type: .identifier, lexeme: "init", line: 2),
                            ParameterList(normalParameters: []),
                            [
                                .expression(
                                    .set(
                                        Token(type: .dot, lexeme: ".", line: 3),
                                        .this(
                                            Token(type: .this, lexeme: "this", line: 3),
                                            UnresolvedDepth()),
                                        Token(type: .identifier, lexeme: "name", line: 3),
                                        .string(Token(type: .string, lexeme: "\"bad\"", line: 1))))
                            ]))
                ])
        ]

        var resolver = Resolver()
        let nameToken = Token(type: .identifier, lexeme: "init", line: 2)
        let expectedError = ResolverError.staticInitsNotAllowed(nameToken)
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
        let locToken = Token(type: .super, lexeme: "super", line: 1)
        let expectedError = ResolverError.cannotReferenceSuperOutsideClass(locToken)
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
                            Token(type: .identifier, lexeme: "someMethod", line: 2),
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
        let locToken = Token(type: .super, lexeme: "super", line: 3)
        let expectedError = ResolverError.cannotReferenceSuperWithoutSubclassing(locToken)
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
                Token(type: .if, lexeme: "if", line: 1),
                .literal(
                    Token(type: .true, lexeme: "true", line: 1),
                    .boolean(true)),
                .break(Token(type: .break, lexeme: "break", line: 2)),
                nil)
        ]

        var resolver = Resolver()
        let locToken = Token(type: .break, lexeme: "break", line: 2)
        let expectedError = ResolverError.cannotBreakOutsideLoopOrSwitch(locToken)
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
                .literal(
                    Token(type: .true, lexeme: "true", line: 1),
                    .boolean(true)),
                .block([
                    .function(
                        Token(type: .identifier, lexeme: "foo", line: 2),
                        .lambda(
                            Token(type: .identifier, lexeme: "foo", line: 2),
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
        let locToken = Token(type: .break, lexeme: "break", line: 3)
        let expectedError = ResolverError.cannotBreakOutsideLoopOrSwitch(locToken)
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }

    func testResolveTopLevelExpressionWithSplatOperator() throws {
        // *[1, 2, 3]
        let statements: [Statement<UnresolvedDepth>] = [
            .expression(
                .splat(
                    Token(type: .star, lexeme: "*", line: 1),
                    .list(
                        Token(type: .leftBracket, lexeme: "[", line: 1),
                        [
                            .literal(
                                Token(type: .int, lexeme: "1", line: 1),
                                .int(1)),
                            .literal(
                                Token(type: .int, lexeme: "2", line: 1),
                                .int(2)),
                            .literal(
                                Token(type: .int, lexeme: "3", line: 1),
                                .int(3)),
                        ])))
        ]

        var resolver = Resolver()
        let locToken = Token(type: .star, lexeme: "*", line: 1)
        let expectedError = ResolverError.cannotUseSplatOperatorOutOfContext(locToken)
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
            .switch(
                Token(type: .switch, lexeme: "switch", line: 1),
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42)),
                [])
        ]

        var resolver = Resolver()
        let locToken = Token(type: .switch, lexeme: "switch", line: 1)
        let expectedError = ResolverError.switchMustHaveAtLeastOneCaseOrDefault(locToken)
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
                Token(type: .switch, lexeme: "switch", line: 1),
                .literal(
                    Token(type: .int, lexeme: "42", line: 1),
                    .int(42)),
                [
                    SwitchCaseDeclaration(
                        caseToken: Token(type: .case, lexeme: "case", line: 2),
                        valueExpressions: [
                            .literal(
                                Token(type: .int, lexeme: "42", line: 2),
                                .int(42))
                        ],
                        statement: .block([]))
                ])
        ]

        var resolver = Resolver()
        let locToken = Token(type: .case, lexeme: "case", line: 2)
        let expectedError = ResolverError.switchMustHaveAtLeastOneStatementPerCaseOrDefault(locToken)
        XCTAssertThrowsError(try resolver.resolve(statements: statements)) { actualError in
            XCTAssertEqual(actualError as! ResolverError, expectedError)
        }
    }
}
