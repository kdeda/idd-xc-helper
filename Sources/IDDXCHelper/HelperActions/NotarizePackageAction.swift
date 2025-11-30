//
//  NotarizePackageAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Notarize a pkg build
 */
public struct NotarizePackageAction: Sendable {
    public static let type: HelperActionType = .notarizePackage
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension NotarizePackageAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() async {
        helper.notarizePackage()
    }
}
