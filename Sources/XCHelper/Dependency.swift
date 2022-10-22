//
//  Config.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//

import Foundation

/**
 These are executable dependencies that we need to do our job.
 Typically these are installed by xcode or macos.
 */
public struct Dependency {
    static let version = "1.0.0"
    
    // TODO: this is from Stéphane Sudre.pl, not used ...
    // static let PACKAGES = URL(fileURLWithPath: "/usr/local/bin/packagesbuild")
    
    static let PACKAGE_BUILD = URL(fileURLWithPath: "/usr/bin/pkgbuild")
    static let PACKAGE_UTIL = URL(fileURLWithPath: "/usr/sbin/pkgutil")
    static let PRODUCT_BUILD = URL(fileURLWithPath: "/usr/bin/productbuild")
    static let PRODUCT_SIGN = URL(fileURLWithPath: "/usr/bin/productsign")
    static let CODE_SIGN_COMMAND = URL(fileURLWithPath: "/usr/bin/codesign")
    static let XCODE_BUILD = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild")
    static let XCRUN = URL(fileURLWithPath: "/usr/bin/xcrun")
    static let XATTR = URL(fileURLWithPath: "/usr/bin/xattr")
    static let SUDO = URL(fileURLWithPath: "/usr/bin/sudo")
    static let DITTO = URL(fileURLWithPath: "/usr/bin/ditto")

    static let HOME = URL.iddHomeDirectory
    static let DESKTOP_PACKAGES = HOME.appendingPathComponent("Desktop/Packages")

    // TODO: the following need to move out of here
    static let INSTALLER_TOOLS = HOME.appendingPathComponent("Development/git.id-design.com/installer_tools")
    static let TEST_ROOT = INSTALLER_TOOLS.appendingPathComponent("helpers/test_files")
    static let SPARKLE_SIGN = INSTALLER_TOOLS.appendingPathComponent("common/sparkle/sign_update")
}
