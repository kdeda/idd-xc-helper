//
//  Helper.swift
//  xchelper
//
//  Created by Klajd Deda on 9/11/19.
//

import Foundation
import Log4swift
import SwiftCommons

// MARK: - Helper -
public struct Helper {
    var project: Project
    
    // MARK: - Private methods -
    private func build(scheme schemeName: String, fromWorkSpaceAtPath workspacePath: String) {
        // let arguments = ["-workspace", workspacePath, "-scheme", schemeName, "GCC_PREPROCESSOR_DEFINITIONS=\"IDD_PTRACE=1\"", "ARCHS=\"x86_64\"", "-configuration", "Release"]
        // GCC_PREPROCESSOR_DEFINITIONS will squish the .xcconfig from Sparkle ...
        // September 2019
        //
        // let arguments = ["-workspace", workspacePath, "-scheme", schemeName, "-configuration", "Release", "DEPLOYMENT_LOCATION=YES", "DSTROOT=/Users/kdeda/Development/build", "INSTALL_PATH=."]

        Log4swift[Self.self].info("building ...")
        let output = Process.fetchString(
            taskURL: Config.XCODE_BUILD,
            arguments: ["-workspace", workspacePath, "-scheme", schemeName, "-configuration", "Release"]
        )
        
        if output.range(of: "BUILD SUCCEEDED") == nil {
            Log4swift[Self.self].info("failed build ...")
            Log4swift[Self.self].info(output)
            exit(0)
        }
        Log4swift[Self.self].info("completed build")
    }
    
    private func copyPackageFiles() {
        Log4swift["xchelper"].info("package: '\(project.configName)'")
        
        if Config.PACKAGE_BASE.fileExist {
            _ = FileManager.default.removeItemIfExist(at: Config.PACKAGE_BASE)
            Log4swift[Self.self].info("removed: '\(Config.PACKAGE_BASE.path)'")
        }

        // copy Products
        //
        let packageNameProducts = Config.PACKAGE_BASE.appendingPathComponent("Products")
        FileManager.default.createDirectoryIfMissing(at: packageNameProducts)
        Log4swift[Self.self].info("created: '\(packageNameProducts.path)'")
        
        project.productFiles.forEach { (productFile) in
            if let source = productFile["source"], let destination = productFile["destination"] {
                let sourceURL = Config.BUILD_SOURCE.appendingPathComponent(source)
                var destinationURL = Config.PACKAGE_BASE.appendingPathComponent(destination)
                
                if !destinationURL.fileExist {
                    FileManager.default.createDirectoryIfMissing(at: destinationURL)
                    Log4swift[Self.self].info("created: '\(destinationURL.path)'")
                }
                do {
                    destinationURL = destinationURL.appendingPathComponent(sourceURL.lastPathComponent)
                    try FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationURL.path)
                    let relativePath = destinationURL.path.substring(after: Config.PACKAGE_BASE.path) ?? "unknown"
                    
                    Log4swift[Self.self].info("copy: '\(sourceURL.path)' to: '..\(relativePath)'")
                } catch {
                    Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
                }
            }
        }

        // strip .svn folders, .h files etc
        //
        do {
            let items = try FileManager.default.subpathsOfDirectory(atPath: Config.PACKAGE_BASE.path)
            items.forEach { (relativeFileName) in
                let fileURL = Config.PACKAGE_BASE.appendingPathComponent(relativeFileName)
                
                if fileURL.isFileURL {
                    if fileURL.pathExtension == "h" || fileURL.lastPathComponent == ".DSStore" {
                        _ = FileManager.default.removeItemIfExist(at: fileURL)
                        Log4swift[Self.self].info("removed: '\(fileURL.path)'")
                    }
                } else if fileURL.isDirectory {
                    if fileURL.pathExtension == "svn" {
                        _ = FileManager.default.removeItemIfExist(at: fileURL)
                        Log4swift[Self.self].info("removed: '\(fileURL.path)'")
                    }
                }
            }
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        // remove xattr
        //
        let packageNameResources = project.pathToConfig.appendingPathComponent("Resources")
        let output = Process.fetchString(taskURL: Config.XATTR, arguments: ["-cr", packageNameResources.path])
        
        Log4swift[Self.self].info(output)
    }
    
