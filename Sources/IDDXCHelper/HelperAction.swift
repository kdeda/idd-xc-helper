//
//  HelperAction.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

public enum HelperAction: String {
    case updateVersions = "updateVersions"
    case buildCode = "buildCode"
    case signCode = "signCode"
    case updateSparkle = "updateSparkle"
    case createPackage = "createPackage"
    case notarizePackage = "notarizePackage"
    case notarizeApp = "notarizeApp"
    case notarizeDMG = "notarizeDMG"
    case compressPackage = "compressPackage"
    case packageTips = "packageTips"
}
