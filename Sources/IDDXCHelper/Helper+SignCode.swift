//
//  File.swift
//  
//
//  Created by Klajd Deda on 10/24/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import SwiftCommons

extension Helper {
    private func removeSignature(file fileURL: URL) {
        let arguments = ["--remove-signature", fileURL.path]
        _ = Process
            .fetchData(taskURL: Dependency.CODE_SIGN_COMMAND, arguments: arguments)
            .allString()
        //
        //        switch output {
        //        case .success(let output):
        //            Log4swift[Self.self].info("output: \(output)")
        //        case .failure(let error):
        //            Log4swift[Self.self].info("output: \(error)")
        //        }
    }

    @discardableResult
    private func sign(file fileURL: URL, entitlments entitlmentsPath: String) -> Result<URL, Error> {
        let tool = Dependency.CODE_SIGN_COMMAND
        var arguments = ["--verbose"]

        if entitlmentsPath.count > 0 {
            arguments += ["--entitlements", entitlmentsPath]
        }
        arguments += ["--force", "--timestamp", "--options=runtime", "--strict", "--sign"]
        arguments += [project.keyChain.developerIDApplication]
        arguments += [fileURL.path]

        _ = Process
            .fetchData(taskURL: tool, arguments: arguments)
            .mapError { processError in
                Log4swift[Self.self].info("failed to sign: \(fileURL.path)")
                Log4swift[Self.self].info("output: \(processError)")
                Log4swift[Self.self].info("")
                Log4swift[Self.self].info("")
                exit(0)
            }
            .allString()
            .flatMap { output -> Result<Bool, Process.ProcessError> in
                guard output.range(of: "\(fileURL.lastPathComponent): signed") != .none,
                      output.range(of: "Mach-O") != .none
                else {
                    Log4swift[Self.self].info("output: \(output)")
                    return .failure(.error("failed to sign: \(fileURL.path)"))
                }
                return .success(true)
            }
        // we really want to stop cold ...
            .mapError { error -> Process.ProcessError in
                Log4swift[Self.self].info("\(error)")
                Log4swift[Self.self].info("")
                Log4swift[Self.self].info("")
                exit(0)
            }

        return signValidate(file: fileURL)
    }

    // How to inspect entitlements
    // codesign -d --entitlements - [binary]
    // /usr/bin/codesign --verify --verbose /Users/kdeda/Development/build/Debug/WhatSize.app
    //
    private func signValidate(file fileURL: URL) -> Result<URL, Error> {
        _ = Process
            .fetchData(taskURL: Dependency.CODE_SIGN_COMMAND, arguments: ["--verify", "--verbose", fileURL.path])
            .mapError { processError in
                Log4swift[Self.self].info("failed to sign: \(fileURL.path)")
                Log4swift[Self.self].info("output: \(processError)")
                Log4swift[Self.self].info("")
                Log4swift[Self.self].info("")
                exit(0)
            }
            .allString()
            .flatMap { output -> Result<Bool, Process.ProcessError> in
                guard output.range(of: "satisfies its Designated Requirement") == .none
                else { return .success(true) }

                guard output.range(of: "valid on disk") != .none,
                      output.range(of: "Mach-O") != .none
                else {
                    Log4swift[Self.self].info("output: \(output)")
                    return .failure(.error("failed to sign: \(fileURL.path)"))
                }
                return .success(true)
            }
        // we really want to stop cold ...
            .mapError { error -> Process.ProcessError in
                Log4swift[Self.self].info("\(error)")
                Log4swift[Self.self].info("")
                Log4swift[Self.self].info("")
                exit(0)
            }

        Log4swift[Self.self].info("   validated signature: \(fileURL.path)")
        return .success(fileURL)
    }

