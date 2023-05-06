//
//  Helper.swift
//  xchelper
//
//  Created by Klajd Deda on 9/11/19.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import IDDSwift

/**
 Implementations for each HelperAction
 */
public struct Helper {
    var project: Project
    
    // MARK: - Private methods -
    
    private func copyPackageFiles() {
        Log4swift["xchelper"].info("package: '\(project.configName)'")
        
        // copy Products
        //
        project.productFiles.forEach { productFile in
            let destinationURL = project.packageRootURL.appendingPathComponent(productFile.destinationURL.path)
            
            if !destinationURL.fileExist {
                FileManager.default.createDirectoryIfMissing(at: destinationURL)
                Log4swift[Self.self].info("created: '\(destinationURL.path)'")
            }
            do {
                let destinationURL = destinationURL.appendingPathComponent(productFile.sourceURL.lastPathComponent)
                try FileManager.default.copyItem(atPath: productFile.sourceURL.path, toPath: destinationURL.path)
                let relativePath = destinationURL.path.substring(after: project.packageRootURL.path) ?? "unknown"
                
                Log4swift[Self.self].info("copy: '\(productFile.sourceURL.path)' to: '..\(relativePath)'")
            } catch {
                Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
            }
        }

        // strip .svn folders, .h files etc
        //
        do {
            let items = try FileManager.default.subpathsOfDirectory(atPath: project.packageRootURL.path)
            
            items.forEach { (relativeFileName) in
                let fileURL = project.packageRootURL.appendingPathComponent(relativeFileName)
                
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
        let packageNameResources = project.configURL.appendingPathComponent("Resources")
        let output = Process.fetchString(taskURL: Dependency.XATTR, arguments: ["-cr", packageNameResources.path])
        
        Log4swift[Self.self].info("\(output)")
    }
    
    private func signPackageValidate() {
        let output = Process.fetchString(
            taskURL: Dependency.PACKAGE_UTIL,
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
            taskURL: Dependency.PRODUCT_SIGN,
            arguments: [
                "--sign",
                project.keyChain.developerIDInstall,
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
        
        let script = URL.home.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/fixPackagePermissions.tcsh")
        let output = Process.fetchString(taskURL: Dependency.SUDO, arguments: [script.path, project.packageName])
        
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info("\(output)")
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
            taskURL: Dependency.PACKAGE_BUILD,
            arguments: [
                "--identifier",
                project.packageIdentifier,
                "--version",
                project.versionInfo.bundleShortVersionString,
                "--root",
                project.packageRootURL.appendingPathComponent("Products").path,
                "--scripts",
                project.configURL.appendingPathComponent("Scripts").path,
                "--install-location",
                "/",
                "--component-plist",
                project.configURL.appendingPathComponent("component-list.plist").path,
                project.pathToPKGUnsigned.path
            ])
        guard output.range(of: ": Wrote package to") != .none
        else {
            Log4swift[Self.self].info("failed to create: \(project.pathToPKGUnsigned.path)")
            Log4swift[Self.self].info("\(output)")
            Log4swift[Self.self].info("")
            Log4swift[Self.self].info("")
            exit(0)
        }

        // Adorn the package, ie: WhatSizeAdorned.pkg
        //
        output = Process.fetchString(
            taskURL: Dependency.PRODUCT_BUILD,
            arguments: [
                "--distribution",
                project.distributionURL.path,
                "--resources",
                project.configURL.appendingPathComponent("Resources").path,
                "--package-path",
                project.packageRootURL.path,
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

    /**
     This should be the path to the Project.json
     */
    public init(configURL: URL) {
        self.project = Project(configURL: configURL)!
    }

    public func actionDivider(method: String = #function) -> String {
        let logMessage = "<IDDXCHelper.Helper \(method)>   package: '\(project.configName)'"
        return "\n" + Array(repeating: "-", count: 42 + logMessage.count).joined(separator: "")
    }

    public func handleAction(_ action: HelperAction) async -> Helper {
        switch action {
        case .updateVersions: updateVersions()
        case .buildCode: await buildCode()
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

    // should run as root
    // will blast and recreate the Package folder at project.packageRootURL
    //
    public func createPackage() {
        let security = URL(fileURLWithPath: "/private/etc/sudoers.d/kdeda")

        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        if !security.fileExist {
            Log4swift[Self.self].info("Please create: '\(security.path)'")
            Log4swift[Self.self].info("   Follow instrctions from '../common/scripts/ ReadMe.txt'")
            Log4swift[Self.self].info("   Upgrading or installing a macOS major update tends to blw these away")
            exit(0)
        }
        let script = URL.home.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/chownExistingPackage.tcsh")
        let output = Process.fetchString(taskURL: Dependency.SUDO, arguments: [script.path])
        
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info("\(output)")
            exit(0)
        }

        if FileManager.default.removeItemIfExist(at: project.packageRootURL) {
            Log4swift[Self.self].info("removed: '\(project.packageRootURL.path)'")
        }
        if FileManager.default.createDirectoryIfMissing(at: project.packageRootURL) {
            Log4swift[Self.self].info("created: '\(project.packageRootURL.path)'")
        }

        copyPackageFiles()
        fixPermissions()
        makePackage()
        signPackage()
        signPackageValidate()
        
        compressPackage()
    }
    
    public func notarizePackage() {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        let pkgFile = project.pathToPKG
        pkgFile.notarize(keychainProfile: project.keyChain.keychainProfile)
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
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        guard let productFile = project.productFiles.filter(\.requiresSignature).first
        else {
            exit(0)
        }
        
        let appName = productFile.sourceURL.deletingPathExtension().lastPathComponent
        let zipFile = productFile.sourceURL.deletingLastPathComponent().appendingPathComponent("\(appName.lowercased()).zip")
        _ = Process.fetchString(
            taskURL: Dependency.DITTO,
            arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", productFile.sourceURL.path, zipFile.path]
        )
        
        zipFile.notarize(keychainProfile: project.keyChain.keychainProfile)
        
        // from Eskino
        // https://developer.apple.com/forums/thread/116812
        // we have to staple the app we just notarized
        if !productFile.sourceURL.xcrunStaplerStapleAndValidate {
            exit(0)
        }
        // than create a new zip
        _ = Process.fetchString(
            taskURL: Dependency.DITTO,
            arguments: ["-c", "-k", "--sequesterRsrc", "--keepParent", productFile.sourceURL.path, zipFile.path]
        )
    }

    /**
     WIP
     */
    // TODO: Fix me ...
    public func notarizeDMG() {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

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
        diskImage.notarize(keychainProfile: project.keyChain.keychainProfile)
        if !diskImage.xcrunStaplerStapleAndValidate {
            exit(0)
        }
    }

    public func compressPackage() {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        let script = URL.home.appendingPathComponent("Development/git.id-design.com/installer_tools/common/scripts/compressPackage.tcsh")
        let output = Process.fetchString(taskURL: Dependency.SUDO, arguments: [script.path, project.packageName])
        if output.range(of: "completed") == nil {
            Log4swift[Self.self].info("\(output)")
            exit(0)
        }
        
        let packageFolder = "\(project.packageName)_\(project.versionInfo.bundleShortVersionString)"
        let desktopBaseURL = Dependency.PACKAGES_ARCHIVE_ROOT.appendingPathComponent(packageFolder)
        
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
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")
        Log4swift[Self.self].info("notes_xml: '\(project.notes_xml)'")
        do {
            let fileURL = project.sparkle.releaseURL.appendingPathComponent("notes.xml")
            try project.notes_xml.write(to: fileURL, atomically: true, encoding: .utf8)
            Log4swift[Self.self].info("updated: '\(fileURL.path)'")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        Log4swift[Self.self].info("sparklecast_xml: '\(project.sparklecast_xml)'")
        do {
            let fileURL = project.sparkle.releaseURL.appendingPathComponent("sparklecast.xml")
            try project.sparklecast_xml.write(to: fileURL, atomically: true, encoding: .utf8)
            Log4swift[Self.self].info("updated: '\(fileURL.path)'")
        } catch {
            Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
        }
        
        if project.packageIdentifier.hasPrefix("com.id-design") {
            let phpInfo_xml: String = {
                var rv = ""
                
                rv += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                rv += "<!--\n"
                rv += "    autogenerated \(Date.init().description)\n"
                rv += "-->\n"
                rv += "<info>\n"
                rv += "    <version>\(project.versionInfo.bundleShortVersionString)</version>\n"
                rv += "    <releaseDate>\(project.sparkle.releaseDate)</releaseDate>\n"
                rv += "    <sizeInMB>\(project.pathToPKG.physicalSize.compactFormatted)</sizeInMB>\n"
                rv += "</info>\n"
                return rv
            }()
            
            Log4swift[Self.self].info("phpInfo_xml: '\(phpInfo_xml)'")
            do {
                let fileURL = project.sparkle.releaseURL.appendingPathComponent("phpInfo.xml")
                try phpInfo_xml.write(to: fileURL, atomically: true, encoding: .utf8)
                Log4swift[Self.self].info("updated: '\(fileURL.path)'")
            } catch {
                Log4swift[Self.self].error("error: '\(error.localizedDescription)'")
            }
        }
    }
    
    public func packageTips() {
        Log4swift[Self.self].info("package: '\(project.configName)' \(actionDivider())")

        let packageFolder = "\(project.packageName)_\(project.versionInfo.bundleShortVersionString)"
        var packageTips = [String]()

        if project.packageIdentifier.hasPrefix("com.id-design") {
            let WEBSERVER_ROOT = "/var/www/www.whatsizemac.com/downloads"
            let WEBSITE_URL = "https://www.whatsizemac.com"
            let WEBSITE_REPO = URL.home.appendingPathComponent("Development/git.id-design.com/website")

            packageTips.append("")
            packageTips.append("")
            packageTips.append("# LIVE package upload ...")
            packageTips.append("# These commands will update the files DIRECTLY")
            packageTips.append("# Changes will happen immediately live, not recommended")
            packageTips.append("\(WEBSITE_URL)/downloads/\(packageFolder.lowercased()).pkg")
            packageTips.append("--- --- --- --- ---")
            packageTips.append(" # scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(project.sparkle.sshUserName):\(WEBSERVER_ROOT)/\(packageFolder.lowercased()).pkg")
            packageTips.append(" # scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).tgz \(project.sparkle.sshUserName):\(project.sparkle.serverFileURL)/\(packageFolder.lowercased()).tgz")
            packageTips.append(" # scp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(project.sparkle.sshUserName):\(project.sparkle.serverFileURL)/\(project.packageName.lowercased()).pkg")
            packageTips.append(" # scp -r \(project.sparkle.releaseURL.path)/ \(project.sparkle.sshUserName):\(project.sparkle.serverFileURL)/")
            packageTips.append("")
            packageTips.append("")
            packageTips.append("# MANUAL, files will be pushed into the local git repo ...")
            packageTips.append("# Validate/Test locally than push to the remote: '\(WEBSITE_REPO.path)'")
            packageTips.append("# When ready sync the live server with this repo to see Sparkle and WebSite changes ...")
            packageTips.append("--- --- --- --- ---")
            packageTips.append("   cp -R ~/Development/git.id-design.com/whatsize7/WhatSize/release \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/")
            packageTips.append("   cp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).tgz \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/\(packageFolder.lowercased()).tgz")
            packageTips.append("   cp ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg \(WEBSITE_REPO.path)/www.whatsizemac.com/software/whatsize7/\(project.packageName.lowercased()).pkg")

        } else if project.packageIdentifier.hasPrefix("com.other") {
            packageTips.append("")
        }
        
        packageTips.append("")
        packageTips.append("")
        packageTips.append("--- --- --- --- --- ---")
        packageTips.append("Install the package locally and test ...")
        packageTips.append("sudo installer -verbose -pkg ~/Desktop/Packages/\(packageFolder)/\(project.packageName).pkg -target /")
        packageTips.append("")
        Log4swift[Self.self].info("\(packageTips.joined(separator: "\n"))")
    }
}
