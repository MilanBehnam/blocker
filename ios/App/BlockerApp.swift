import FamilyControls
import SwiftUI

@main
struct BlockerApp: App {
    @State private var picked = selection
    @State private var picking = false
    @State private var failure: String?

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Text(isActive() ? "Blocking until \(endHour):00" : "Blocks Mon–Fri \(startHour):00–\(endHour):00").font(.title2)
                Text(sites.joined(separator: ", ")).font(.footnote).foregroundStyle(.secondary)
                // Like install.sh: no changes during block hours.
                Button("Choose apps & sites") { picking = true }.disabled(isActive())
                if let failure { Text(failure).foregroundStyle(.red) }
            }
            .padding()
            .familyActivityPicker(isPresented: $picking, selection: $picked)
            .onChange(of: picked) { selection = picked }
            .task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    try startSchedule()
                    if isActive() { block() } // the monitor only fires at the next 9:00
                } catch {
                    failure = error.localizedDescription
                }
            }
        }
    }
}
