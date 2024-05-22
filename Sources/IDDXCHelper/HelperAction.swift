//
//  HelperAction.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

public enum HelperAction: String {
    case updateVersions = "updateVersions"
    case buildCode = "buildCode"
    case signCode = "signCode"
    case notarizePackage = "notarizePackage"
    case updateSparkle = "updateSparkle"
    case createPackage = "createPackage"
    case packageTips = "packageTips"

    case notarizeApp = "notarizeApp"
    case notarizeDMG = "notarizeDMG"
}
