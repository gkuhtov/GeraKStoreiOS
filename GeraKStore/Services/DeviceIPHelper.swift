import Foundation

public enum DeviceIPHelper {
    public static func getLocalIPAddress() -> String {
        var wifiAddress: String?
        var cellAddress: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return "127.0.0.1"
        }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                let ip = String(cString: hostname)

                if name == "en0" && !ip.isEmpty && ip != "127.0.0.1" {
                    wifiAddress = ip
                } else if name.hasPrefix("pdp_ip") && !ip.isEmpty && ip != "127.0.0.1" {
                    cellAddress = ip
                }
            }
        }
        freeifaddrs(ifaddr)

        // 1. Если подключен Wi-Fi — используем его
        if let wifi = wifiAddress {
            return wifi
        }
        // 2. Если мобильная сеть — возвращаем 127.0.0.1 (локальный демон installd обращается к петле)
        return "127.0.0.1"
    }
}
