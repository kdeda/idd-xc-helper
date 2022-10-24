//
//  main.swift
//  xchelper
//
//  Created by Klajd Deda on 10/22/22.
//

import Foundation
import Log4swift
import XCHelper

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
 in there we copy the WhatSize7Config, Destination: Executables
 Subpath: config
 This will allow xcode to copy the WhatSize7Config on a folder relative to the Bundle.main.executablePath
 Bundle.main.executablePath/../config/WhatSize7Config
 which we can than use.
 
 The required actions to create a WhatSize7package are
 -actions "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips"
 You can use any actions you want by passing them to the argument line, this allows for modularity, say you just want to
 -actions "buildCode"
 */

fileprivate let toolName = Bundle.main.executableURL?.lastPathComponent ?? "unknown"
fileprivate let project = UserDefaults.standard.string(forKey: "project") ?? ""

guard !project.isEmpty
else {
    Log4swift["main"].info("usage: '\(toolName) -project pathToProject.json'")
    Log4swift["main"].info("       where pathToProject.json is an absolute path or user relative path to the Project.json for this run")
    exit(0)
}

/// make sure we have full disk access
fileprivate let output = Process.fetchString(taskURL: URL(fileURLWithPath: "/bin/date"), arguments: [])
guard !output.isEmpty,
      FileManager.default.hasFullDiskAccess
else {
    Log4swift["main"].info("usage: '\(toolName)  Pleae correct Full Disk Access and try again")
    Log4swift["main"].info("       open  x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    exit(0)
}

Log4swift["main"].info("--------------------------------")
Log4swift["main"].info("-project '\(project)'")
fileprivate let configURL = URL(string: project)!.expandingTilde!

fileprivate let actions = (UserDefaults.standard.string(forKey: "actions") ?? "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips")
    .replacingOccurrences(of: " ", with: "")
    .components(separatedBy: ",")
    .compactMap(HelperAction.init(rawValue:))

fileprivate let projectJSON = Bundle.main.executablePath
fileprivate let helper = Helper(configURL: configURL)
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
