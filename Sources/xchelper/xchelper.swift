//
//  xchelper.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//

import Foundation
import Log4swift
import SwiftCommons

@main
public struct xchelper {
    let configName: String
    let helper: Helper
    let actions: [HelperAction]
    
    private static func IDDLogLogFileName() -> String? {
        if UserDefaults.standard.bool(forKey: "standardLog") {
            Log4swift.getLogger("main").info("Starting as normal process (not a daemon) ...")
            return nil
        } else {
            Log4swift.getLogger("main").info("Starting as daemon ...")
            return URL.iddHomeDirectory.appendingPathComponent("Library/Logs/xchelper.log").path
        }
    }
    
    init() {
        self.configName = UserDefaults.standard.string(forKey: "configName") ?? "WhatSize7"
        self.helper = Helper(configName: configName)
        self.actions = (UserDefaults.standard.string(forKey: "actions") ?? "unknown")
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ",")
            .compactMap(HelperAction.init(rawValue:))
    }
    
    public static func main() {
        Log4swiftConfig.configureLogs(defaultLogFile: IDDLogLogFileName(), lock: "IDDLogLock")
        var totalElapsedTimeInMilliseconds = 0.0
        let xchelper = xchelper()
        
        xchelper.actions.forEach { action in
            let startDate = Date()
            
            Log4swift["main"].info("--------------------------------")
            _ = xchelper.helper.handleAction(action)
            let elapsedTimeInMilliseconds = startDate.elapsedTimeInMilliseconds
            
            totalElapsedTimeInMilliseconds += elapsedTimeInMilliseconds
            let elapsedInSeconds = Date.elapsedTime(from: elapsedTimeInMilliseconds)
            let totalElapsedInSeconds = Date.elapsedTime(from: totalElapsedTimeInMilliseconds)
            Log4swift["main"].info("action: '\(action)' completed in: '\(elapsedInSeconds) ms' total: '\(totalElapsedInSeconds)'\n")
        }
        
        Log4swift["main"].info("completed in: '\((totalElapsedTimeInMilliseconds / 1000.0).with3Digits) seconds'\n")
    }
}
