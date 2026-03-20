import ExpoModulesCore
import Foundation

final class BonjourBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
  var onService: ((NetService) -> Void)?
  var onServiceLost: ((NetService) -> Void)?
  var onError: ((String) -> Void)?

  private var browser: NetServiceBrowser?
  private var services: [String: NetService] = [:]

  func start(type: String, domain: String) {
    stop()
    let b = NetServiceBrowser()
    b.delegate = self
    browser = b
    b.searchForServices(ofType: type, inDomain: domain)
  }

  func stop() {
    browser?.stop()
    browser?.delegate = nil
    browser = nil

    for (_, s) in services {
      s.stop()
      s.delegate = nil
    }
    services.removeAll()
  }

  func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    services[serviceKey(service)] = service
    service.delegate = self
    service.resolve(withTimeout: 2.0)
  }

  func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    services.removeValue(forKey: serviceKey(service))
    onServiceLost?(service)
  }

  func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    onError?("bonjour_search_failed")
  }

  func netServiceDidResolveAddress(_ sender: NetService) {
    onService?(sender)
  }

  func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
    onError?("bonjour_resolve_failed")
  }

  private func serviceKey(_ s: NetService) -> String {
    return "\(s.name)|\(s.type)|\(s.domain)"
  }
}

public class OpenClawDiscoveryModule: Module {
  private let bonjour = BonjourBrowser()

  public func definition() -> ModuleDefinition {
    Name("OpenClawDiscovery")
    Events("onService", "onServiceLost", "onError")

    Function("start") { (serviceType: String?, domain: String?) in
      let t = (serviceType?.isEmpty == false) ? serviceType! : "_openclaw-gw._tcp."
      let d = (domain?.isEmpty == false) ? domain! : "local."
      bonjour.onService = { [weak self] service in
        self?.sendEvent("onService", self?.buildPayload(service: service, resolved: true) ?? [:] as [String: Any?])
      }
      bonjour.onServiceLost = { [weak self] service in
        self?.sendEvent("onServiceLost", self?.buildPayload(service: service, resolved: false) ?? [:] as [String: Any?])
      }
      bonjour.onError = { [weak self] msg in
        self?.sendEvent("onError", ["message": msg])
      }
      bonjour.start(type: t, domain: d)
    }

    Function("stop") {
      bonjour.stop()
    }
  }

  private func buildPayload(service: NetService, resolved: Bool) -> [String: Any?] {
    var payload: [String: Any?] = [
      "name": service.name,
      "type": service.type,
      "domain": service.domain
    ]

    if resolved {
      let host = service.hostName?.trimmingCharacters(in: .whitespacesAndNewlines)
      if let host, !host.isEmpty { payload["host"] = host }
      if service.port > 0 { payload["port"] = service.port }

      if let addresses = service.addresses {
        let ips = addresses.compactMap { data in
          return ipString(fromSockaddrData: data)
        }
        if !ips.isEmpty { payload["addresses"] = ips }
      }

      if let txtData = service.txtRecordData() {
        let dict = NetService.dictionary(fromTXTRecord: txtData)
        var out: [String: String] = [:]
        for (k, v) in dict {
          if let s = String(data: v, encoding: .utf8) {
            out[k] = s
          }
        }
        if !out.isEmpty { payload["txt"] = out }
      }
    }

    return payload
  }

  private func ipString(fromSockaddrData data: Data) -> String? {
    return data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> String? in
      guard let base = rawBuffer.baseAddress else { return nil }
      let addr = base.assumingMemoryBound(to: sockaddr.self)
      if addr.pointee.sa_family == sa_family_t(AF_INET) {
        let addr4 = base.assumingMemoryBound(to: sockaddr_in.self).pointee
        var a = addr4.sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &a, &buffer, socklen_t(INET_ADDRSTRLEN))
        return String(cString: buffer)
      }
      if addr.pointee.sa_family == sa_family_t(AF_INET6) {
        let addr6 = base.assumingMemoryBound(to: sockaddr_in6.self).pointee
        var a = addr6.sin6_addr
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        inet_ntop(AF_INET6, &a, &buffer, socklen_t(INET6_ADDRSTRLEN))
        return String(cString: buffer)
      }
      return nil
    }
  }
}
