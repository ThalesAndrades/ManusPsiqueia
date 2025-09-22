//
//  AdvancedScrollView.swift
//  ManusPsiqueia
//
//  Created by AiLun Team on 19/01/2024.
//  Copyright © 2024 AiLun Tecnologia. All rights reserved.
//

import SwiftUI

/// Advanced ScrollView with enhanced usability features for mental health platform
struct AdvancedScrollView<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    let bounces: Bool
    let onRefresh: (() async -> Void)?
    
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(
        showsIndicators: Bool = true,
        bounces: Bool = true,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.showsIndicators = showsIndicators
        self.bounces = bounces
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .top) {
                    // Pull-to-refresh indicator
                    if let onRefresh = onRefresh {
                        PullToRefreshView(
                            isRefreshing: $isRefreshing,
                            onRefresh: onRefresh
                        )
                        .offset(y: -50)
                    }
                    
                    // Main content with scroll tracking
                    LazyVStack(spacing: 0) {
                        content
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: contentGeometry.frame(in: .named("scroll")).minY
                                        )
                                }
                            )
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .scrollIndicators(showsIndicators ? .visible : .hidden)
            .scrollBounceBehavior(bounces ? .basedOnSize : .never)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                withAnimation(.easeInOut(duration: 0.1)) {
                    scrollOffset = value
                }
                
                // Haptic feedback for scroll milestones
                if abs(value) > 100 && abs(scrollOffset - value) > 50 {
                    hapticFeedback.impactOccurred()
                }
            }
            .refreshable {
                if let onRefresh = onRefresh {
                    await onRefresh()
                }
            }
        }
    }
}

/// Pull-to-refresh component with mental health themed design
struct PullToRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 30, height: 30)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(rotationAngle))
            }
            
            Text("Atualizando bem-estar...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .opacity(isRefreshing ? 1 : 0)
        .scaleEffect(isRefreshing ? 1 : 0.8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isRefreshing)
        .onAppear {
            if isRefreshing {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
        .task {
            if isRefreshing {
                await onRefresh()
                isRefreshing = false
                rotationAngle = 0
            }
        }
    }
}

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Advanced scroll view with parallax effect for headers
struct ParallaxScrollView<Header: View, Content: View>: View {
    let header: Header
    let content: Content
    let headerHeight: CGFloat
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        headerHeight: CGFloat = 200,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.headerHeight = headerHeight
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Parallax header
                    GeometryReader { headerGeometry in
                        header
                            .frame(
                                width: geometry.size.width,
                                height: headerHeight + max(0, -scrollOffset)
                            )
                            .offset(y: scrollOffset > 0 ? -scrollOffset * 0.5 : 0)
                            .clipped()
                    }
                    .frame(height: headerHeight)
                    
                    // Main content
                    content
                        .background(Color(.systemBackground))
                }
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: contentGeometry.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
    }
}

/// Smooth scroll to top functionality
extension View {
    func scrollToTop(with scrollReader: ScrollViewReader, id: String = "top") -> some View {
        self.onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.8)) {
                scrollReader.scrollTo(id, anchor: .top)
            }
        }
    }
}

#Preview {
    AdvancedScrollView(onRefresh: {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }) {
        LazyVStack(spacing: 16) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        Text("Item \(index + 1)")
                            .font(.headline)
                            .foregroundColor(.primary)
                    )
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    .preferredColorScheme(.light)
}
