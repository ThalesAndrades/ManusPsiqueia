//
//  SplashScreenView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var particlesOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles background
            ParticlesView()
                .opacity(particlesOpacity)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo principal
                VStack(spacing: 20) {
                    // Ícone do app com efeito de glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.brandPrimary.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                        
                        // Custom logo with fallback to system icon
                        Group {
                            if let _ = UIImage(named: "ManusLogo") {
                                Image("ManusLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                            } else {
                                // Fallback to a more sophisticated brain icon
                                ZStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 80, weight: .light))
                                    
                                    // Add "M" overlay for Manus branding
                                    Text("M")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .offset(y: 10)
                                }
                            }
                        }
                        .foregroundStyle(Color.brandGradient)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // Nome do app
                    VStack(spacing: 8) {
                        Text("Manus")
                            .font(.system(size: 42, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Psiqueia")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.brandTextGradient)
                    }
                    .opacity(textOpacity)
                }
                
                Spacer()
                
                // Tagline
                VStack(spacing: 12) {
                    Text("Inteligência Artificial")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("em Saúde Mental")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(logoScale)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: logoScale
                                )
                        }
                    }
                    .padding(.top, 20)
                }
                .opacity(textOpacity)
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                particlesOpacity = 1.0
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}

