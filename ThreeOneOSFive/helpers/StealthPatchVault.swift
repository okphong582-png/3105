import CommonCrypto
import Foundation

/// Stealth In-Memory Vault for decrypting and resolving game patches
/// All payloads are disguised as system render cache (.dat) on disk and decrypted purely in RAM.
enum StealthPatchVault {
    private static let keyBytes: [UInt8] = [
        0x8E, 0x4A, 0x9B, 0x1F, 0x7C, 0x32, 0xD4, 0x60,
        0x55, 0xBA, 0x23, 0xF1, 0x6E, 0xA7, 0x48, 0x3C,
        0x90, 0x14, 0x77, 0xDF, 0x3A, 0xC5, 0x88, 0x29,
        0xFE, 0x51, 0x0B, 0x72, 0x9D, 0x46, 0xE3, 0x18
    ]

    // In-Memory cache of decrypted projects
    private static var projectCache: [String: PatchProject] = [:]
    private static let cacheLock = NSLock()

    enum ResourceTag: String {
        case aimBody = "cr_a0"
        case aimChest = "cr_a1"
        case aimDrag = "cr_a2"
        case aimMagic = "cr_a3"
        case aimNeck = "cr_a4"
        case modSkin = "cr_s1"
        case modOutfit = "cr_o1"
        case locator = "cr_v1"
        case locatorRed = "cr_v2"
        case esp = "cr_e1"

        var defaultPassword: String? {
            switch self {
            case .locator, .locatorRed, .esp:
                return nil // Unencrypted payload
            default:
                return "YaBao" // Standard internal password
            }
        }
    }

    /// Tải và giải mã gói cấu hình hoàn toàn trên RAM
    static func loadProject(for tag: ResourceTag) -> PatchProject? {
        cacheLock.lock()
        if let cached = projectCache[tag.rawValue] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        guard let encryptedData = readResourceData(tag: tag) else {
            // Fallback trực tiếp cho gói ESP nếu cr_e1.dat chưa sẵn sàng
            if tag == .esp,
               let directData = readDirectFile(name: "Hih", ext: "3105") ?? readDirectFile(name: "hih", ext: "3105"),
               let decoded = try? PatchPackageCodec.decode(directData, password: nil) {
                cacheLock.lock()
                projectCache[tag.rawValue] = decoded.project
                cacheLock.unlock()
                return decoded.project
            }
            log("vault: không tìm thấy resource \(tag.rawValue)")
            return nil
        }

        guard let decryptedRaw = decrypt(data: encryptedData) else {
            log("vault: giải mã thất bại \(tag.rawValue)")
            return nil
        }

        do {
            let decoded = try PatchPackageCodec.decode(decryptedRaw, password: tag.defaultPassword)
            cacheLock.lock()
            projectCache[tag.rawValue] = decoded.project
            cacheLock.unlock()
            return decoded.project
        } catch {
            // Fallback giải mã trực tiếp nếu decode thất bại
            if tag == .esp,
               let directData = readDirectFile(name: "Hih", ext: "3105") ?? readDirectFile(name: "hih", ext: "3105"),
               let decoded = try? PatchPackageCodec.decode(directData, password: nil) {
                cacheLock.lock()
                projectCache[tag.rawValue] = decoded.project
                cacheLock.unlock()
                return decoded.project
            }
            log("vault: decode patch error for \(tag.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    /// Đọc tệp dữ liệu ngụy trang từ Bundle
    private static func readResourceData(tag: ResourceTag) -> Data? {
        // 1. Bundle main
        if let url = Bundle.main.url(forResource: tag.rawValue, withExtension: "dat") {
            return try? Data(contentsOf: url, options: .mappedIfSafe)
        }
        // 2. Application bundle directory
        let bundleURL = Bundle.main.bundleURL
        let directURL = bundleURL.appendingPathComponent("\(tag.rawValue).dat")
        if FileManager.default.fileExists(atPath: directURL.path) {
            return try? Data(contentsOf: directURL, options: .mappedIfSafe)
        }
        // 3. Fallback: documents / app directory
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docURL = docs.appendingPathComponent("\(tag.rawValue).dat")
            if FileManager.default.fileExists(atPath: docURL.path) {
                return try? Data(contentsOf: docURL, options: .mappedIfSafe)
            }
        }
        return nil
    }

    /// Đọc trực tiếp tệp từ Bundle hoặc Documents khi cần thiết
    private static func readDirectFile(name: String, ext: String) -> Data? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return try? Data(contentsOf: url, options: .mappedIfSafe)
        }
        let bundleURL = Bundle.main.bundleURL
        let directURL = bundleURL.appendingPathComponent("\(name).\(ext)")
        if FileManager.default.fileExists(atPath: directURL.path) {
            return try? Data(contentsOf: directURL, options: .mappedIfSafe)
        }
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docURL = docs.appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: docURL.path) {
                return try? Data(contentsOf: docURL, options: .mappedIfSafe)
            }
        }
        return nil
    }

    /// Giải mã trực tiếp trên RAM bằng giải thuật Stream Counter SHA-256
    private static func decrypt(data: Data) -> Data? {
        guard data.count > 16 else { return nil }
        let nonce = data.prefix(16)
        let ciphertext = data.dropFirst(16)

        var plaintext = Data(count: ciphertext.count)
        let keyData = Data(keyBytes)

        ciphertext.withUnsafeBytes { (cipherPtr: UnsafeRawBufferPointer) in
            plaintext.withUnsafeMutableBytes { (plainPtr: UnsafeMutableRawBufferPointer) in
                guard let cipherBase = cipherPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let plainBase = plainPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return
                }

                var counter: UInt32 = 0
                var offset = 0
                let total = ciphertext.count
                var blockInput = Data(capacity: keyData.count + nonce.count + 4)
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

                while offset < total {
                    blockInput.removeAll(keepingCapacity: true)
                    blockInput.append(keyData)
                    blockInput.append(nonce)
                    var counterLE = counter.littleEndian
                    blockInput.append(Data(bytes: &counterLE, count: MemoryLayout<UInt32>.size))

                    blockInput.withUnsafeBytes { (inputPtr: UnsafeRawBufferPointer) in
                        _ = CC_SHA256(inputPtr.baseAddress, CC_LONG(inputPtr.count), &digest)
                    }

                    let chunkSize = min(Int(CC_SHA256_DIGEST_LENGTH), total - offset)
                    for i in 0..<chunkSize {
                        plainBase[offset + i] = cipherBase[offset + i] ^ digest[i]
                    }

                    offset += chunkSize
                    counter += 1
                }
            }
        }
        return plaintext
    }
}
