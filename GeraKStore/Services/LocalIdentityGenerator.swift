import Foundation
import Security
import Network

public enum LocalIdentityGenerator {
    public static func createLocalIdentity() -> SecIdentity? {
        let tag = "com.gerakstore.local-tls".data(using: .utf8)!

        let keyParams: [String: Any] = [
            kSecAttrType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecReturnRef as String: true
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyParams as CFDictionary, &error) else {
            return nil
        }

        // Параметры самоподписанного сертификата X.509
        let certParams: [String: Any] = [
            kSecCertificateKeyUsage as String: NSNumber(value: SecKeyUsage.all.rawValue)
        ]

        let subjectName = [
            [kSecAttrCommonName as String: "localhost"]
        ]

        var certError: Unmanaged<CFError>?
        guard let certificate = SecGenerateSelfSignedCertificate(
            subjectName as CFArray,
            certParams as CFDictionary,
            privateKey,
            &certError
        ) else {
            return nil
        }

        // Сохраняем во временный Keychain для связывания в SecIdentity
        let secItemParams: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnPersistentRef as String: true
        ]
        SecItemAdd(secItemParams as CFDictionary, nil)

        let certItemParams: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate,
            kSecAttrLabel as String: "localhost"
        ]
        SecItemAdd(certItemParams as CFDictionary, nil)

        var identityRef: CFTypeRef?
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchItemList as String: [certificate]
        ]

        if SecItemCopyMatching(identityQuery as CFDictionary, &identityRef) == errSecSuccess,
           let identity = identityRef {
            return (identity as! SecIdentity)
        }

        return nil
    }
}
