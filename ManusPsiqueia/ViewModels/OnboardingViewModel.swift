//
//  OnboardingViewModel.swift
//  ManusPsiqueia
//
//  Created by AiLun Tecnologia on 2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentPage = 0
    @Published var showUserTypeSelection = false
    @Published var animateGradient = false
    @Published var particleOffset: CGFloat = 0
    @Published var error: IdentifiableError?
    
    // MARK: - Private Properties
    
    private var animationTimer: Timer?
    private let pages = OnboardingPage.allPages
    
    // MARK: - Computed Properties
    
    var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    var shouldShowSkipButton: Bool {
        currentPage < pages.count - 1
    }
    
    // MARK: - Actions
    
    func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animateGradient = true
        }
        
        startParticleAnimation()
    }
    
    func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    func nextPage() {
        guard currentPage < pages.count - 1 else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }
    
    func showUserSelection() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showUserTypeSelection = true
        }
    }
    
    func hideUserSelection() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showUserTypeSelection = false
        }
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func startParticleAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                withAnimation(.linear(duration: 0.1)) {
                    self.particleOffset += 1
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    deinit {
        stopAnimations()
    }
}

// MARK: - Supporting Types

struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: Error
    
    var localizedDescription: String {
        if let localizedError = error as? LocalizedError {
            return localizedError.localizedDescription
        }
        return error.localizedDescription
    }
}