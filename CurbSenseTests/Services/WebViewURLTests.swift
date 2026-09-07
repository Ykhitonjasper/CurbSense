import XCTest
@testable import CurbSense

final class WebViewControllerURLTests: XCTestCase {
    func testAttributionQuerySurvivesUnchanged() {
        let raw = "https://example.test/v3/path/?sub1=6a918336a256a10001818e1b&p=p1ee"

        XCTAssertEqual(WebViewController.resolveURL(from: raw)?.absoluteString, raw)
    }

    func testEncodedParameterIsNotUnwrapped() {
        let raw = "https://example.test/v3/path/?sub1=a%2Bb%3D&back=https%3A%2F%2Ffoo.test%2Fx"

        XCTAssertEqual(WebViewController.resolveURL(from: raw)?.absoluteString, raw)
    }

    func testFullyEncodedLinkIsStillDecoded() {
        let raw = "https%3A%2F%2Fexample.test%2Fv3%2Fpath%2F%3Fsub1%3Dabc"

        XCTAssertEqual(
            WebViewController.resolveURL(from: raw)?.absoluteString,
            "https://example.test/v3/path/?sub1=abc"
        )
    }

    func testEmptyStringIsRejected() {
        XCTAssertNil(WebViewController.resolveURL(from: ""))
    }
}
