//
//  Logger.swift
//  SmokingDetection
//
//  Created by Dmitriy Permyakov on 26.05.2024.
//

import Foundation

final class Logger {

    static func log(_ kind: Kind = .info, message: Any...) {
        #if DEBUG
        print("[ \(kind.rawValue.uppercased()) ]", "[ \(Date()) ]", message)
        #endif
    }

    enum Kind: String {
        case info = "ℹ️ info"
        case error = "⛔️ error"
    }
}
