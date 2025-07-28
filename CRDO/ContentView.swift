//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan yip on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentPanel = 0
    @State private var selectedOptions: [Int] = []
    @State private var showingMainApp = false
    @State private var isTransitioning = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if showingMainApp {
                MainAppView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Landing panels
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressIndicator(currentPanel: currentPanel, totalPanels: 5)
                        .padding(.top, 40)
                        .padding(.horizontal, 20)
                    
                    // Panel content
                    TabView(selection: $currentPanel) {
                        // Panel 1: Fitness reimagined
                        Panel1View(selectedOptions: $selectedOptions, currentPanel: $currentPanel, isTransitioning: $isTransitioning)
                            .tag(0)
                        
                        // Panel 2: What's your why
                        Panel2View(selectedOptions: $selectedOptions, currentPanel: $currentPanel, isTransitioning: $isTransitioning)
                            .tag(1)
                        
                        // Panel 3: Streak relationship
                        Panel3View(selectedOptions: $selectedOptions, currentPanel: $currentPanel, isTransitioning: $isTransitioning)
                            .tag(2)
                        
                        // Panel 5: Daily challenges
                        Panel5View(selectedOptions: $selectedOptions, currentPanel: $currentPanel, isTransitioning: $isTransitioning)
                            .tag(3)
                        
                        // Panel 6: Final motivation
                        Panel6View()
                            .tag(4)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentPanel)
                    
                    // Navigation buttons
                    NavigationButtons(
                        currentPanel: $currentPanel,
                        totalPanels: 5,
                        showingMainApp: $showingMainApp
                    )
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let currentPanel: Int
    let totalPanels: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPanels, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentPanel ? Color.gold : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentPanel)
            }
        }
    }
}

