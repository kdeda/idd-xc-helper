//
//  Sparkle.swift
//  xchelper
//
//  Created by Klajd Deda on 10/22/22.
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
