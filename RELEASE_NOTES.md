# Release Notes - Joy TV v1.3.0

This release introduces automated daily playlist updates through GitHub Actions, ensuring our default playlist is always fresh and verified. This update also brings enhancements to our internal streaming engine and discovery visuals.

## 🚀 Automated Playlist Engine
- **Daily Updates**: Integrated GitHub Actions to automatically regenerate and verify the combined playlist every 24 hours.
- **"Joy TV (Combined)" Source**: Added as the new default source, combining all IPTV links into one verified, deduplicated list.
- **Smart Link Verification**: Our Python-based generator now performs 100+ parallel health checks per second to prune broken links.
- **Automation Tools**: New `scripts/` directory with easy-to-use Bash and Python tools for manual generation.

## 📺 Enhanced Streaming & UI Experience
- **Consolidated Search & Filter**: Improved categorization and search logic to handle our massive unified list (40k+ entries).
- **Discovery Visuals**: Refined item scaling and border effects on the "Discovery" screen for better remote navigation.
- **Better Date Handling**: Optimized date parsing across all content models with new extensions.

## 🛠 Internal Improvements
- **Security & Stability**: Implemented self-reference protection in the playlist generator.
- **GitHub Workflow Support**: Full CI/CD support for the playlist generation engine.

---
*Version: 1.3.0 (Build 3)*

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
