//
//  ErrorStateView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Search Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorStateView(message: "Network request failed.") {}
}
