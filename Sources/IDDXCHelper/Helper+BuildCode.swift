//
//  Helper+BuildCode.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 10/24/22.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import IDDSwift

extension Helper {
    /**
     Build a particular Worksapce, for complex project you might have to build a few.
     For now all the workspaces must output to the same project.buildProductsURL folder
     */
    private func build(workspace: Workspace) async {
        Log4swift[Self.self].info("building ...")

        /**
         More arguments can be passed here as "KEY=Value" type thing
         ie: GCC\_PREPROCESSOR\_DEFINITIONS="IDD\_PTRACE=1"
         somehow escaping the DSTROOT results in odd ball issues
         so we will assume there are no spaces in them ...

         Starting on Xcode 15 puting . on the INSTALL\_PATH causes problems on a clean build
         The work around is to have DSTROOT="/Users/kdeda/Developer/build"
         and define INSTALL\_PATH=Release
         All the products will be paced under /Users/kdeda/Developer/build/Release
         */
        let DSTROOT = (project.buildProductsURL.lastPathComponent == "Release")
        ? project.buildProductsURL.deletingLastPathComponent().path
        : project.buildProductsURL.path

        let process = Process(Dependency.XCODE_BUILD, [
            "-workspace", workspace.workspaceURL.path,
            "-scheme", workspace.scheme,
            "-configuration", "Release",
            "-derivedDataPath", "\(project.buildProductsURL.path)/DerivedData",
            "ONLY_ACTIVE_ARCH=NO", // for some reason xcode was building arm only
            "DSTROOT=\(DSTROOT)",
            "DWARF_DSYM_FOLDER_PATH=\(project.buildProductsURL.path)/dSYM",
            "INSTALL_PATH=Release",
            "install"
        ])

        var processOutput = ""
        let processName = Bundle.main.executableURL?.lastPathComponent ?? "unknown"
        let logFile = URL.home.appendingPathComponent("Library/Logs/\(processName)_build.log")
        let fileHandle: FileHandle? = {
            // the file shall be reset to zero ...
            try? "".write(to: logFile, atomically: true, encoding: .utf8)
            Log4swift[Self.self].info("to see log details\n tail -f '\(logFile.path)'")

            let rv = try? FileHandle(forWritingTo: logFile)
            _ = try? rv?.seekToEnd()
            rv?.write(
                """
                \n
                --------------------------------------------------
                building workspace: \(workspace.scheme)
                --------------------------------------------------
                \n
                """.data(using: .utf8) ?? Data())
            return rv
        }()

        for await output in process.asyncOutput() {
            switch output {
            case .error:
                ()
                // Log4swift[Self.self].info("error: '\(error)'")
            case .terminated:
                ()
                // Log4swift[Self.self].info("terminated: '\(reason)'")
            case let .stdout(data):
                fileHandle?.write(data)

                let string = String(data: data, encoding: .utf8) ?? ""
                // Log4swift[Self.self].info("stdout: '\(string)'")
                processOutput += string
            case let .stderr(data):
                fileHandle?.write(data)

                let string = String(data: data, encoding: .utf8) ?? ""
                //Log4swift[Self.self].info("stderr: '\(string)'")
                processOutput += string
            }
        }

        // the 'install' parameter on the arguments will force this output if all goes well
        //
        if processOutput.range(of: "INSTALL SUCCEEDED") == nil {
            Log4swift[Self.self].info("failed build ...")
            Log4swift[Self.self].info("to see log details\n tail -100 '\(logFile.path)'")
            exit(0)
        }
        Log4swift[Self.self].info("completed build")
    }

    /**
     This will blast the buildProductsURL folder.
     Keep in mind the buildProductsURL points to where xcode will put the products. ie: '/Users/kdeda/Developer/build/Release'
     But under it there might be other folders such as '../Intermediates.noindex' or '../Package'
     */
    public func buildCode() async {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        if FileManager.default.removeItemIfExist(at: project.buildProductsURL) {
            Log4swift[Self.self].info("removed: '\(project.buildProductsURL.path)'")
        }
        if FileManager.default.createDirectoryIfMissing(at: project.buildProductsURL) {
            Log4swift[Self.self].info("created: '\(project.buildProductsURL.path)'")
        }

        await project.workspaces.asyncForEach(build(workspace:))
    }
}

