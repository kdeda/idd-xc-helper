//
//  Config.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//

import Foundation

struct Config {
    static let HOME = URL.iddHomeDirectory
    static let INSTALLER_TOOLS = HOME.appendingPathComponent("Development/git.id-design.com/installer_tools")
    static let TEST_ROOT = INSTALLER_TOOLS.appendingPathComponent("helpers/test_files")
    static let SRIPTS_ROOT = INSTALLER_TOOLS.appendingPathComponent("scripts")
    static let SPARKLE_SIGN = INSTALLER_TOOLS.appendingPathComponent("common/sparkle/sign_update")

    static let BUILD_SOURCE = HOME.appendingPathComponent("Development")
    static let PACKAGE_BASE = HOME.appendingPathComponent("Development/build/Package")
    static let DESKTOP_PACKAGES = HOME.appendingPathComponent("Desktop/Packages")

    static let PACKAGES = URL(fileURLWithPath: "/usr/local/bin/packagesbuild")
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

    static let CERTIFICATE_APPLICATION_GATEKEEPER_OTHER = "Developer ID Application: Other Software Inc. (8008-DEBYQ)"
    static let CERTIFICATE_INSTALLER_GATEKEEPER_OTHER = "Developer ID Installer: Other Software Inc. (8008-DEBYQ)"
    static let CERTIFICATE_APPLICATION_GATEKEEPER_IDD = "Developer ID Application: ID-DESIGN INC. (ME637H7ZM9)"
    static let CERTIFICATE_INSTALLER_GATEKEEPER_IDD = "Developer ID Installer: ID-DESIGN INC. (ME637H7ZM9)"
}
