//
//  Tool.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 10/25/22.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public struct Tool {
    private var toolName: String
    private var knownConfigs: [String]
    private var config: String
    public var projectURL: URL

    /**
     We need to provide the path to the Project.json for this work
     The trick here is to provide a CopyFiles step on the Xcode xchelper target
     where we copy the WhatSize7, Destination: Executables
     Subpath: config
     This will allow xcode to copy the WhatSize7 on a folder relative to the Bundle.main.executablePath
     Bundle.main.executablePath/../config/WhatSize7
     which we can than use.

     This is a convenience and keeps the configs well formed inside this app.
     Yes we could keep the configs outside scatered in the file system, but
     this enforces more encapsulation.

     The required actions to create a WhatSize7package are
     -actions "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips"
     You can use any actions you want by passing them to the argument line, this allows for modularity, say you just want to
     -actions "buildCode"
     */
    public init?(knownConfigs: [String]) {
        let config = UserDefaults.standard.string(forKey: "config") ?? ""
        guard knownConfigs.contains(config)
        else {
            Log4swift[Self.self].error("you provided an invalid config value: '\(config)'")
            Log4swift[Self.self].error("valid configs are: '\(knownConfigs.joined(separator: " | "))'")
            return nil
        }

        let projectURL = Bundle.main.executableURL!
            .deletingLastPathComponent().appendingPathComponent("config/\(config)/Project.json")
        guard projectURL.fileExist
        else {
            Log4swift[Self.self].error("we could not find: '\(projectURL.path)'")
            return nil
        }

        Log4swift[Self.self].dash("-config '\(config)' projectURL: '\(projectURL.path)'")
        Log4swift[Self.self].info("-config '\(config)' projectURL: '\(projectURL.path)'")

        /// make sure we have full disk access
        guard FileManager.default.hasFullDiskAccess
        else {
            FileManager.default.hasFullDiskAccessTips()
            return nil
        }

        self.toolName = Bundle.main.executableURL!.lastPathComponent
        self.knownConfigs = knownConfigs
        self.config = UserDefaults.standard.string(forKey: "config") ?? ""
        self.projectURL = projectURL
    }
}
