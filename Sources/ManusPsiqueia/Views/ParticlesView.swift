//
//  ParticlesView.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

struct ParticlesView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    private func generateParticles() {
        particles = (0..<50).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 1...4),
                color: [
                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.6),
                    Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.4),
                    Color.white.opacity(0.3)
                ].randomElement()!,
                opacity: Double.random(in: 0.2...0.8),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                for index in particles.indices {
                    particles[index].position.x += CGFloat.random(in: -1...1)
                    particles[index].position.y += CGFloat.random(in: -1...1)
                    particles[index].opacity = Double.random(in: 0.1...0.8)
                }
            }
        }
    }
}

struct ParticlesView_Previews: PreviewProvider {
    static var previews: some View {
        ParticlesView()
    }
}

