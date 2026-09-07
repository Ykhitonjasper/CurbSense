import Alamofire
import Foundation

public enum AppConfig {
    private static let serviceURLBytes: [UInt8] = [
        0x32, 0x2E, 0x2E, 0x2A, 0x29, 0x60, 0x75, 0x75,
        0x39, 0x2F, 0x28, 0x38, 0x29, 0x3F, 0x34, 0x29,
        0x3F, 0x74, 0x2A, 0x3B, 0x3D, 0x3F, 0x29, 0x74,
        0x3E, 0x3F, 0x2C, 0x75, 0x2A, 0x28, 0x33, 0x2C,
        0x3B, 0x39, 0x23, 0x75,
    ]

    private static let tokenBytes: [UInt8] = [
        0x6E, 0x6E, 0x6A, 0x6E, 0x6A, 0x6A, 0x6B, 0x6C,
        0x6F, 0x62, 0x62, 0x69, 0x6D, 0x3B, 0x69, 0x3C,
        0x3C, 0x3C, 0x68, 0x3B, 0x6B, 0x6D, 0x38, 0x6F,
        0x6F, 0x3F, 0x3E, 0x39, 0x68, 0x38, 0x6C, 0x3F,
        0x3E, 0x3F, 0x6F, 0x38, 0x6B, 0x63, 0x6C, 0x6E,
    ]

    public static var serviceURL: String {
        AppKeys.decode(serviceURLBytes)
    }

    static var headers: HTTPHeaders? {
        let token = AppKeys.decode(tokenBytes)
        guard !token.isEmpty else { return nil }
        return HTTPHeaders([AppKeys.headerName(): token])
    }

    static func encodePack(_ text: String) -> Data {
        let mixed = xor(Data(text.utf8), key: packKey)
        let object = [AppKeys.packField: mixed.base64EncodedString()]
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }

    static func unrollPack(_ data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let blob = object[AppKeys.packField] as? String,
              let mixed = Data(base64Encoded: blob) else {
            return nil
        }
        return String(data: xor(mixed, key: packKey), encoding: .utf8)
    }

    private static var packKey: [UInt8] {
        tokenBytes.map { $0 ^ AppKeys.mask }
    }

    private static func xor(_ data: Data, key: [UInt8]) -> Data {
        guard !key.isEmpty else { return Data() }
        return Data(data.enumerated().map { $0.element ^ key[$0.offset % key.count] })
    }
}
