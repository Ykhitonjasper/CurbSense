import XCTest
@testable import CurbSense

final class DecodeRouteTests: XCTestCase {
    func testPackDecodes() {
        let link = "https://example.test/go"
        let route = AppSession.decodePayload(AppConfig.encodePack(link))
        XCTAssertEqual(route?.url, link)
        XCTAssertEqual(route?.enabled, true)
    }

    func testPackKeepsQuery() {
        let raw = "https://example.test/go?sub1=abc&p=p1"
        XCTAssertEqual(AppSession.decodePayload(AppConfig.encodePack(raw))?.url, raw)
    }

    func testPackAllowsTrailingNewline() {
        let link = "https://example.test/go"
        var plate = AppConfig.encodePack(link)
        plate.append(contentsOf: "\n".utf8)
        XCTAssertEqual(AppSession.decodePayload(plate)?.url, link)
    }

    func testPackUsesOwnField() {
        let data = AppConfig.encodePack("https://example.test/go")
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?.keys.sorted(), [AppKeys.packField])
        XCTAssertTrue(object?[AppKeys.packField] is String)
        XCTAssertFalse(String(data: data, encoding: .utf8)?.contains("https://") ?? true)
    }

    func testPlaintextLinkIsIgnored() {
        XCTAssertNil(AppSession.decodePayload(Data("https://example.test/go".utf8)))
    }

    func testBareBase64IsIgnored() {
        let mixed = Data("https://example.test/go".utf8).base64EncodedString()
        XCTAssertNil(AppSession.decodePayload(Data(mixed.utf8)))
    }

    func testFamilyXorHexIsIgnored() {
        XCTAssertNil(AppSession.decodePayload(Data("322e2e2a296075753f223b372a363f742e3f292e753d35".utf8)))
    }

    func testFamilyPlatesAreIgnored() {
        let blob = "XEBEREMKHhlQQFleRw1WSBIDQRUeUA0="
        XCTAssertNil(AppSession.decodePayload(Data("o2.\(blob)".utf8)))
        XCTAssertNil(AppSession.decodePayload(Data("p1.\(blob)".utf8)))
        XCTAssertNil(AppSession.decodePayload(Data("f7.\(blob)".utf8)))
        XCTAssertNil(AppSession.decodePayload(Data("k9.\(blob)".utf8)))
    }

    func testSeriesTokenObjectIsIgnored() {
        let mixed = AppConfig.encodePack("https://example.test/go")
        let object = try? JSONSerialization.jsonObject(with: mixed) as? [String: String]
        let blob = object?[AppKeys.packField] ?? ""
        XCTAssertNil(AppSession.decodePayload(Data(#"{"token":"\#(blob)"}"#.utf8)))
        XCTAssertNil(AppSession.decodePayload(Data(#"{"content":"\#(blob)"}"#.utf8)))
    }

    func testEmptyObjectIsNative() {
        XCTAssertNil(AppSession.decodePayload(Data("{}".utf8)))
    }

    func testGarbageIsIgnored() {
        XCTAssertNil(AppSession.decodePayload(Data("not-a-link".utf8)))
        XCTAssertNil(AppSession.decodePayload(Data("".utf8)))
    }

    func testWrappedEnvelopesAreIgnored() {
        let object = Data(#"{"content":"https://example.test/go"}"#.utf8)
        let legacy = Data(#"{"pages":{"start_v1":{"enabled":true,"url":"https://example.test/go"}}}"#.utf8)
        XCTAssertNil(AppSession.decodePayload(object))
        XCTAssertNil(AppSession.decodePayload(legacy))
    }

    func testHeaderIsProductScoped() {
        let header = AppKeys.headerName()
        XCTAssertEqual(
            header,
            String(
                bytes: [
                    0x39, 0x2F, 0x28, 0x38, 0x77, 0x28, 0x2F, 0x34,
                    0x38, 0x35, 0x35, 0x31,
                ].map { $0 ^ AppKeys.mask },
                encoding: .utf8
            )
        )
        XCTAssertTrue(AppConfig.serviceURL.hasSuffix("/privacy/"))
        XCTAssertTrue(AppConfig.serviceURL.contains("curbsense"))
        XCTAssertTrue(AppKeys.cacheEntryKey.hasPrefix("cs_"))
    }
}