    private func removeSignature(file fileURL: URL) {
        let arguments = ["--remove-signature", fileURL.path]
        _ = Process
            .fetchData(taskURL: Config.CODE_SIGN_COMMAND, arguments: arguments)
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
        let tool = Config.CODE_SIGN_COMMAND
        var arguments = ["--verbose"]
        
        if entitlmentsPath.count > 0 {
            arguments += ["--entitlements", entitlmentsPath]
        }
        arguments += ["--force", "--timestamp", "--options=runtime", "--strict", "--sign"]
        arguments += [project.certificateApplication]
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
            .fetchData(taskURL: Config.CODE_SIGN_COMMAND, arguments: ["--verify", "--verbose", fileURL.path])
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
    
    private func signPackageValidate() {
        let output = Process.fetchString(
            taskURL: Config.PACKAGE_UTIL,
            arguments: ["--check-signature", project.pathToPKG.path]
        )
        
        guard output.range(of: "Signed with a trusted timestamp") != .none
        else {
            Log4swift[Self.self].info("failed to sign: \(project.pathToPKG.path)")
            Log4swift[Self.self].info("output: \(output)")
            Log4swift[Self.self].info("")
            Log4swift[Self.self].info("")
            exit(0)
        }
        Log4swift[Self.self].info("   validated signature: \(project.pathToPKG.path)")
    }
    
    private func signPackage() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let output = Process.fetchString(
            taskURL: Config.PRODUCT_SIGN,
            arguments: [
                "--sign",
                project.certificateInstaller,
                project.pathToPKGAdorned.path,
                project.pathToPKG.path
            ])
        
        guard output.range(of: ": Wrote signed product archive") != .none
        else {
            Log4swift[Self.self].info("failed to sign: \(project.pathToPKGUnsigned.path)")
            Log4swift[Self.self].info("output: \(output)")
            Log4swift[Self.self].info("")
            Log4swift[Self.self].info("")
            exit(0)
        }
        Log4swift[Self.self].info("    created signed package: \(project.pathToPKG.path)")
    }
    
    // since pkg will preserve permissions
    // we have to adjust or the app will be installed as the builder
    //
    private func fixPermissions() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let script = URL.iddHomeDirectory.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/fixPackagePermissions.tcsh")
        let output = Process.fetchString(taskURL: Config.SUDO, arguments: [script.path, project.packageName])
        
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info(output)
            exit(0)
        }
    }
    
    /*
     https://stackoverflow.com/questions/11487596/making-macos-installer-packages-which-are-developer-id-ready
     https://scriptingosx.com/2020/12/platform-support-in-macos-installer-packages-pkg/
     pkgutil --expand "/Users/kdeda/Downloads/Install iTunes.pkg" "Install iTunes"
     we need to rework this flow to use apple's crap ...

     cd /Users/kdeda/Development/build/Package
     pkgbuild --identifier com.id-design.v7.whatsize.pkg --version 7.7.3 --root ./BuildProducts --scripts ./Scripts --install-location / ./WhatSize.pkg
     pkgbuild --analyze --root /Users/kdeda/Development/build/Release/WhatSize.app /Users/kdeda/Development/build/WhatSizeComponents.plist
     pkgbuild --root /Users/kdeda/Development/build/Release/WhatSize.app --component-plist /Users/kdeda/Development/build/WhatSizeComponents.plist /Users/kdeda/Development/build/Package/WhatSize.pkg
     */
    private func makePackage() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
                
        // Create the WhatSize.pkg
        // Generate the component file manually once in a while
        // pkgbuild --analyze --root ./BuildProducts component-list.plist
        // and replace the relocatable flag
        // plutil -replace BundleIsRelocatable -bool NO component-list.plist
        //
        var output = Process.fetchString(
            taskURL: Config.PACKAGE_BUILD,
            arguments: [
                "--identifier",
                project.bundleIdentifier,
                "--version",
                project.bundleShortVersionString,
                "--root",
                Config.PACKAGE_BASE.appendingPathComponent("Products").path,
                "--scripts",
                project.pathToConfig.appendingPathComponent("Scripts").path,
                "--install-location",
                "/",
                "--component-plist",
                project.pathToConfig.appendingPathComponent("component-list.plist").path,
                project.pathToPKGUnsigned.path
            ])
        guard output.range(of: ": Wrote package to") != .none
        else {
            Log4swift[Self.self].info("failed to create: \(project.pathToPKGUnsigned.path)")
            Log4swift[Self.self].info("output: \(output)")
            Log4swift[Self.self].info("")
            Log4swift[Self.self].info("")
            exit(0)
        }

        // Adorn the package, ie: WhatSizeAdorned.pkg
        //
        output = Process.fetchString(
            taskURL: Config.PRODUCT_BUILD,
            arguments: [
                "--distribution",
                project.distributionURL.path,
                "--resources",
                project.pathToConfig.appendingPathComponent("Resources").path,
                "--package-path",
                Config.PACKAGE_BASE.path,
                project.pathToPKGAdorned.path
            ])
        guard output.range(of: ": Wrote product to") != .none
        else {
            Log4swift[Self.self].info("failed to create: \(project.pathToPKGAdorned.path)")
            Log4swift[Self.self].info("output: \(output)")
            Log4swift[Self.self].info("")
            Log4swift[Self.self].info("")
            exit(0)
        }
    }

    // MARK: - Instance methods -
    init(configName: String) {
        let projectJson = Config
            .SRIPTS_ROOT
            .appendingPathComponent(configName)
            .appendingPathComponent("Project.json")
        if !projectJson.fileExist {
            Log4swift[Self.self].info("missing path: '\(projectJson.path)'")
            Log4swift[Self.self].info("missing path: '\(projectJson.path)'")
        }
        self.project = JSONDecoder.decode(Data.init(withURL:projectJson))!
    }
    
    public func handleAction(_ action: HelperAction) -> Helper {
        switch action {
        case .updateVersions: updateVersions()
        case .buildCode: buildCode()
        case .signCode: signCode()
        case .updateSparkle: updateSparkle()
        case .createPackage: createPackage()
        case .notarizePackage: notarizePackage()
        case .notarizeApp: notarizeApp()
        case .notarizeDMG: notarizeDMG()
        case .compressPackage: compressPackage()
        case .packageTips: packageTips()
        }
        return self
    }
    
    public func updateVersions() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        project.updateVersions()
    }
    
    // will remove the ../build/Release
    //
    public func buildCode() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
