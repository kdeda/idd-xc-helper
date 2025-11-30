//
//  HelperAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 10/19/22.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation

public protocol HelperAction {
    var type: HelperActionType { get }
    func runCommand() async
}

public extension UserDefaults {
    static func hasActionType(_ type: HelperActionType) -> Bool {
        let actions = (UserDefaults.standard.string(forKey: "actions") ?? "")
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ",")
        return actions.contains(type.rawValue)
    }
}

public struct HelperActionTypeFactory {
    internal static let helper: Helper? = {
        guard let tool = Tool(knownConfigs: ["WhatSize7", "WhatSize8", "SupportWhatSize"])
        else { return .none }

        return Helper(configURL: tool.projectURL)
    }()

    public static var actions: [any HelperAction]? {
        var rv: [any HelperAction] = HelperActionType.allCases.compactMap { type -> HelperAction? in
            switch type {
            case .buildCode:       return BuildCodeAction()
            case .createPackage:   return CreatePackageAction()
            case .notarizeApp:     return NotarizeAppAction()
            case .notarizeDMG:     return NotarizeDMGAction()
            case .notarizePackage: return NotarizePackageAction()
            case .packageTips:     return PackageTipsAction()
            case .help:            return HelpAction()
            case .signCode:        return SignCodeAction()
            case .toolVersion:     return ToolVersionAction()
            case .updateSparkle:   return UpdateSparkleAction()
            case .updateVersions:  return UpdateVersionsAction()
            }
        }

        if rv.isEmpty {
            rv.append(HelpAction(safe: true))
        }

        return rv.sorted(by: { $0.type.sortIndex < $1.type.sortIndex })
    }
}
