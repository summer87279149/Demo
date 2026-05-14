//
//  LoadingView.swift
//  Demo
//
//  Created by xiatian on 5/14/26.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)
            ProgressView("Loading")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
