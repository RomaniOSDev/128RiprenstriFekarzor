//
//  AppExternalLink.swift
//  128RiprenstriFekarzor
//

import Foundation

enum AppExternalLink: String {
    case privacyPolicy = "https://example.com/privacy-policy"
    case termsOfUse = "https://example.com/terms"

    var url: URL? {
        URL(string: rawValue)
    }
}
