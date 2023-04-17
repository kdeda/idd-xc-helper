//
//  Helper+BuildCode.swift
//  xchelper
//
//  Created by Klajd Deda on 10/24/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import IDDSwift

extension Helper {
    /**
     Build a particular Worksapce, for complex project you might have to build a few.
     For now all the workspaces must output to the same project.buildProductsURL folder
     */
    private func build(workspace: Workspace) {
        Log4swift[Self.self].info("building ...")

        // More arguments can be passed here as "KEY=Value" type thing
        // ie: GCC_PREPROCESSOR_DEFINITIONS="IDD_PTRACE=1"
        // somehow escaping the DSTROOT results in odd ball issues
        // so we will assume there are no spaces in them ...
        //
        let output = Process.fetchString(
            taskURL: Dependency.XCODE_BUILD,
            arguments: [
                "-workspace", workspace.workspaceURL.path,
                "-scheme", workspace.scheme,
                "-configuration", "Release",
                "DSTROOT=\(project.buildProductsURL.path)",
                "DWARF_DSYM_FOLDER_PATH=\(project.buildProductsURL.path)",
                "INSTALL_PATH=.",
                "install"
            ]
        )

        // the 'install' parameter on the arguments will force this output if all goes well
        //
        if output.range(of: "INSTALL SUCCEEDED") == nil {
            Log4swift[Self.self].info("failed build ...")
            Log4swift[Self.self].info("\(output)")
            exit(0)
        }
        Log4swift[Self.self].info("completed build")
    }

    /**
     This will blast the buildProductsURL folder.
     Keep in mind the buildProductsURL points to where xcode will put the products. ie: '/Users/kdeda/Development/build/Release'
     But under it there might be other folders such as '../Intermediates.noindex' or '../Package'
     */
    public func buildCode() {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        if FileManager.default.removeItemIfExist(at: project.buildProductsURL) {
            Log4swift[Self.self].info("removed: '\(project.buildProductsURL.path)'")
        }
        if FileManager.default.createDirectoryIfMissing(at: project.buildProductsURL) {
            Log4swift[Self.self].info("created: '\(project.buildProductsURL.path)'")
        }

        project.workspaces.forEach(build(workspace:))
    }
}

