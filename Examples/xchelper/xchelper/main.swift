//
//  main.swift
//  xchelper
//
//  Created by Klajd Deda on 10/22/22.
//

import Foundation
import Log4swift
import IDDXCHelper

fileprivate let tool = Tool(knownConfigs: ["WhatSize7"])

fileprivate let actions = (UserDefaults.standard.string(forKey: "actions") ?? "updateVersions, buildCode, signCode, createPackage, notarizePackage, updateSparkle, packageTips")
    .replacingOccurrences(of: " ", with: "")
    .components(separatedBy: ",")
    .compactMap(HelperAction.init(rawValue:))

fileprivate let helper = Helper(configURL: tool.projectURL)
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