// MARK: - Panel 1: Fitness Reimagined
struct Panel1View: View {
    @Binding var selectedOptions: [Int]
    @Binding var currentPanel: Int
    @Binding var isTransitioning: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main heading
            VStack(spacing: 15) {
                Text("Fitness reimagined.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("BUILD A CITY WHILE YOU MOVE")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gold)
                    .tracking(2)
            }
            
            Text("What kind of progress are you secretly hoping to see?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Progress options
            VStack(spacing: 10) {
                SelectionOption(
                    icon: "🎯",
                    text: "Finally sticking to something for more than 3 days",
                    isSelected: selectedOptions.contains(12),
                    action: { if !isTransitioning { toggleSelection(12) } }
                )
                
                SelectionOption(
                    icon: "🏙️",
                    text: "Watching my city not look like a sad parking lot",
                    isSelected: selectedOptions.contains(13),
                    action: { if !isTransitioning { toggleSelection(13) } }
                )
                
                SelectionOption(
                    icon: "🥔",
                    text: "Feeling less like a potato with legs",
                    isSelected: selectedOptions.contains(14),
                    action: { if !isTransitioning { toggleSelection(14) } }
                )
                
                SelectionOption(
                    icon: "✨",
                    text: "Lowkey trying to become that *person*",
                    isSelected: selectedOptions.contains(15),
                    action: { if !isTransitioning { toggleSelection(15) } }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func toggleSelection(_ index: Int) {
        selectedOptions.removeAll { $0 >= 12 && $0 <= 15 } // Clear previous selections for panel 1
        selectedOptions.append(index)
        
        // Set transitioning state to prevent further selections
        isTransitioning = true
        
        // Auto-advance to next panel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPanel += 1
                isTransitioning = false // Reset transitioning state
            }
        }
    }
}

// MARK: - Panel 2: What's your why
struct Panel2View: View {
    @Binding var selectedOptions: [Int]
    @Binding var currentPanel: Int
    @Binding var isTransitioning: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main heading
            VStack(spacing: 15) {
                Text("What's your \"why\" for showing up?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("(Yes, existential dread counts.)")
                    .font(.subheadline)
                    .foregroundColor(.gold)
                    .italic()
            }
            
            // Options
            VStack(spacing: 12) {
                SelectionOption(
                    icon: "✅",
                    text: "I like structure and progress",
                    isSelected: selectedOptions.contains(0),
                    action: { if !isTransitioning { toggleSelection(0) } }
                )
                
                SelectionOption(
                    icon: "🎭",
                    text: "I want to impress someone (maybe myself)",
                    isSelected: selectedOptions.contains(1),
                    action: { if !isTransitioning { toggleSelection(1) } }
                )
                
                SelectionOption(
                    icon: "🧃",
                    text: "I want to feel better (emotionally, physically, spiritually, digestively)",
                    isSelected: selectedOptions.contains(2),
                    action: { if !isTransitioning { toggleSelection(2) } }
                )
                
                SelectionOption(
                    icon: "❓",
                    text: "Honestly, no clue — but I'm here, so let's see what happens",
                    isSelected: selectedOptions.contains(3),
                    action: { if !isTransitioning { toggleSelection(3) } }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func toggleSelection(_ index: Int) {
        selectedOptions.removeAll { $0 >= 0 && $0 <= 3 }  // Clear previous selections
        selectedOptions.append(index)
        
        // Set transitioning state to prevent further selections
        isTransitioning = true
        
        // Auto-advance to next panel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPanel += 1
                isTransitioning = false // Reset transitioning state
            }
        }
    }
}

// MARK: - Panel 3: Streak relationship
struct Panel3View: View {
    @Binding var selectedOptions: [Int]
    @Binding var currentPanel: Int
    @Binding var isTransitioning: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main heading
            VStack(spacing: 15) {
                Text("When it comes to streaks, what's your relationship status?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("(We're all commitment-phobic at some point. It's okay.)")
                    .font(.subheadline)
                    .foregroundColor(.gold)
                    .italic()
            }
            
            // Options
            VStack(spacing: 12) {
                SelectionOption(
                    icon: "🔓",
                    text: "\"Day one\" is my natural habitat",
                    isSelected: selectedOptions.contains(4),
                    action: { if !isTransitioning { toggleSelection(4) } }
                )
                
                SelectionOption(
                    icon: "🫣",
                    text: "I ghost after 3 days, but I come back eventually",
                    isSelected: selectedOptions.contains(5),
                    action: { if !isTransitioning { toggleSelection(5) } }
                )
                
                SelectionOption(
                    icon: "🧱",
                    text: "I'm ready to build something steady — like a responsible adult (kind of)",
                    isSelected: selectedOptions.contains(6),
                    action: { if !isTransitioning { toggleSelection(6) } }
                )
                
                SelectionOption(
                    icon: "🔥",
                    text: "I'm unhinged and addicted to green checkmarks",
                    isSelected: selectedOptions.contains(7),
                    action: { if !isTransitioning { toggleSelection(7) } }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func toggleSelection(_ index: Int) {
        selectedOptions.removeAll { $0 >= 4 && $0 <= 7 } // Clear previous selections
        selectedOptions.append(index)
        
        // Set transitioning state to prevent further selections
        isTransitioning = true
        
        // Auto-advance to next panel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPanel += 1
                isTransitioning = false // Reset transitioning state
            }
        }
    }
}



// MARK: - Panel 5: Daily challenges
struct Panel5View: View {
    @Binding var selectedOptions: [Int]
    @Binding var currentPanel: Int
    @Binding var isTransitioning: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main heading
            VStack(spacing: 15) {
                Text("You've got 15 minutes a day. Be honest — what are we up against?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("(We respect your battle.)")
                    .font(.subheadline)
                    .foregroundColor(.gold)
                    .italic()
            }
            
            // Options
            VStack(spacing: 12) {
                SelectionOption(
                    icon: "🛋️",
                    text: "The gravitational pull of my couch",
                    isSelected: selectedOptions.contains(8),
                    action: { if !isTransitioning { toggleSelection(8) } }
                )
                
                SelectionOption(
                    icon: "📱",
                    text: "An endless scroll that started \"just for a sec\"",
                    isSelected: selectedOptions.contains(9),
                    action: { if !isTransitioning { toggleSelection(9) } }
                )
                
                SelectionOption(
                    icon: "🧩",
                    text: "Literally every other responsibility in my life",
                    isSelected: selectedOptions.contains(10),
                    action: { if !isTransitioning { toggleSelection(10) } }
                )
                
                SelectionOption(
                    icon: "💪",
                    text: "Nothing. This is my time now",
                    isSelected: selectedOptions.contains(11),
                    action: { if !isTransitioning { toggleSelection(11) } }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private func toggleSelection(_ index: Int) {
        selectedOptions.removeAll { $0 >= 8 && $0 <= 11 } // Clear previous selections
        selectedOptions.append(index)
        
        // Set transitioning state to prevent further selections
        isTransitioning = true
        
        // Auto-advance to next panel after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPanel += 1
                isTransitioning = false // Reset transitioning state
            }
        }
    }
}

// MARK: - Panel 6: Final motivation
struct Panel6View: View {
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Main heading
            VStack(spacing: 15) {
                Text("Ready to build your city?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your journey starts now.")
                    .font(.title3)
                    .foregroundColor(.gold)
            }
            
            // Final motivation card
            GlassCard {
                VStack(spacing: 20) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gold)
                    
                    Text("Every step counts. Every run builds. Every streak matters.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's make discipline feel different.")
                        .font(.headline)
                        .foregroundColor(.gold)
                        .italic()
                }
                .padding(25)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @Binding var currentPanel: Int
    let totalPanels: Int
    @Binding var showingMainApp: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            if currentPanel > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPanel -= 1
                    }
                }
                .buttonStyle(GlassButtonStyle())
            }
            
            Spacer()
            
            if currentPanel < totalPanels - 1 {
                                    Button("Next") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPanel += 1
                        }
                    }
                .buttonStyle(GlassButtonStyle())
            } else {
                Button("Start Building") {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showingMainApp = true
                    }
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Supporting Views
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                Color.gold.opacity(0.4),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .gold.opacity(0.3), radius: 10, x: 0, y: 5)
            )
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gold, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ProgressOption: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SelectionOption: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(icon)
                    .font(.title2)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gold)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.gold.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Extensions
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Main App View (Placeholder)
struct MainAppView: View {
    var body: some View {
        VStack {
            Text("Welcome to CRDO!")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text("Your city awaits...")
                .font(.title2)
                .foregroundColor(.gold)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

#Preview {
    ContentView()
}
