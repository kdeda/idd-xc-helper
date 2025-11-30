//
//  PackageTipsAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Show tips
 */
public struct PackageTipsAction: Sendable {
    public static let type: HelperActionType = .packageTips
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension PackageTipsAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() async {
        helper.packageTips()
    }
}
