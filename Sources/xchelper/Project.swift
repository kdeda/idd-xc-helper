//
//  ConfigItem.swift
//  xchelper
//
//  Created by Klajd Deda on 4/12/20.
//

import Foundation
import Log4swift
import SwiftCommons

// MARK: - Project -
struct Project: Codable {
    let configName: String
    let bundleGetInfoString: String
    let bundleShortVersionString: String
    let bundleVersion: String
    let bundleIdentifier: String
    let humanReadableCopyright: String
    let infoPlistFiles: [String]
    let packageName: String
    let entitlementsFile: String
    let productFilesToSign: [String]
    let productFiles: [[String: String]]
    let workspaces: [[String: String]]
    let pathToConfig: URL
    
    var majorBundleVersion: String { return bundleShortVersionString.components(separatedBy: ".")[0] }
    var pathToTGZ: URL { return Config.PACKAGE_BASE.appendingPathComponent(packageName).appendingPathExtension("tgz") }
    // created first, raw
    var pathToPKGUnsigned: URL { return Config.PACKAGE_BASE.appendingPathComponent("\(packageName)Unsigned").appendingPathExtension("pkg")}
    // created with extras from distribution.xml
    var pathToPKGAdorned: URL { return Config.PACKAGE_BASE.appendingPathComponent("\(packageName)Adorned").appendingPathExtension("pkg")}
    // created if we sign the pathToPKGAdorned
    var pathToPKG: URL { return Config.PACKAGE_BASE.appendingPathComponent(packageName).appendingPathExtension("pkg") }
}

// MARK: - Project -
extension Project {
    var distributionURL: URL {
        let projectURL = Config.SRIPTS_ROOT
            .appendingPathComponent(configName)
            .appendingPathComponent("distribution")
            .appendingPathExtension("xml")
        
        do {
            let current = try String(contentsOf: projectURL, encoding: .utf8)
            let modified = current
                .replacingOccurrences(of: "title_replaceable", with: "Install \(packageName) \(bundleShortVersionString)")
                .replacingOccurrences(of: "bundleIdentifier_replaceable", with: "\(bundleIdentifier)")
                .replacingOccurrences(of: "bundleShortVersionString_replaceable", with: "\(bundleShortVersionString)")

            if current != modified {
                let pathExtension = projectURL.pathExtension
                let projectName = projectURL.deletingPathExtension().lastPathComponent + "_build_\(bundleShortVersionString)"
                let rv = projectURL.deletingLastPathComponent().appendingPathComponent(projectName).appendingPathExtension(pathExtension)
                
                _ = FileManager.default.removeItemIfExist(at: rv)
                try modified.write(to: rv, atomically: true, encoding: .utf8)
                return rv
            }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        return projectURL
    }

    // update the info.plist, save it if there are changes
    public func updateInfo(at plistURL: URL) {
        guard let existing = NSMutableDictionary(contentsOf: plistURL)
        else {
            Log4swift[Self.self].error("failed to load plist from: '\(plistURL.path)'")
            return
        }

        let newValue = NSMutableDictionary(dictionary: existing)
        
        newValue["CFBundleGetInfoString"] = "\(bundleShortVersionString), \(bundleGetInfoString)"
        newValue["CFBundleShortVersionString"] = bundleShortVersionString
        newValue["CFBundleVersion"] = bundleVersion
        newValue["NSHumanReadableCopyright"] = humanReadableCopyright
        
        guard newValue != existing
        else { return }
        do {
            try newValue.write(to: plistURL)
            Log4swift[Self.self].info("saved: '\(plistURL.path)'")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
    }
    
    public func updateVersions() {
        infoPlistFiles
            .map(URL.init(fileURLWithPath:))
            .forEach(updateInfo(at:))
    }
}

// MARK: - Project (Installer) -
extension Project {
    var username: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return "kdeda@mac.com"
        } else if bundleIdentifier.hasPrefix("com.other") {
            return "clyde@other.com"
        }
        return "kdeda@mac.com"
    }
    
    var password: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return "@keychain:GATEKEEPER_IDD"
        } else if bundleIdentifier.hasPrefix("com.other") {
            return "@keychain:GATEKEEPER_OTHER"
        }
        return "@keychain:GATEKEEPER_IDD"
    }
    
    // figure it out
    // /usr/bin/xcrun altool --list-providers --username clyde@other.com --password @keychain:GATEKEEPER_OTHER
    // /usr/bin/xcrun altool --list-providers --username kdeda@mac.com --password @keychain:GATEKEEPER_IDD
    // use the ProviderShortname
    //
    var ascProvider: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return "KlajdDeda13114586"
        } else if bundleIdentifier.hasPrefix("com.other") {
            return "OtherCorpInc"
        }
        return "KlajdDeda13114586"
    }
    
    var notarytoolProfileName: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return "GATEKEEPER_IDD_PROFILE"
        } else if bundleIdentifier.hasPrefix("com.other") {
            return ""
        }
        return ""
    }
    
    var certificateApplication: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return Config.CERTIFICATE_APPLICATION_GATEKEEPER_IDD
        } else if bundleIdentifier.hasPrefix("com.other.app") {
            return Config.CERTIFICATE_APPLICATION_GATEKEEPER_OTHER
        }
        return Config.CERTIFICATE_APPLICATION_GATEKEEPER_IDD
    }
    
    var certificateInstaller: String {
        if bundleIdentifier.hasPrefix("com.id-design") {
            return Config.CERTIFICATE_INSTALLER_GATEKEEPER_IDD
        } else if bundleIdentifier.hasPrefix("com.other") {
            return Config.CERTIFICATE_INSTALLER_GATEKEEPER_OTHER
        }
        return Config.CERTIFICATE_INSTALLER_GATEKEEPER_IDD
    }
}

// MARK: - JSONDecoder -
extension JSONDecoder {
    static var prettyDecoder: JSONDecoder {
        return JSONDecoder()
    }
    
    static func decode<T: Decodable>(
        _ data: Data,
        _ decoder: JSONDecoder = .prettyDecoder
    ) -> T? {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Log4swift[Self.self].error("json: '\(String(data: data, encoding: .utf8) ?? "unknown")'")
            Log4swift[Self.self].error("error: '\(error)'")
        }
        return nil
    }
}

// MARK: - JSONEncoder -
extension JSONEncoder {
    static var prettyEncoder: JSONEncoder {
        let rv = JSONEncoder()
        rv.outputFormatting = .prettyPrinted
        return rv
    }
    
    static func encode<T: Encodable>(
        _ value: T,
        _ encoder: JSONEncoder = .prettyEncoder
    ) -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            Log4swift[Self.self].error("json.objects: '\(self)'")
            Log4swift[Self.self].error("error: '\(error)'")
        }
        return Data()
    }
}