//        let buildURL = Config.BUILD_SOURCE.appendingPathComponent("build/Release")
//        if FileManager.default.removeItemIfExist(at: buildURL) {
//            Log4swift[Self.self].info("removed: '\(buildURL.path)'")
//        }
//        if FileManager.default.createDirectoryIfMissing(at: buildURL) {
//            Log4swift[Self.self].info("created: '\(buildURL.path)'")
//        }
        
        project.workspaces.forEach { (workspace) in
            if let scheme = workspace["scheme"], let workspace = workspace["workspace"] {
                build(scheme: scheme, fromWorkSpaceAtPath: workspace)
            }
        }
    }
    
    // http://lessons.livecode.com/a/1088036-signing-and-notarizing-macos-apps-for-gatekeeper
    //
    public func signCode() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        project.productFilesToSign.forEach { relativeBuildFile in
            let sourceURL = Config.BUILD_SOURCE.appendingPathComponent(relativeBuildFile)
            
            if sourceURL.pathExtension == "app" {
                Log4swift[Self.self].info("signApplication: '\(relativeBuildFile)'")
                signApplicationFrameworks(at: sourceURL)
                signPlugins(at: sourceURL)
                signLaunchServices(at: sourceURL)
                
                let fileName = sourceURL.deletingPathExtension().lastPathComponent
                let fileURL = sourceURL.appendingPathComponent("Contents/MacOS/\(fileName)")
                
                removeSignature(file: fileURL)
                sign(file: fileURL, entitlments: project.entitlementsFile)
                sign(file: sourceURL, entitlments: project.entitlementsFile)
            } else {
                removeSignature(file: sourceURL)
                sign(file: sourceURL, entitlments: "")
            }
        }
    }
    
    // should run as root
    //
    public func createPackage() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let script = URL.iddHomeDirectory.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/chownExistingPackage.tcsh")
        let output = Process.fetchString(taskURL: Config.SUDO, arguments: [script.path])
        
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info(output)
            exit(0)
        }
        
        copyPackageFiles()
        fixPermissions()
        makePackage()
        signPackage()
        signPackageValidate()
        
        compressPackage()
    }
    
    public func notarizePackage() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let pkgFile = project.pathToPKG
        pkgFile.notarize(keychainProfile: project.notarytoolProfileName)
        if !pkgFile.xcrunStaplerStapleAndValidate {
            exit(0)
        }
        compressPackage()
    }
    
    /**
     https://forum.xojo.com/t/notarizing-an-app-for-zip-distribution/49736
     Will notarize a .app, will make a zip first and notarize it than the app is stapled.
     */
    //
    public func notarizeApp() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let apps = project.productFilesToSign.map(Config.BUILD_SOURCE.appendingPathComponent)
        guard let appPath = apps.first
        else {
            exit(0)
        }
        
        let appName = appPath.deletingPathExtension().lastPathComponent
        let zipFile = appPath.deletingLastPathComponent().appendingPathComponent("\(appName.lowercased()).zip")
        _ = Process.fetchString(
            taskURL: Config.DITTO,
            arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", appPath.path, zipFile.path]
        )
        
        zipFile.notarize(keychainProfile: project.notarytoolProfileName)
        
        // from Eskino
        // https://developer.apple.com/forums/thread/116812
        // we have to staple the app we just notarized
        if !appPath.xcrunStaplerStapleAndValidate {
            exit(0)
        }
        // than create a new zip
        _ = Process.fetchString(
            taskURL: Config.DITTO,
            arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", appPath.path, zipFile.path]
        )
    }

    /**
     WIP
     */
    // TODO: Fix me ...
    public func notarizeDMG() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
