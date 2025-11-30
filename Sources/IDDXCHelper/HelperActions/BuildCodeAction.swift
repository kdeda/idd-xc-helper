//
//  BuildCodeAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Build all code
 */
public struct BuildCodeAction: Sendable {
    public static let type: HelperActionType = .buildCode
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension BuildCodeAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() async {
        await helper.buildCode()
    }
}
