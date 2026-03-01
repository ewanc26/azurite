//
//  EnvironmentKeys.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import SwiftUI

// MARK: - isFocused

/// True on the focal post inside a thread view — enlarges text and removes line limits.
private struct IsFocusedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isFocused: Bool {
        get { self[IsFocusedKey.self] }
        set { self[IsFocusedKey.self] = newValue }
    }
}
