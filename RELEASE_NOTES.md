# Release Notes - Joy TV v1.2.0

This release focuses on optimizing the user experience for Android TV and remote-controlled devices, while streamlining input handling on mobile.

## 📺 Android TV & D-Pad Optimization
- **Unified Navigation Logic**: Replaced all manual focus and key event handling with the `dpad` package.
- **Global D-Pad Support**: Added `DpadNavigator` at the root to manage focus traversal across the entire app.
- **Improved Focusable Widgets**:
  - **Sidebar**: Now supports smooth navigation between "Live TV," "Movies," and "Settings."
  - **Channel Cards**: Enhanced with visual focus effects (scaling and colored borders) specifically for D-pad users.
  - **Source Picker**: Redesigned source/playlist selection to be fully navigable via remote control.
  - **Player Controls**: All playback buttons (Play/Pause, Prev/Next, Toggle List) now respond to the DPAD center key.
- **Native Input**: Integrated `android_tv_text_field` to provide a superior search experience on TV platforms, including a focusable "Clear" button.

## 📱 Mobile Improvements
- **Automatic Orientation Handling**: The player screen now automatically rotates to landscape on smartphones for full-screen viewing and returns to portrait when navigating back.
- **Responsive Layouts**: Refined sidebar and grid spacing for consistent visuals on both handheld and TV screens.

## 🛠 Fixes & Internal Changes
- **Simplified Flutter Code**: Migrated redundant `Focus` and `Stateful` widget logic into declarative `DpadFocusable` builders, reducing code complexity.
- **Focus Resilience**: Fixed issues where focus could be lost when switching between search results and channel details.

---
*Version: 1.2.0 (Build 2)*
