//
//  Workspace.swift
//  xchelper
//
//  Created by Klajd Deda on 10/23/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

extension Workspace {
    var expandingTilde: Workspace {
        var rv = self
        
        rv.workspaceURL = self.workspaceURL.expandingTilde!
        return rv
    }
}
