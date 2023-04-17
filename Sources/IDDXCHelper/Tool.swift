//
//  Tool.swift
//  xchelper
//
//  Created by Klajd Deda on 10/25/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public struct Tool {
    private var toolName: String
    private var knownConfigs: [String]
    private var config: String
    public var projectURL: URL

    public init(knownConfigs: [String]) {
        self.toolName = Bundle.main.executableURL!.lastPathComponent
        self.knownConfigs = knownConfigs
        self.config = UserDefaults.standard.string(forKey: "config") ?? ""

        // stick a dummy value, this will be replaced by the validate()
        self.projectURL = FileManager.default.temporaryDirectory

        validate(projectURL: &projectURL)
    }

    private func validate(projectURL: inout URL) {
        Log4swift.configure(appName: toolName)

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

        let config = UserDefaults.standard.string(forKey: "config") ?? ""
        guard knownConfigs.contains(config)
        else {
            let toolName = Bundle.main.executableURL!.lastPathComponent

            Log4swift["main"].info("usage: '\(toolName) -config [\(knownConfigs.joined(separator: " | "))]'")
            Log4swift["main"].info("       you provided an invalid config value: '\(config)'")
            Log4swift["main"].info("       valid configs are: '\(knownConfigs.joined(separator: " | "))'")
            exit(0)
        }

        projectURL = Bundle.main.executableURL!
            .deletingLastPathComponent().appendingPathComponent("config/\(config)/Project.json")
        guard projectURL.fileExist
        else {
            let toolName = Bundle.main.executableURL!.lastPathComponent

            Log4swift["main"].info("usage: '\(toolName) -config [\(knownConfigs.joined(separator: " | "))]'")
            Log4swift["main"].info("       valid configs are: '\(knownConfigs.joined(separator: " | "))'")
            exit(0)
        }

        Log4swift["main"].info("--------------------------------")
        Log4swift["main"].info("-config '\(config)' projectURL: '\(projectURL.path)'")

        /// make sure we have full disk access
        let output = Process.fetchString(taskURL: URL(fileURLWithPath: "/bin/date"), arguments: [])
        guard !output.isEmpty,
              FileManager.default.hasFullDiskAccess
        else {
            exit(0)
        }
    }
}
