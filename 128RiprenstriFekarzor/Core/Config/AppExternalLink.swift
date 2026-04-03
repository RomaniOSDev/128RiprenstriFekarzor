//
//  AppExternalLink.swift
//  128RiprenstriFekarzor
//

import Foundation

enum AppExternalLink: String {
    case privacyPolicy = "https://riprenstrifekarzor128.site/privacy/78"
    case termsOfUse = "https://riprenstrifekarzor128.site/terms/78"

    var url: URL? {
        URL(string: rawValue)
    }
}
