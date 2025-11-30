//
//  SignCodeAction.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 11/29/25.
//

import Foundation
import IDDSwift
import Log4swift

/**
 Sign all code
 */
public struct SignCodeAction: Sendable {
    public static let type: HelperActionType = .signCode
    let helper: Helper

    public init?() {
        guard UserDefaults.hasActionType(Self.type),
              let helper = HelperActionTypeFactory.helper
        else { return nil }

        self.helper = helper
    }
}

extension SignCodeAction: HelperAction {
    public var type: HelperActionType {
        Self.type
    }

    public func runCommand() async {
        helper.signCode()
    }
}