    // this is url to a .app
    //
    private func signApplicationFrameworks(at applicationURL: URL) {
        do {
            let applicationURL = applicationURL.appendingPathComponent("Contents/Frameworks")
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: applicationURL.path)

            fileNames.forEach { fileName in
                let parentURL = applicationURL.appendingPathComponent(fileName)
                let fileType = parentURL.pathExtension
                let fileName = parentURL.deletingPathExtension().lastPathComponent

                switch fileType {
                case "framework":
                    let fileURL = parentURL.appendingPathComponent("Versions/A")
                    let headersURL = parentURL.appendingPathComponent("Versions/A/Headers")

                    Log4swift[Self.self].info("fileURL: '\(fileURL)'")
                    if fileName == "Sparkle" {
                        let fileop = parentURL.appendingPathComponent("Versions/A/Resources/Autoupdate.app/Contents/MacOS/fileop")
                        removeSignature(file: fileop)
                        sign(file: fileop, entitlments: "")

                        let autoupdate = parentURL.appendingPathComponent("Versions/A/Resources/Autoupdate.app/Contents/MacOS/Autoupdate")
                        removeSignature(file: autoupdate)
                        sign(file: autoupdate, entitlments: "")
                    }
                    // remove headers on installed code
                    let headerFiles = (try? FileManager.default.contentsOfDirectory(atPath: headersURL.path)) ?? []
                    headerFiles.forEach { headerFile in
                        try? FileManager.default.removeItem(atPath: headersURL.appendingPathComponent(headerFile).path)
                    }
                    removeSignature(file: fileURL)
                    sign(file: fileURL, entitlments: "")
                case "dylib":
                    removeSignature(file: parentURL)
                    sign(file: parentURL, entitlments: "")
                default:
                    Log4swift[Self.self].error("ignore: '\(parentURL)'")
                }
            }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
    }

    private func signPlugins(at applicationURL: URL) {
        do {
            let applicationURL = applicationURL.appendingPathComponent("Contents/Resources/Plugins")
            guard applicationURL.fileExist
            else {
                Log4swift[Self.self].error("Found no plugins under: '\(applicationURL.path)'")
                return
            }
            let fileNames = try FileManager.default.subpathsOfDirectory(atPath: applicationURL.path)
            let knownPlugins = Set(["FooPlugin.extension"])

            _ = fileNames
                .map { applicationURL.appendingPathComponent($0) }
                .filter { knownPlugins.contains($0.lastPathComponent) }
                .compactMap { (pluginFileURL) -> Result<URL, Error>? in
                    removeSignature(file: pluginFileURL)
                    let result = sign(file: pluginFileURL, entitlments: "")
                    switch result {
                    case .success(_):
                        return .none
                    case .failure(let error):
                        print("error: '\(error)' on: '\(pluginFileURL)'")
                        return result
                    }
                }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
    }

    private func signLaunchServices(at applicationURL: URL) {
        do {
            let applicationURL = applicationURL.appendingPathComponent("Contents/Library/LaunchServices")
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: applicationURL.path)

            fileNames.forEach { (fileName) in
                let parentURL = applicationURL.appendingPathComponent(fileName)

                removeSignature(file: parentURL)
                sign(file: parentURL, entitlments: "")
            }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
    }

    // http://lessons.livecode.com/a/1088036-signing-and-notarizing-macos-apps-for-gatekeeper
    //
    public func signCode() {
        Log4swift[Self.self].info("package: '\(project.configName)'")

        project.productFiles.filter(\.requiresSignature).forEach { productFile in
            if productFile.sourceURL.pathExtension == "app" {
                Log4swift[Self.self].info("signApplication: '\(productFile.sourceURL.path)'")
                signApplicationFrameworks(at: productFile.sourceURL)
                signPlugins(at: productFile.sourceURL)
                signLaunchServices(at: productFile.sourceURL)

                let fileName = productFile.sourceURL.deletingPathExtension().lastPathComponent
                let fileURL = productFile.sourceURL.appendingPathComponent("Contents/MacOS/\(fileName)")

                removeSignature(file: fileURL)
                sign(file: fileURL, entitlments: productFile.entitlementsPath)
                sign(file: productFile.sourceURL, entitlments: productFile.entitlementsPath)
            } else {
                removeSignature(file: productFile.sourceURL)
                sign(file: productFile.sourceURL, entitlments: "")
            }
        }
    }
}
