import ManusPsiqueiaCore
//
//  LoadingView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

public struct LoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading spinner
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.2, blue: 0.8),
                            Color(red: 0.2, green: 0.6, blue: 0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            Text("Carregando...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

public struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

