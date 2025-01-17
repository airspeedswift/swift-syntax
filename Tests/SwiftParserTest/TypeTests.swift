//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(RawSyntax) import SwiftSyntax
@_spi(RawSyntax) import SwiftParser
import XCTest

final class TypeTests: XCTestCase {

  func testMissingColonInType() {
    AssertParse(
      """
      var foo 1️⃣Bar = 1
      """,
      diagnostics: [
        DiagnosticSpec(message: "expected ':' in type annotation")
      ]
    )
  }

  func testClosureParsing() {
    AssertParse(
      "(a, b) -> c",
      { TypeSyntax.parse(from: &$0) }
    )

    AssertParse(
      "@MainActor (a, b) async throws -> c",
      { TypeSyntax.parse(from: &$0) }
    )

    AssertParse("() -> (\u{feff})")
  }

  func testGenericTypeWithTrivia() {
    // N.B. Whitespace is significant here.
    AssertParse(
      """
              Foo<Bar<
                  V, Baz<Quux>
              >>
      """,
      { TypeSyntax.parse(from: &$0) }
    )
  }

  func testFunctionTypes() {
    AssertParse(
      "t as(1️⃣..)->2️⃣",
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "expected type in function type"),
        DiagnosticSpec(locationMarker: "1️⃣", message: "unexpected code '..' in function type"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "expected type in function type"),
      ]
    )
  }

  func testClosureSignatures() {

    AssertParse(
      """
      simple { [] str in
        print("closure with empty capture list")
      }
      """
    )

    AssertParse(
      """
      { ()
      throws -> Void in }
      """,
      { ExprSyntax.parse(from: &$0) }
    )

    AssertParse(
      """
      { [weak a, unowned(safe) self, b = 3] (a: Int, b: Int, _: Int) -> Int in }
      """,
      { ExprSyntax.parse(from: &$0) }
    )

    AssertParse(
      "{[1️⃣class]in2️⃣",
      { ExprSyntax.parse(from: &$0) },
      diagnostics: [
        DiagnosticSpec(locationMarker: "1️⃣", message: "expected identifier in closure capture item"),
        DiagnosticSpec(locationMarker: "1️⃣", message: "unexpected 'class' keyword in closure capture signature"),
        DiagnosticSpec(locationMarker: "2️⃣", message: "expected '}' to end closure"),
      ]
    )

    AssertParse(
      "{[n1️⃣`]in}",
      { ExprSyntax.parse(from: &$0) },
      diagnostics: [
        DiagnosticSpec(message: "unexpected code '`' in closure capture signature")
      ]
    )

    AssertParse(
      "{[weak1️⃣^]in}",
      { ExprSyntax.parse(from: &$0) },
      diagnostics: [
        DiagnosticSpec(message: "expected identifier in closure capture item"),
        DiagnosticSpec(message: "unexpected code '^' in closure capture signature"),
      ]
    )
  }

  func testOpaqueReturnTypes() {
    AssertParse(
      """
      public typealias Body = @_opaqueReturnTypeOf("$s6CatKit10pspspspspsV5cmereV6lilguyQrvp", 0) __
      """
    )
  }

  func testVariadics() {
    AssertParse(
      #"""
      func takesVariadicFnWithGenericRet<T>(_ fn: (S...) -> T) {}
      let _: (S...) -> Int = \.i
      let _: (S...) -> Int = \Array.i1️⃣
      let _: (S...) -> Int = \S.i2️⃣
      """#
    )
  }

  func testConvention() {
    AssertParse(
      #"""
      let _: @convention(thin) (@convention(thick) () -> (),
                                @convention(thin) () -> (),
                                @convention(c) () -> (),
                                @convention(c, cType: "intptr_t (*)(size_t)") (Int) -> Int,
                                @convention(block) () -> (),
                                @convention(method) () -> (),
                                @convention(objc_method) () -> (),
                                @convention(witness_method: Bendable) (Fork) -> ()) -> ()
      """#
    )
  }

  func testNamedOpaqueReturnTypes() {
    AssertParse(
      """
      func f2() -> <T: SignedInteger, U: SignedInteger> Int {
      }

      dynamic func lazyMapCollection<C: Collection, T>(_ collection: C, body: @escaping (C.Element) -> T)
          -> <R: Collection where R.Element == T> R {
        return collection.lazy.map { body($0) }
      }

      struct Boom<T: P> {
        var prop1: Int = 5
        var prop2: <U, V> (U, V) = ("hello", 5)
      }
      """
    )
  }
}
