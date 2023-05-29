//
//  RemoteConfigManager.swift
//  SleepSentry
//
//  Created by Selina on 17/5/2023.
//

import Foundation
import FirebaseRemoteConfig

extension RemoteConfigFetcher {
    class func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        debugPrint(items, separator: separator, terminator: terminator)
    }
}

public extension RemoteConfigFetcher {
    static let didUpdatedConfig = Notification.Name("RemoteConfigFetcherDidUpdatedConfig")
}

public class RemoteConfigFetcher {
    public static let shared = RemoteConfigFetcher()
    
    private var remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()
    
    private lazy var defaultJSONDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private init() {}
    
    public func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(onActiveAction), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        #if DEBUG
        settings.minimumFetchInterval = 0
        #endif
        remoteConfig.configSettings = settings
        
        remoteConfig.setDefaults(fromPlist: "remote_config_defaults")
    }
    
    public func fetch() {
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                RemoteConfigFetcher.log("fetchAndActivate failed: \(error.localizedDescription)")
            }
            
            switch status {
            case .successFetchedFromRemote:
                self.postUpdatedNotification()
            default:
                break
            }
        }
    }
    
    private func postUpdatedNotification() {
        NotificationCenter.default.post(name: RemoteConfigFetcher.didUpdatedConfig, object: nil)
    }
    
    @objc private func onActiveAction() {
        fetch()
    }
}

public extension RemoteConfigFetcher {
    func get<T: Decodable>(forKey key: String, customDecoder: JSONDecoder? = nil) throws -> T {
        let decoder = customDecoder ?? defaultJSONDecoder
        
        let value = remoteConfig.configValue(forKey: key)
        return try decoder.decode(T.self, from: value.dataValue)
    }
}
