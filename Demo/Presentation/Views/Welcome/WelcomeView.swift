//
//  WelcomeView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct WelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.largeTitle.bold())
                Text("Search Pokemon species and inspect abilities.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button(action: onStart) {
                Text("Start Searching")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
}
