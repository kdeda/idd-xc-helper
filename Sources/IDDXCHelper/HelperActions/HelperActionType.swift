//
//  HelperActionType.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation

public enum HelperActionType: String, CaseIterable, Sendable {
    case buildCode = "buildCode"
    case createPackage = "createPackage"
    case notarizeApp = "notarizeApp"
    case notarizeDMG = "notarizeDMG"
    case notarizePackage = "notarizePackage"
    case packageTips = "packageTips"
    case help = "help"
    case signCode = "signCode"
    case toolVersion = "toolVersion"
    case updateSparkle = "updateSparkle"
    case updateVersions = "updateVersions"

    public var sortIndex: Int {
        switch self {
        case .buildCode:       return 2
        case .createPackage:   return 4
        case .notarizeApp:     return 9
        case .notarizeDMG:     return 10
        case .notarizePackage: return 5
        case .packageTips:     return 7
        case .help:            return 98
        case .signCode:        return 3
        case .toolVersion:     return 99
        case .updateSparkle:   return 6
        case .updateVersions:  return 1
        }
    }
}

