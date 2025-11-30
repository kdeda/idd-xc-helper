//
//  ToolVersionAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Print the tool version to the console
 */
public struct ToolVersionAction: Sendable {
    public static let type: HelperActionType = .toolVersion

    public init?() {
        guard UserDefaults.hasActionType(Self.type)
        else { return nil }
    }

    public init(safe: Bool) {
    }
}

extension ToolVersionAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }
    
    public func runCommand() {
        Log4swift.log("""
            \(Self.type.rawValue) | \"\(Bundle.main.appVersion.buildNumber)\"
        
        """)
    }
}
