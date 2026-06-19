import SwiftUI

struct SourcePickerView: View {
    @AppStorage("sourcePreference") private var rawPreference: String = SourcePreference.auto.rawValue

    private var preference: Binding<SourcePreference> {
        Binding(
            get: { SourcePreference(rawValue: rawPreference) ?? .auto },
            set: { rawPreference = $0.rawValue }
        )
    }

    var body: some View {
        Picker("Music source", selection: preference) {
            ForEach(SourcePreference.allCases) { p in
                Text(p.displayName).tag(p)
            }
        }
        .pickerStyle(.menu)
    }
}
