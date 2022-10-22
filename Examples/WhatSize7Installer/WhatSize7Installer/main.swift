//
//  main.swift
//  WhatSize7Installer
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
        return URL.iddHomeDirectory.appendingPathComponent("Library/Logs/WhatSize7Installer.log").path
    }
}()

Log4swiftConfig.configureLogs(defaultLogFile: IDDLogLogFileName, lock: "IDDLogLock")

/**
 We need to provide the path to the Project.json for this work
 the trick is to provide a CopyFiles step on the Xcode WhatSize7Installer target
 in there we copy the WhatSize7InstallerConfig, Destination: Executables
 Subpath: config
 This will allow xcode to copy the WhatSize7InstallerConfig on a folder relative to the Bundle.main.executablePath
 Bundle.main.executablePath/../config/WhatSize7InstallerConfig
 which we can than use.
 
 The required actions to create a WhatSize7package are
 -actions "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips"
 You can use any actions you want by passing them to the argument line, this allows for modularity, say you just want to
 -actions "buildCode"
 */

let configURL = Bundle.main.executableURL!
    .deletingLastPathComponent().appendingPathComponent("config/WhatSize7InstallerConfig/Project.json")

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
