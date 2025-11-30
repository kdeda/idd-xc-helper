//
//  NotarizeAppAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Notarize an app build
 */
public struct NotarizeAppAction: Sendable {
    public static let type: HelperActionType = .notarizeApp
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension NotarizeAppAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() async {
        helper.notarizeApp()
    }
}
