//
//  ProductFile.swift
//  xchelper
//
//  Created by Klajd Deda on 10/23/22.
//

import Foundation

extension ProductFile {
    var expandingTilde: ProductFile {
        var rv = self

        rv.sourceURL = self.buildProductsURL.appendingPathComponent(self.sourceURL.path)
        if let entitlementsURL = entitlementsURL, !entitlementsURL.path.isEmpty {
            rv.entitlementsURL = entitlementsURL.expandingTilde!
        }
        return rv
    }

    var entitlementsPath: String {
        guard let entitlementsURL = entitlementsURL
        else { return "" }

        return entitlementsURL.path
    }
}
