//
//  main.swift
//  xchelper
//
//  Created by Klajd Deda on 10/22/22.
//

import Foundation
import Log4swift
import XCSwiftHelper

fileprivate let IDDLogLogFileName: String? = {
    if UserDefaults.standard.bool(forKey: "standardLog") {
        Log4swift.getLogger("main").info("Starting as normal process (not a daemon) ...")
        return nil
    } else {
        Log4swift.getLogger("main").info("Starting as daemon ...")
        return URL.iddHomeDirectory.appendingPathComponent("Library/Logs/xchelper.log").path
    }
}()

Log4swiftConfig.configureLogs(defaultLogFile: IDDLogLogFileName, lock: "IDDLogLock")

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

fileprivate let config = UserDefaults.standard.string(forKey: "config") ?? ""
guard !config.isEmpty
else {
    let toolName = Bundle.main.executableURL!.lastPathComponent

    Log4swift["main"].info("usage: '\(toolName) -config WhatSize7'")
    Log4swift["main"].info("       where WhatSize7 should be a valid name.")
    exit(0)
}

fileprivate let projectURL = Bundle.main.executableURL!
    .deletingLastPathComponent().appendingPathComponent("config/\(config)/Project.json")
guard projectURL.fileExist
else {
    let toolName = Bundle.main.executableURL!.lastPathComponent

    Log4swift["main"].info("usage: '\(toolName) -config WhatSize7'")
    Log4swift["main"].info("       where WhatSize7 should be a valid name.")
    exit(0)
}

Log4swift["main"].info("--------------------------------")
Log4swift["main"].info("-config '\(config)' projectURL: '\(projectURL.path)'")

/// make sure we have full disk access
fileprivate let output = Process.fetchString(taskURL: URL(fileURLWithPath: "/bin/date"), arguments: [])
guard !output.isEmpty,
      FileManager.default.hasFullDiskAccess
else {
    Log4swift["main"].info("Please give this tool Full Disk Access and try again")
    Log4swift["main"].info("    open x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    Log4swift["main"].info("    open \(Bundle.main.executableURL!.deletingLastPathComponent().path)")
    Log4swift["main"].info("    and add \(Bundle.main.executableURL!.path) to the list of allowed binaries")
    exit(0)
}


fileprivate let actions = (UserDefaults.standard.string(forKey: "actions") ?? "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips")
    .replacingOccurrences(of: " ", with: "")
    .components(separatedBy: ",")
    .compactMap(HelperAction.init(rawValue:))

fileprivate let helper = Helper(configURL: projectURL)
fileprivate var totalElapsedTimeInMilliseconds = 0.0

actions.forEach { helperAction in
    let startDate = Date()
    
    Log4swift["main"].info("--------------------------------")
    _ = helper.handleAction(helperAction)
    let elapsedTimeInMilliseconds = startDate.elapsedTimeInMilliseconds
    
    totalElapsedTimeInMilliseconds += elapsedTimeInMilliseconds
    let elapsedInSeconds = Date.elapsedTime(from: elapsedTimeInMilliseconds)
    let totalElapsedInSeconds = Date.elapsedTime(from: totalElapsedTimeInMilliseconds)
    Log4swift["main"].info("action: '\(helperAction)' completed in: '\(elapsedInSeconds) ms' total: '\(totalElapsedInSeconds)'\n")
}

Log4swift["main"].info("completed in: '\((totalElapsedTimeInMilliseconds / 1000.0).with3Digits) seconds'\n")
