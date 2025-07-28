//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan Yip on 7/25/25.
//  Refactored for efficiency & maintainability
//

import SwiftUI

// MARK: - Models

struct Option: Identifiable, Equatable {
    let id: Int
    let icon: String
    let text: String
}

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case fitness
    case why
    case streak
    case challenges
    case final

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fitness:      return "Fitness reimagined."
        case .why:          return "What's your \"why\" for showing up?"
        case .streak:       return "When it comes to streaks, what's your relationship status?"
        case .challenges:   return "You've got 15 minutes a day. Be honest — what are we up against?"
        case .final:        return "Ready to build your city?"
        }
    }

    var subtitle: String? {
        switch self {
        case .fitness:
            return "BUILD A CITY WHILE YOU MOVE"
        case .why:
            return "(Yes, existential dread counts.)"
        case .streak:
            return "(We're all commitment-phobic at some point. It's okay.)"
        case .challenges:
            return "(We respect your battle.)"
        case .final:
            return "Your journey starts now."
        }
    }

    var titleFont: Font {
        switch self {
        case .fitness, .final:
            return .system(size: 28, weight: .bold, design: .rounded)
        case .why:
            return .system(size: 24, weight: .bold, design: .rounded)
        case .streak:
            return .system(size: 22, weight: .bold, design: .rounded)
        case .challenges:
            return .system(size: 20, weight: .bold, design: .rounded)
        }
    }

    /// Options shown for the step (nil for the last one)
    var options: [Option]? {
        switch self {
        case .fitness:
            return [
                .init(id: 0, icon: "🎯", text: "Finally sticking to something for more than 3 days"),
                .init(id: 1, icon: "🏙️", text: "Watching my city not look like a sad parking lot"),
                .init(id: 2, icon: "🥔", text: "Feeling less like a potato with legs"),
                .init(id: 3, icon: "✨", text: "Lowkey trying to become that *person*")
            ]
        case .why:
            return [
                .init(id: 0, icon: "✅", text: "I like structure and progress"),
                .init(id: 1, icon: "🎭", text: "I want to impress someone (maybe myself)"),
                .init(id: 2, icon: "🧃", text: "I want to feel better (emotionally, physically, spiritually, digestively)"),
                .init(id: 3, icon: "❓", text: "Honestly, no clue — but I'm here, so let's see what happens")
            ]
        case .streak:
            return [
                .init(id: 0, icon: "🔓", text: "\"Day one\" is my natural habitat"),
                .init(id: 1, icon: "🫣", text: "I ghost after 3 days, but I come back eventually"),
                .init(id: 2, icon: "🧱", text: "I'm ready to build something steady — like a responsible adult (kind of)"),
                .init(id: 3, icon: "🔥", text: "I'm unhinged and addicted to green checkmarks")
            ]
        case .challenges:
            return [
                .init(id: 0, icon: "🛋️", text: "The gravitational pull of my couch"),
                .init(id: 1, icon: "📱", text: "An endless scroll that started \"just for a sec\""),
                .init(id: 2, icon: "🧩", text: "Literally every other responsibility in my life"),
                .init(id: 3, icon: "💪", text: "Nothing. This is my time now")
            ]
        case .final:
            return nil
        }
    }

    static var total: Int { Self.allCases.count }
}

// MARK: - ViewModel

final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .fitness
    @Published var selected: [OnboardingStep: Int] = [:]
    @Published var showingMainApp = false
    @Published var isTransitioning = false

    func select(_ optionID: Int, in step: OnboardingStep) {
        guard !isTransitioning else { return }
        selected[step] = optionID
        selectAndAdvance()
    }

    private func selectAndAdvance() {
        isTransitioning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                if let next = OnboardingStep(rawValue: self.currentStep.rawValue + 1) {
                    self.currentStep = next
                }
                self.isTransitioning = false
            }
        }
    }

    func back() {
        guard currentStep.rawValue > 0 else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .fitness
        }
    }

    func next() {
        guard currentStep.rawValue < OnboardingStep.total - 1 else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .final
        }
    }

    func startApp() {
        withAnimation(.easeInOut(duration: 0.8)) {
            showingMainApp = true
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if vm.showingMainApp {
                MainAppView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                VStack(spacing: 0) {
                    ProgressIndicator(currentIndex: vm.currentStep.rawValue, total: OnboardingStep.total)
                        .padding(.top, 40)
                        .padding(.horizontal, 20)

                    TabView(selection: $vm.currentStep) {
                        ForEach(OnboardingStep.allCases) { step in
                            Group {
                                if let options = step.options {
                                    OnboardingPanel(
                                        step: step,
                                        options: options,
                                        selectedID: Binding(
                                            get: { vm.selected[step] },
                                            set: { _ in } // selection handled inside select()
                                        ),
                                        onSelect: { id in vm.select(id, in: step) }
                                    )
                                } else {
                                    FinalPanel()
                                }
                            }
                            .tag(step)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: vm.currentStep)

                    NavigationButtons(
                        currentIndex: vm.currentStep.rawValue,
                        total: OnboardingStep.total,
                        onBack: vm.back,
                        onNext: vm.next,
                        onStart: vm.startApp
                    )
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentIndex ? Color.gold : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
    }
}

// MARK: - Generic Onboarding Panel

struct OnboardingPanel: View {
    let step: OnboardingStep
    let options: [Option]
    @Binding var selectedID: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            VStack(spacing: 15) {
                Text(step.title)
                    .font(step.titleFont)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                if let subtitle = step.subtitle {
                    if step == .fitness {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gold)
                            .tracking(2)
                    } else {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gold)
                            .italic()
                    }
                }

                if step == .fitness {
                    Text("What kind of progress are you secretly hoping to see?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }

            VStack(spacing: 12) {
                ForEach(options) { option in
                    SelectionOption(
                        icon: option.icon,
                        text: option.text,
                        isSelected: selectedID == option.id,
                        action: { onSelect(option.id) }
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}

// MARK: - Final Panel

struct FinalPanel: View {
    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            VStack(spacing: 15) {
                Text("Ready to build your city?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your journey starts now.")
                    .font(.title3)
                    .foregroundColor(.gold)
            }

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

// MARK: - Navigation

struct NavigationButtons: View {
    let currentIndex: Int
    let total: Int
    let onBack: () -> Void
    let onNext: () -> Void
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            if currentIndex > 0 {
                Button("Back", action: onBack)
                    .buttonStyle(GlassButtonStyle())
            }

            Spacer()

            if currentIndex < total - 1 {
                Button("Next", action: onNext)
                    .buttonStyle(GlassButtonStyle())
            } else {
                Button("Start Building", action: onStart)
                    .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Reusable bits

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
                            .stroke(Color.gold.opacity(0.4), lineWidth: 1)
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

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Main App View (Placeholder)

// MARK: - Main App View (Improved Welcome Screen)

struct MainAppView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.85)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.gold)
                        .scaleEffect(pulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

                    Text("Welcome to CRDO")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Your city awaits...")
                        .font(.title3)
                        .foregroundColor(.gold)
                        .italic()
                }

                GlassCard {
                    VStack(spacing: 16) {
                        Text("Start strong. Build daily. Earn every block.")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("This is fitness with a purpose.")
                            .font(.subheadline)
                            .foregroundColor(.gold)
                            .italic()
                    }
                    .padding(25)
                }

                Spacer()

                Button(action: {
                    // Placeholder action (can route to dashboard)
                }) {
                    Text("Enter Your City")
                        .font(.headline)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 30)
            .onAppear {
                pulse = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

