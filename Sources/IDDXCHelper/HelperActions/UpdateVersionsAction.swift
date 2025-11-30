//
//  UpdateVersionsAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Update all plist versions
 */
public struct UpdateVersionsAction: Sendable {
    public static let type: HelperActionType = .updateVersions
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension UpdateVersionsAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() {
        helper.updateVersions()
    }
}
