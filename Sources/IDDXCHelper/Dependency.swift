//
//  Config.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
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

    /**
     make sure you are using xcode 14.2
     xcode-select -p

     update it if not
     sudo xcode-select -s /Applications/Xcode15.app/Contents/Developer
     sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
     */
    static let XCODE_BUILD = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    static let XCRUN = URL(fileURLWithPath: "/usr/bin/xcrun")
    static let XATTR = URL(fileURLWithPath: "/usr/bin/xattr")
    static let SUDO = URL(fileURLWithPath: "/usr/bin/sudo")
    static let DITTO = URL(fileURLWithPath: "/usr/bin/ditto")
    static let TAR = URL(fileURLWithPath: "/usr/bin/tar")

    static let PACKAGES_ARCHIVE_ROOT = URL.home.appendingPathComponent("Desktop/Packages")

    // TODO: the following need to move out of here
    static let INSTALLER_TOOLS = URL.home.appendingPathComponent("Developer/git.id-design.com/installer_tools")
    static let TEST_ROOT = INSTALLER_TOOLS.appendingPathComponent("helpers/test_files")
    static let SPARKLE_SIGN = INSTALLER_TOOLS.appendingPathComponent("common/sparkle/sign_update")
}
