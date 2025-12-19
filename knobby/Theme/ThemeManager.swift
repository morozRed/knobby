import SwiftUI

@Observable
final class ThemeManager {
    var isDarkMode: Bool = false

    // MARK: - Surface Colors

    var surface: Color {
        isDarkMode ? KnobbyColors.surfaceDarkMode : KnobbyColors.surface
    }

    var surfaceLight: Color {
        isDarkMode ? KnobbyColors.surfaceLightDarkMode : KnobbyColors.surfaceLight
    }

    var surfaceMid: Color {
        isDarkMode ? KnobbyColors.surfaceMidDarkMode : KnobbyColors.surfaceMid
    }

    var surfaceDark: Color {
        isDarkMode ? KnobbyColors.surfaceDarkDarkMode : KnobbyColors.surfaceDark
    }

    // MARK: - Shadow Colors

    var shadowDark: Color {
        isDarkMode ? KnobbyColors.shadowDarkDarkMode : KnobbyColors.shadowDark
    }

    var shadowLight: Color {
        isDarkMode ? KnobbyColors.shadowLightDarkMode : KnobbyColors.shadowLight
    }

    // MARK: - Text Colors

    var textPrimary: Color {
        isDarkMode ? KnobbyColors.textOnDark : KnobbyColors.textPrimary
    }

    var textSubtle: Color {
        isDarkMode ? Color.white.opacity(0.5) : KnobbyColors.textSubtle
    }

    // MARK: - Actions

    func toggle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
}
