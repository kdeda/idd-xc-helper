//
//  Sparkle.swift
//  idd-xc-helper
//
//  Created by Klajd Deda on 10/22/22.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

extension Sparkle {
    // ie: Tue, 13 September 2011
    //
    var releaseDate: String {
        let today = Date.init()
        return today.string(withFormat: "EEE, MMMM d, yyyy")
    }
}
