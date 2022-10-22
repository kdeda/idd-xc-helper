//
//  Workspace.swift
//  xchelper
//
//  Created by Klajd Deda on 10/23/22.
//

import Foundation

extension Workspace {
    var expandingTilde: Workspace {
        var rv = self
        
        rv.workspaceURL = self.workspaceURL.expandingTilde!
        return rv
    }
}
