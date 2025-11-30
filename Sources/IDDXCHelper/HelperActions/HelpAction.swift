//
//  HelpAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Print help
 */
public struct HelpAction: Sendable {
    public static let type: HelperActionType = .help

    public init?() {
        guard UserDefaults.hasActionType(Self.type)
        else { return nil }
    }

    public init(safe: Bool) {
    }
}

extension HelpAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() {
        let actions = HelperActionType.allCases
            .sorted(by: { $0.sortIndex < $1.sortIndex })
            .map(\.rawValue)
            .joined(separator: " | ")

        Log4swift.log("""
            usage: -actions [\(actions)] -config [WhatSize7 | WhatSize8 | SupportWhatSize]
        
        """)
    }
}
