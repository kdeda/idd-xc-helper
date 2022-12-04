//
//  ConfigItem.swift
//  xchelper
//
//  Created by Klajd Deda on 4/12/20.
//

import Foundation
import Log4swift
import SwiftCommons

extension Project {
    init?(configURL: URL) {
        guard configURL.fileExist
        else {
            Log4swift[Self.self].error("missing path: '\(configURL.path)'")
            return nil
        }

        let data = Data.init(withURL: configURL)

        do {
            var project = try JSONDecoder().decode(Project.self, from: data)

            project.configURL = configURL.deletingLastPathComponent()
            project.buildProductsURL = project.buildProductsURL.expandingTilde!
            project.infoPlistFiles = project.infoPlistFiles.map { $0.expandingTilde! }
            project.packageRootURL = project.packageRootURL.expandingTilde!
            project.productFiles = project.productFiles.map { productFile in
                var rv = productFile
                
                rv.buildProductsURL = project.buildProductsURL
                return rv.expandingTilde
            }
            project.sparkle.releaseURL = project.sparkle.releaseURL.expandingTilde!
            project.workspaces = project.workspaces.map { $0.expandingTilde }
            self = project
            Log4swift[Self.self].info("loaded project: '\(project.configName)' from: '\(configURL.path)'")
        } catch {
            Log4swift[Self.self].error("json: '\(String(data: data, encoding: .utf8) ?? "unknown")'")
            Log4swift[Self.self].error("error: '\(error)'")
            return nil
        }
    }

    var distributionURL: URL {
        let distributionURL = configURL.appendingPathComponent("distribution.xml")

        do {
            let current = try String(contentsOf: distributionURL, encoding: .utf8)
            let modified = current
                .replacingOccurrences(of: "$title_placeholder", with: "Install \(packageName) \(versionInfo.bundleShortVersionString)")
                .replacingOccurrences(of: "$bundleIdentifier_placeholder", with: "\(packageIdentifier)")
                .replacingOccurrences(of: "$bundleShortVersionString_placeholder", with: "\(versionInfo.bundleShortVersionString)")

            if current != modified {
                let pathExtension = distributionURL.pathExtension
                let projectName = distributionURL.deletingPathExtension().lastPathComponent + "_build_\(versionInfo.bundleShortVersionString)"
                let rv = FileManager.default
                    .temporaryDirectory
                    .appendingPathComponent("\(configName)_\(projectName)")
                    .appendingPathExtension(pathExtension)
                
                _ = FileManager.default.removeItemIfExist(at: rv)
                try modified.write(to: rv, atomically: true, encoding: .utf8)

                Log4swift[Self.self].info("created distributionURL: '\(rv.path)'")
                return rv
            }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        return distributionURL
    }
}

// MARK: - Project (Installer) -
extension Project {
    var username: String {
        if packageIdentifier.hasPrefix("com.id-design") {
            return "kdeda@mac.com"
        } else if packageIdentifier.hasPrefix("com.other") {
            return "clyde@other.com"
        }
        return "kdeda@mac.com"
    }
    
    var password: String {
        if packageIdentifier.hasPrefix("com.id-design") {
            return "@keychain:GATEKEEPER_IDD"
        } else if packageIdentifier.hasPrefix("com.other") {
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
        if packageIdentifier.hasPrefix("com.id-design") {
            return "KlajdDeda13114586"
        } else if packageIdentifier.hasPrefix("com.other") {
            return "OtherCorpInc"
        }
        return "KlajdDeda13114586"
    }
}
