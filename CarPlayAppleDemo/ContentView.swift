import SwiftUI

struct ContentView: View {
    #if os(iOS)
    @StateObject private var tapLog = CarPlayTapLog.shared
    #endif

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 16) {
            Text("CarPlay Header Tap Sample")
                .font(.title.bold())
            Text("Open this app on CarPlay to try the Continue Trip and Next Stop buttons in the trip and day headers.")
            LabeledContent("Continue Trip callbacks", value: "\(tapLog.continueTripCount)")
            LabeledContent("Next Stop callbacks", value: "\(tapLog.nextStopCount)")
            Text(tapLog.lastAction)
                .font(.headline)
        }
        .padding()
        #else
        Text("This CarPlay sample runs on iPhone.")
            .padding()
        #endif
    }
}

#Preview {
    ContentView()
}
