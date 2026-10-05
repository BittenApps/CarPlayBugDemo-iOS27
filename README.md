# CarPlayBugDemo-iOS27

Minimal CarPlay sample that reproduces a hit-testing bug: an enabled `CPButton` in a
`CPListTemplateDetailsHeader` does not respond across its full visible area on iOS 27.
Only the upper part of the button fires its handler.

- Forum thread: https://developer.apple.com/forums/thread/849585
- Environment: Xcode 27.0 (27A266a), iOS 27.0, CarPlay Simulator and a real CarPlay display
- Entitlement: `com.apple.developer.carplay-driving-task`

## Reproduce

1. Run on an iOS 27 iPhone with CarPlay connected, or use the CarPlay Simulator.
2. In CarPlay, open the app and select **Coastal Road Trip**.
3. Tap different parts of the **Continue Trip** button. A CarPlay alert appears when the handler fires.
4. Select a day card and repeat with **Next Stop**.

Expected: the action fires from anywhere on the visible button.
Actual: only part of the button responds.

The phone screen and the console also log each callback.
