//
//  URL+Extensions.swift
//  xchelper
//
//  Created by Klajd Deda on 10/19/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import IDDSwift

extension URL {
    /**
     The team identifier for the Developer Team to be used with this notarytool subcommand.
     Usually 10 alphanumeric characters.
     Your Apple ID may be a member of multiple teams.
     You can find Team IDs for teams you belong to by going to <https://developer.apple.com/account/#/membership>.
     You cannot get information on Submission IDs created by another wwdr_team_id.
     
     https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/
     
     xcrun notarytool store-credentials --apple-id kdeda@mac.com --team-id ME637H7ZM9
     # enter a name for this profile ie: WhatSizeAppPassword, i'm matching this with the name i put on  https://support.apple.com/en-us/HT204397
     # enter the password, this password should match the one we got from https://support.apple.com/en-us/HT204397
     # profile WhatSizeAppPassword
     # once the WhatSizeAppPassword is created we can just use it
     /usr/bin/xcrun notarytool submit /Users/kdeda/Development/build/Package/WhatSize.pkg --keychain-profile WhatSizeAppPassword --wait
     */
    public func notarize(keychainProfile: String) {
        let arguments = [
            "notarytool",
            "submit", self.path,
            "--keychain-profile", keychainProfile,
            "--wait"
        ]
        
        /*
         let processOutput =
         """
         Conducting pre-submission checks for WhatSize.pkg and initiating connection to the Apple notary service...
         Submission ID received
         id: d6fa0c33-6da9-40cd-9797-427c32dc8fc1
         Successfully uploaded file21.8 MB of 21.9 MB)
         id: d6fa0c33-6da9-40cd-9797-427c32dc8fc1
         path: /Users/kdeda/Development/build/Package/WhatSize.pkg
         Waiting for processing to complete.
         Current status: Accepted..........
         Processing complete
         id: d6fa0c33-6da9-40cd-9797-427c32dc8fc1
         status: Accepted
         """
         */
        
        let processOutput = Process.stdString(taskURL: Dependency.XCRUN, arguments: arguments)
        let tokens = processOutput.components(separatedBy: "\n")

        func uuid(_ tokens: [String]) -> String? {
            return tokens.filter { $0.contains("id:") }.first?.replacingOccurrences(of: "id:", with: "").trimmingCharacters(in: .whitespaces)
        }

        guard let index = tokens.firstIndex(where: { $0.contains("Processing complete") }),
              index + 2 < tokens.count,
              tokens[index + 2].contains("status: Accepted")
        else {
            // find the log id from the response, than pass it along to the task to see the log that apple is sending
            if let uuid = uuid(tokens) {
                let arguments = [
                    "notarytool",
                    "log", uuid,
                    "--keychain-profile", keychainProfile
                ]
                let processOutput = Process.stdString(taskURL: Dependency.XCRUN, arguments: arguments)
                Log4swift[Self.self].info("log: '\(processOutput)'")
            }

            exit(0)
        }
        let uuid = uuid(tokens) ?? "UNKNOWN"
        Log4swift[Self.self].info("received uuid: \(uuid) for: '\(self.path)'")
    }
    
    /**
     Staple the notarization ticket to the file.
     This assumes the file has been notaraized already.
     /usr/bin/stapler staple -v /Users/kdeda/Desktop/Packages/WhatSize_7.3.2/WhatSize.pkg
     */
    var xcrunStaplerStaple: Bool {
        let output = Process.stdString(
            taskURL: Dependency.XCRUN,
            arguments: ["stapler", "staple", "-v", self.path]
        )
        
        if output.contains("The staple and validate action worked") {
            Log4swift[Self.self].info("stapler did work for: '\(self.path)'")
            return true
        }
        Log4swift[Self.self].info("stapler for: '\(self.path)' failed: \(output)")
        return false
    }

    /**
     Validate that staple is ok
     /usr/bin/stapler validate -v /Users/kdeda/Desktop/Packages/WhatSize_7.3.2/WhatSize.pkg
     */
    var xcrunStaplerValidate: Bool {
        let output = Process.stdString(
            taskURL: Dependency.XCRUN,
            arguments: ["stapler", "validate", "-v", self.path]
        )
        
        if output.contains("The validate action worked") {
            Log4swift[Self.self].info("stapler did work for: '\(self.path)'")
            return true
        }
        Log4swift[Self.self].info("stapler for: '\(self.path)' failed: \(output)")
        return false
    }

    var xcrunStaplerStapleAndValidate: Bool {
        xcrunStaplerStaple && xcrunStaplerValidate
    }
}