//        let apps = project.productFilesToSign.map(Config.BUILD_SOURCE.appendingPathComponent)
//        guard let appPath = apps.first
//        else {
//            exit(0)
//        }
//
//        let appName = appPath.deletingPathExtension().lastPathComponent
//        let zipFile = appPath.deletingLastPathComponent().appendingPathComponent("\(appName.lowercased()).zip")
//        let tool = "/usr/bin/ditto"
//        let arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", appPath.path, zipFile.path]
//        Log4swift[Self.self].info("\(tool) \(arguments.joined(separator: " "))")
//        _ = Process.fetchString(taskURL: tool, arguments: arguments)
        
        let diskImage = URL(fileURLWithPath: "/Users/cdeda/Development/backblaze/bzmono/www/java/clientdownload/bzinstall-mac-8.5.0.634-ca000.backblaze.com.dmg")
        diskImage.notarize(keychainProfile: project.notarytoolProfileName)
        if !diskImage.xcrunStaplerStapleAndValidate {
            exit(0)
        }
    }

    public func compressPackage() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        
        let script = URL.iddHomeDirectory.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/compressPackage.tcsh")
        let output = Process.fetchString(taskURL: Config.SUDO, arguments: [script.path, project.packageName])
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info(output)
            exit(0)
        }
        
        let packageFolder = "\(project.packageName)_\(project.bundleShortVersionString)"
        let desktopBaseURL = Config.DESKTOP_PACKAGES.appendingPathComponent(packageFolder)
        
        FileManager.default.createDirectoryIfMissing(at: desktopBaseURL)
        do {
            let desktopURL = desktopBaseURL.appendingPathComponent(project.packageName).appendingPathExtension("pkg")
            
            _ = FileManager.default.removeItemIfExist(at: desktopURL)
            try FileManager.default.copyItem(at: project.pathToPKG, to: desktopURL)
            Log4swift[Self.self].info("updated \(desktopURL.path)")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        do {
            let desktopURL = desktopBaseURL.appendingPathComponent(project.packageName).appendingPathExtension("tgz")
            
            _ = FileManager.default.removeItemIfExist(at: desktopURL)
            try FileManager.default.copyItem(at: project.pathToTGZ, to: desktopURL)
            Log4swift[Self.self].info("updated \(desktopURL.path)")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
    }
    
    // shall be called after compressPackage
    //
    public func updateSparkle() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        Log4swift[Self.self].info("notes_xml: '\(project.notes_xml)'")
        do {
            let fileURL = project.sparkleApplicationReleaseURL.appendingPathComponent("notes.xml")
            try project.notes_xml.write(to: fileURL, atomically: true, encoding: .utf8)
            Log4swift[Self.self].info("updated: '\(fileURL.path)'")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        Log4swift[Self.self].info("sparklecast_xml: '\(project.sparklecast_xml)'")
        do {
            let fileURL = project.sparkleApplicationReleaseURL.appendingPathComponent("sparklecast.xml")
            try project.sparklecast_xml.write(to: fileURL, atomically: true, encoding: .utf8)
            Log4swift[Self.self].info("updated: '\(fileURL.path)'")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        if project.bundleIdentifier.hasPrefix("com.id-design") {
            let phpInfo_xml: String = {
                var rv = ""
                
                rv += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                rv += "<!--\n"
                rv += "    autogenerated \(Date.init().description)\n"
                rv += "-->\n"
                rv += "<info>\n"
                rv += "    <version>\(project.bundleShortVersionString)</version>\n"
                rv += "    <releaseDate>\(project.sparkleReleaseDate)</releaseDate>\n"
                rv += "    <sizeInMB>\(project.pathToPKG.physicalSize.compactFormatted)</sizeInMB>\n"
                rv += "</info>\n"
                return rv
            }()
            
            Log4swift[Self.self].info("phpInfo_xml: '\(phpInfo_xml)'")
            do {
                let fileURL = project.sparkleApplicationReleaseURL.appendingPathComponent("phpInfo.xml")
                try phpInfo_xml.write(to: fileURL, atomically: true, encoding: .utf8)
                Log4swift[Self.self].info("updated: '\(fileURL.path)'")
            } catch {
                Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
            }
        }
    }
    
    public func packageTips() {
        Log4swift[Self.self].info("package: '\(project.configName)'")
        let packageFolder = "\(project.packageName)_\(project.bundleShortVersionString)"
        
        if project.bundleIdentifier.hasPrefix("com.id-design") {
            let WEBSERVER_ROOT = "/var/www/www.whatsizemac.com/downloads"
            let WEBSITE_URL = "https://www.whatsizemac.com"
            let WEBSITE_REPO = URL.iddHomeDirectory.appendingPathComponent("Development/git.id-design.com/website")
            
            Log4swift[Self.self].info("Manually upload/download ...")
            Log4swift[Self.self].info("Use these commands to upload packages into the public servers directly")
            Log4swift[Self.self].info("    --------------------------------")
            Log4swift[Self.self].info("scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(project.sparkleSSHUserName):\(WEBSERVER_ROOT)/\(packageFolder.lowercased()).pkg")
            Log4swift[Self.self].info("\(WEBSITE_URL)/downloads/\(packageFolder.lowercased()).pkg")
            
            Log4swift[Self.self].info(" ")
            Log4swift[Self.self].info("Manually Update the Sparkle server directly ...")
            Log4swift[Self.self].info("These commands will update the public sparkle server, live")
            Log4swift[Self.self].info("    --------------------------------")
            Log4swift[Self.self].info("scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).tgz \(project.sparkleSSHUserName):\(project.sparkleApacheServerURL)/\(packageFolder.lowercased()).tgz")
            Log4swift[Self.self].info("scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(project.sparkleSSHUserName):\(project.sparkleApacheServerURL)/\(project.packageName.lowercased()).pkg")
            Log4swift[Self.self].info("scp -r \(project.sparkleApplicationReleaseURL.path)/ \(project.sparkleSSHUserName):\(project.sparkleApacheServerURL)/")
            
            Log4swift[Self.self].info(" ")
            Log4swift[Self.self].info("Manually Update the local WebSite repo ...")
            Log4swift[Self.self].info("Validate/Test locally than push to the remote: '\(WEBSITE_REPO.path)'")
            Log4swift[Self.self].info("When ready sync the live server with this repo to see Sparkle and WebSite changes ...")
            Log4swift[Self.self].info("    --------------------------------")
            Log4swift[Self.self].info("cp -R ~/Development/git.id-design.com/whatsize7/WhatSize/release \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/")
            Log4swift[Self.self].info("cp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).tgz \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/\(packageFolder.lowercased()).tgz")
            Log4swift[Self.self].info("cp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/\(project.packageName.lowercased()).pkg")
        } else if project.bundleIdentifier.hasPrefix("com.other") {
        }
        
        Log4swift[Self.self].info(" ")
        Log4swift[Self.self].info("Install the package locally and test ...")
        Log4swift[Self.self].info("sudo installer -verbose -pkg ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg -target /")
        Log4swift[Self.self].info(" ")
    }
}
