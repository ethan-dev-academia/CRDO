//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan Yip on 7/25/25.
//  Refactored for efficiency & maintainability
//

import SwiftUI
import UserNotifications
import CoreLocation
import MapKit

// MARK: - Models

struct Option: Identifiable, Equatable {
    let id: Int
    let icon: String
    let text: String
}

struct UserPreferences: Codable {
    var fitnessGoal: Int?
    var motivation: Int?
    var streakStyle: Int?
    var challenges: Int?
    var onboardingCompleted: Bool = false
    
    static func load() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return UserPreferences()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
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
    @Published var userPreferences: UserPreferences = UserPreferences.load()

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
        // Save user preferences before starting the app
        saveUserPreferences()
        
        withAnimation(.easeInOut(duration: 0.8)) {
            showingMainApp = true
        }
    }
    
    private func saveUserPreferences() {
        var preferences = UserPreferences()
        preferences.fitnessGoal = selected[.fitness]
        preferences.motivation = selected[.why]
        preferences.streakStyle = selected[.streak]
        preferences.challenges = selected[.challenges]
        preferences.onboardingCompleted = true
        
        preferences.save()
        userPreferences = preferences
    }
}

// MARK: - Root View

struct ContentView: View {
    @StateObject private var vm = OnboardingViewModel()
    @StateObject private var authTracker = AuthenticationTracker.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !authTracker.isAuthenticated {
                AuthenticationView(authTracker: authTracker)
                    .transition(.opacity.combined(with: .scale))
            } else if vm.showingMainApp || vm.userPreferences.onboardingCompleted {
                MainAppView(userPreferences: vm.userPreferences, authTracker: authTracker)
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

// MARK: - User Preferences Summary

struct UserPreferencesSummary: View {
    let preferences: UserPreferences
    
    private func getOptionText(for step: OnboardingStep, optionID: Int?) -> String {
        guard let optionID = optionID,
              let options = step.options else { return "Not selected" }
        
        return options.first { $0.id == optionID }?.text ?? "Not selected"
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text("Your Preferences")
                    .font(.headline)
                    .foregroundColor(.gold)
                
                VStack(spacing: 12) {
                    PreferenceRow(
                        title: "Fitness Goal",
                        text: getOptionText(for: .fitness, optionID: preferences.fitnessGoal),
                        icon: "🎯"
                    )
                    
                    PreferenceRow(
                        title: "Motivation",
                        text: getOptionText(for: .why, optionID: preferences.motivation),
                        icon: "💪"
                    )
                    
                    PreferenceRow(
                        title: "Streak Style",
                        text: getOptionText(for: .streak, optionID: preferences.streakStyle),
                        icon: "🔥"
                    )
                    
                    PreferenceRow(
                        title: "Challenges",
                        text: getOptionText(for: .challenges, optionID: preferences.challenges),
                        icon: "⚡"
                    )
                }
            }
            .padding(20)
        }
    }
}

struct PreferenceRow: View {
    let title: String
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gold)
                    .fontWeight(.semibold)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Top Navigation Bar

struct TopNavigationBar: View {
    @Binding var showingUserSettings: Bool
    @State private var menuAnimation = false
    
    var body: some View {
        HStack {
            // App Title
            Text("CRDO")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.gold)
            
            Spacer()
            
            // Settings Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingUserSettings = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gold)
                        .scaleEffect(menuAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: menuAnimation)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .overlay(
                    Rectangle()
                        .stroke(Color.gold.opacity(0.2), lineWidth: 0.5)
                )
        )
        .ignoresSafeArea(.all, edges: .top)
        .onAppear {
            menuAnimation = true
        }
    }
}

// MARK: - Progress Section

struct ProgressSection: View {
    let progress: Double
    let timeElapsed: Int
    let isActive: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onWorkoutMap: () -> Void
    let currentStreak: Int
    @Binding var showingUserSettings: Bool
    @Binding var userSettingsInitialTab: Int
    
    @State private var glowAnimation = false
    @State private var pulseAnimation = false
    
    private var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressTitle: String {
        if isActive {
            return "WORKOUT IN PROGRESS"
        } else {
            return "DAILY GOAL: 15 MIN"
        }
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    private var dynamicTitle: String {
        let dayNumber = currentStreak + 1 // Add 1 because we're on the current day
        let suffix = getDaySuffix(dayNumber)
        return "\(dayNumber)\(suffix) DAILY CRDO"
    }
    
    private func getDaySuffix(_ day: Int) -> String {
        if day >= 11 && day <= 13 {
            return "TH"
        }
        
        switch day % 10 {
        case 1:
            return "ST"
        case 2:
            return "ND"
        case 3:
            return "RD"
        default:
            return "TH"
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            VStack(spacing: 8) {
                Text(progressTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
            }
            
            // Progress Circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
            LinearGradient(
                            gradient: Gradient(colors: [.gold, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                // Glow effect
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.gold.opacity(0.3), lineWidth: 20)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: glowAnimation ? 8 : 4)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowAnimation)
                
                // Center content
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("\(progressPercentage)%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gold)
                    
                    Text("STREAK MAINTAINED: \(currentStreak)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.gold.opacity(0.8))
                        .tracking(1)
                    
                    if isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                            
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            

            
            // Compact Glassy Button Grid
            VStack(spacing: 12) {
                // Main Workout Button
                Button(action: {
                    if isActive {
                        onStop()
                    } else {
                        onStart()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isActive ? "pause.fill" : "play.fill")
                            .font(.title2)
                        
                        Text(isActive ? "Pause Workout" : "Start Workout")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(isActive ? Color.red.opacity(0.3) : Color.gold.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(isActive ? Color.red.opacity(0.6) : Color.gold.opacity(0.6), lineWidth: 1.5)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.black.opacity(0.2))
                                    .blur(radius: 10)
                            )
                    )
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: pulseAnimation)
                }
                
                // Secondary Buttons Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Workout History
                    Button(action: {
                        userSettingsInitialTab = 0
                        showingUserSettings = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                                .foregroundColor(.gold)
                            
                            Text("HISTORY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.1))
                                        .blur(radius: 5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Personal Stats
                    Button(action: {
                        // Placeholder action for personal stats
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .foregroundColor(.gold)
                            
                            Text("STATS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.1))
                                        .blur(radius: 5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Personal Development
                    Button(action: {
                        // Placeholder action for personal development
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title3)
                                .foregroundColor(.gold)
                            
                            Text("DEVELOPMENT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.1))
                                        .blur(radius: 5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Placeholder for future button or spacing
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            
        }
        .onAppear {
            glowAnimation = true
            pulseAnimation = true
        }
    }
}

// MARK: - Streaks Section

struct StreaksSection: View {
    let currentStreak: Int
    @StateObject private var workoutManager = WorkoutManager.shared
    @State private var streakAnimation = false
    @State private var flameAnimation = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("🔥 STREAKS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.gold)
                    .tracking(1)
                
                Spacer()
                
                Button("View All") {
                    // Placeholder action
                }
                .font(.caption2)
                .foregroundColor(.gold.opacity(0.8))
            }
            
            // Streak Cards
            HStack(spacing: 8) {
                // Current Streak
                StreakCard(
                    title: "Current",
                    value: currentStreak,
                    subtitle: "days",
                    icon: "🔥",
                    color: .orange,
                    isAnimated: true
                )
                
                // Longest Streak
                StreakCard(
                    title: "Longest",
                    value: workoutManager.getLongestStreak(),
                    subtitle: "days",
                    icon: "🏆",
                    color: .gold,
                    isAnimated: false
                )
                
                // Total Workouts
                StreakCard(
                    title: "Total",
                    value: workoutManager.getTotalWorkouts(),
                    subtitle: "workouts",
                    icon: "💪",
                    color: .green,
                    isAnimated: false
                )
            }
            
            // Weekly Progress
            WeeklyProgressView()
        }
        .onAppear {
            streakAnimation = true
            flameAnimation = true
        }
    }
}

struct StreakCard: View {
    let title: String
    let value: Int
    let subtitle: String
    let icon: String
    let color: Color
    let isAnimated: Bool
    
    @State private var scaleAnimation = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Icon
            Text(icon)
                .font(.title3)
                .scaleEffect(scaleAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scaleAnimation)
            
            // Value
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            // Title
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.medium)
            
            // Subtitle
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            if isAnimated {
                scaleAnimation = true
            }
        }
    }
}

struct WeeklyProgressView: View {
    // Sample data for 3 months (12 weeks) - 0 = no workout, 1-4 = workout intensity
    @State private var heatmapData: [[Int]] = [
        [0, 1, 2, 3, 1, 0, 2], // Week 1
        [1, 3, 2, 4, 1, 2, 0], // Week 2
        [2, 1, 3, 2, 1, 0, 1], // Week 3
        [0, 2, 1, 3, 2, 1, 0], // Week 4
        [1, 0, 2, 1, 3, 2, 1], // Week 5
        [2, 1, 0, 2, 1, 3, 2], // Week 6
        [1, 2, 1, 0, 2, 1, 3], // Week 7
        [0, 1, 2, 1, 0, 2, 1], // Week 8
        [2, 0, 1, 2, 1, 0, 2], // Week 9
        [1, 2, 0, 1, 2, 1, 0], // Week 10
        [0, 1, 2, 0, 1, 2, 1], // Week 11
        [2, 1, 0, 2, 1, 0, 1]  // Week 12 (current week)
    ]
    @State private var animationDelay = 0.0
    @State private var selectedDay: (week: Int, day: Int)? = nil
    
    private var maxValue: Int {
        heatmapData.flatMap { $0 }.max() ?? 1
    }
    
    private func getColorForValue(_ value: Int) -> Color {
        switch value {
        case 0:
            return Color.gray.opacity(0.2)
        case 1:
            return Color.gold.opacity(0.3)
        case 2:
            return Color.gold.opacity(0.5)
        case 3:
            return Color.gold.opacity(0.7)
        case 4:
            return Color.gold.opacity(0.9)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    private func getDayLabel(_ weekIndex: Int, _ dayIndex: Int) -> String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[dayIndex]
    }
    
    private func getMonthLabel(_ weekIndex: Int) -> String {
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        // Calculate which month this week belongs to (simplified)
        let monthIndex = weekIndex / 4
        return monthNames[monthIndex % 12]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Last 3 Months")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(heatmapData.flatMap { $0 }.filter { $0 > 0 }.count) workouts")
                    .font(.caption2)
                    .foregroundColor(.gold)
            }
            
            // GitHub-style heatmap with 3 months (horizontal layout)
            HStack(spacing: 3) {
                ForEach(Array(heatmapData.enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: 3) {
                        ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, value in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getColorForValue(value))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                                .scaleEffect(animationDelay > Double(weekIndex * 7 + dayIndex) * 0.05 ? 1.0 : 0.8)
                                .animation(.easeInOut(duration: 0.3).delay(Double(weekIndex * 7 + dayIndex) * 0.01), value: animationDelay)
                                .onTapGesture {
                                    selectedDay = (weekIndex, dayIndex)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(selectedDay?.week == weekIndex && selectedDay?.day == dayIndex ? Color.gold : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            
            // Selected day info
            if let selected = selectedDay {
                let value = heatmapData[selected.week][selected.day]
                let dayLabel = getDayLabel(selected.week, selected.day)
                let monthLabel = getMonthLabel(selected.week)
                
                HStack {
                    Text("\(monthLabel) \(dayLabel)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(value > 0 ? "\(value) workout\(value == 1 ? "" : "s")" : "No workout")
                        .font(.caption2)
                        .foregroundColor(value > 0 ? .gold : .gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(getColorForValue(intensity))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 2)
        .onAppear {
            animationDelay = 1.0
        }
    }
}

// MARK: - User Settings View

struct UserSettingsView: View {
    let userPreferences: UserPreferences
    let authTracker: AuthenticationTracker
    let initialTab: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int
    
    init(userPreferences: UserPreferences, authTracker: AuthenticationTracker, initialTab: Int = 0) {
        self.userPreferences = userPreferences
        self.authTracker = authTracker
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gold)
                    .font(.headline)
                    
                Spacer()

                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.clear)
                    .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Tab Bar
                HStack(spacing: 0) {
                    TabButton(
                        title: "Profile Statistics",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "User Settings",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    ProfileStatisticsTab(userPreferences: userPreferences)
                        .tag(0)
                    
                    UserSettingsTab(authTracker: authTracker)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .gold : .gray)
                    .fontWeight(isSelected ? .bold : .medium)
                
                Rectangle()
                    .fill(isSelected ? Color.gold : Color.clear)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

// MARK: - User Settings Tab

struct UserSettingsTab: View {
    let authTracker: AuthenticationTracker
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Placeholder content for User Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "gear")
                            .font(.system(size: 40))
                        .foregroundColor(.gold)

                        Text("User Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                        .foregroundColor(.white)
                        
                        Text("Settings and preferences will be configured here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    }
                    .padding(30)
                }
                .padding(.horizontal, 20)
                
                // Additional settings cards can be added here
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.xmark")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Sign Out")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Sign out of your CRDO account.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Sign Out") {
                            authTracker.signOut()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.red.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        )
                    }
                    .padding(20)
                }
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Profile Statistics Tab

struct ProfileStatisticsTab: View {
    let userPreferences: UserPreferences
    @StateObject private var workoutManager = WorkoutManager.shared
    @State private var selectedWorkout: WorkoutSession?
    @State private var showingWorkoutDetail = false
    @State private var selectedCategory: RunCategory? = nil
    
    private var filteredWorkouts: [WorkoutSession] {
        let sortedWorkouts = workoutManager.workoutHistory.sorted(by: { $0.startTime > $1.startTime })
        
        if let selectedCategory = selectedCategory {
            return sortedWorkouts.filter { $0.runCategory == selectedCategory }
        } else {
            return sortedWorkouts
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Preferences Summary (moved from main view)
                if userPreferences.onboardingCompleted {
                    UserPreferencesSummary(preferences: userPreferences)
                        .padding(.horizontal, 20)
                }

                // Workout History
                if !workoutManager.workoutHistory.isEmpty {
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                    .foregroundColor(.gold)
                                
                                Text("Workout History")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(workoutManager.workoutHistory.count) workouts")
                                    .font(.caption)
                                    .foregroundColor(.gold)
                            }
                            
                            // Category Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    CategoryFilterButton(
                                        title: "All",
                                        isSelected: selectedCategory == nil,
                                        action: { selectedCategory = nil }
                                    )
                                    
                                    ForEach(RunCategory.allCases, id: \.self) { category in
                                        CategoryFilterButton(
                                            title: category.rawValue,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.vertical, 8)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(filteredWorkouts) { workout in
                                    WorkoutHistoryRow(workout: workout)
                                        .onTapGesture {
                                            selectedWorkout = workout
                                            showingWorkoutDetail = true
                                        }
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
    }
}

// MARK: - Workout Models

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var distance: Double // in meters
    var calories: Int
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var route: [Coordinate]?
    var workoutType: WorkoutType
    var runCategory: RunCategory?
    var isCompleted: Bool
    
    // Custom coordinate struct for Codable support
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
        
        init(coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
        
        var clCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum WorkoutType: String, CaseIterable, Codable {
        case running = "Running"
        case walking = "Walking"
        case cycling = "Cycling"
        case cardio = "Cardio"
        
        var icon: String {
            switch self {
            case .running: return "figure.run"
            case .walking: return "figure.walk"
            case .cycling: return "bicycle"
            case .cardio: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .running: return .orange
            case .walking: return .green
            case .cycling: return .blue
            case .cardio: return .red
            }
        }
    }
    

}

// MARK: - Run Category

enum RunCategory: String, CaseIterable, Codable {
    case sprint = "Sprint"
    case shortRun = "Short Run"
    case mediumRun = "Medium Run"
    case longRun = "Long Run"
    case recoveryRun = "Recovery Run"
    case tempoRun = "Tempo Run"
    case easyRun = "Easy Run"
    
    var icon: String {
        switch self {
        case .sprint: return "bolt.fill"
        case .shortRun: return "figure.run"
        case .mediumRun: return "figure.run"
        case .longRun: return "figure.run"
        case .recoveryRun: return "heart.fill"
        case .tempoRun: return "speedometer"
        case .easyRun: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .sprint: return .red
        case .shortRun: return .orange
        case .mediumRun: return .yellow
        case .longRun: return .blue
        case .recoveryRun: return .green
        case .tempoRun: return .purple
        case .easyRun: return .mint
        }
    }
    
    var description: String {
        switch self {
        case .sprint: return "High intensity, short duration"
        case .shortRun: return "Quick cardio session"
        case .mediumRun: return "Moderate distance run"
        case .longRun: return "Endurance building"
        case .recoveryRun: return "Light, easy pace"
        case .tempoRun: return "Sustained effort"
        case .easyRun: return "Comfortable pace"
        }
    }
}

// MARK: - Workout Manager

class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()
    
    @Published var isWorkoutActive = false
    @Published var currentWorkout: WorkoutSession?
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var currentLocation: CLLocation?
    @Published var workoutType: WorkoutSession.WorkoutType = .running
    @Published var elapsedTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var calories: Int = 0
    @Published var averagePace: Double = 0
    @Published var currentPace: Double = 0
    @Published var dailyGoalProgress: TimeInterval = 0
    
    let locationManager = CLLocationManager()
    private var workoutTimer: Timer?
    private var startLocation: CLLocation?
    private var lastLocation: CLLocation?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    override init() {
        super.init()
        setupLocationManager()
        loadWorkoutHistory()
        loadDailyGoalProgress()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters for more precision
        locationManager.activityType = .fitness
        // Disable background updates to avoid Core Location exception
        // locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    private func categorizeRun(duration: TimeInterval, distance: Double) -> RunCategory {
        let durationMinutes = duration / 60.0
        let distanceKm = distance / 1000.0
        
        // Calculate pace in minutes per kilometer
        let paceMinutesPerKm = distanceKm > 0 ? durationMinutes / distanceKm : 0
        
        // Sprint: Very short duration, high intensity
        if durationMinutes < 5 {
            return .sprint
        }
        
        // Short Run: 5-15 minutes
        if durationMinutes < 15 {
            return .shortRun
        }
        
        // Recovery Run: Slow pace (slower than 6:30 per km)
        if paceMinutesPerKm > 6.5 {
            return .recoveryRun
        }
        
        // Easy Run: Moderate pace (5:30-6:30 per km)
        if paceMinutesPerKm > 5.5 {
            return .easyRun
        }
        
        // Tempo Run: Fast pace (4:30-5:30 per km)
        if paceMinutesPerKm > 4.5 {
            return .tempoRun
        }
        
        // Long Run: Long duration (over 30 minutes)
        if durationMinutes > 30 {
            return .longRun
        }
        
        // Medium Run: Everything else
        return .mediumRun
    }
    
    func startWorkout(type: WorkoutSession.WorkoutType = .running) {
        guard !isWorkoutActive else { return }
        
        print("Starting workout: \(type.rawValue)")
        
        workoutType = type
        isWorkoutActive = true
        elapsedTime = 0
        distance = 0
        calories = 0
        averagePace = 0
        currentPace = 0
        routeCoordinates.removeAll()
        
        // Check location authorization status first
        let authStatus = locationManager.authorizationStatus
        print("Current location authorization status: \(authStatus.rawValue)")
        
        // Request location permission and start tracking
        locationManager.requestWhenInUseAuthorization()
        
        // Add a small delay to ensure authorization is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.locationManager.startUpdatingLocation()
            print("Location updates requested")
        }
        
        // Start timer
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
            self.updateCalories()
            self.updatePace()
        }
        
        // Create workout session
        currentWorkout = WorkoutSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            duration: 0,
            distance: 0,
            calories: 0,
            averageHeartRate: nil,
            maxHeartRate: nil,
            route: [],
            workoutType: type,
            runCategory: nil,
            isCompleted: false
        )
        
        startLocation = currentLocation
        print("Workout started successfully")
    }
    
    func pauseWorkout() {
        isWorkoutActive = false
        workoutTimer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    func resumeWorkout() {
        guard let workout = currentWorkout, !isWorkoutActive else { return }
        
        isWorkoutActive = true
        locationManager.startUpdatingLocation()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
            self.updateCalories()
            self.updatePace()
        }
    }
    
    func endWorkout() {
        guard let workout = currentWorkout else { return }
        
        isWorkoutActive = false
        workoutTimer?.invalidate()
        locationManager.stopUpdatingLocation()
        
        // Update final workout data
        var updatedWorkout = workout
        updatedWorkout.endTime = Date()
        updatedWorkout.duration = elapsedTime
        updatedWorkout.distance = distance
        updatedWorkout.calories = calories
        updatedWorkout.route = routeCoordinates.map { WorkoutSession.Coordinate(coordinate: $0) }
        updatedWorkout.runCategory = categorizeRun(duration: elapsedTime, distance: distance)
        updatedWorkout.isCompleted = true
        
        // Save to history
        workoutHistory.append(updatedWorkout)
        saveWorkoutHistory()
        
        // Add workout time to daily goal
        addToDailyGoal(elapsedTime)
        
        // Reset current workout
        currentWorkout = nil
        elapsedTime = 0
        distance = 0
        calories = 0
        averagePace = 0
        currentPace = 0
        routeCoordinates.removeAll()
        
        // Trigger notification
        NotificationManager.shared.scheduleStreakNotification(streak: getCurrentStreak())
    }
    
    private func updateCalories() {
        // Simple calorie calculation based on time and workout type
        let caloriesPerMinute: Double
        switch workoutType {
        case .running: caloriesPerMinute = 12.0
        case .walking: caloriesPerMinute = 6.0
        case .cycling: caloriesPerMinute = 8.0
        case .cardio: caloriesPerMinute = 10.0
        }
        
        calories = Int((elapsedTime / 60.0) * caloriesPerMinute)
    }
    
    private func updatePace() {
        guard distance > 0 else { return }
        
        // Calculate pace in minutes per kilometer
        let paceInSeconds = elapsedTime / (distance / 1000.0)
        currentPace = paceInSeconds / 60.0
        
        // Update average pace
        averagePace = currentPace
    }
    
    private func loadWorkoutHistory() {
        if let data = UserDefaults.standard.data(forKey: "workoutHistory"),
           let history = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            workoutHistory = history
        }
    }
    
    private func saveWorkoutHistory() {
        if let data = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(data, forKey: "workoutHistory")
        }
    }
    
    private func loadDailyGoalProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastSavedDate = UserDefaults.standard.object(forKey: "lastDailyGoalDate") as? Date ?? Date.distantPast
        
        // Reset progress if it's a new day
        if !Calendar.current.isDate(today, inSameDayAs: lastSavedDate) {
            dailyGoalProgress = 0
            UserDefaults.standard.set(today, forKey: "lastDailyGoalDate")
        } else {
            dailyGoalProgress = UserDefaults.standard.double(forKey: "dailyGoalProgress")
        }
    }
    
    private func saveDailyGoalProgress() {
        UserDefaults.standard.set(dailyGoalProgress, forKey: "dailyGoalProgress")
        UserDefaults.standard.set(Date(), forKey: "lastDailyGoalDate")
    }
    
    func addToDailyGoal(_ time: TimeInterval) {
        dailyGoalProgress += time
        saveDailyGoalProgress()
    }
    
    func getDailyGoalProgress() -> Double {
        let goalMinutes: Double = 15.0
        let goalSeconds = goalMinutes * 60.0
        return min(dailyGoalProgress / goalSeconds, 1.0)
    }
    
    func getDailyGoalTimeString() -> String {
        let minutes = Int(dailyGoalProgress) / 60
        let seconds = Int(dailyGoalProgress) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getCurrentStreak() -> Int {
        // Calculate current streak based on completed workouts
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let workoutsOnDate = workoutHistory.filter { workout in
                calendar.isDate(workout.startTime, inSameDayAs: currentDate) && workout.isCompleted
            }
            
            if workoutsOnDate.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    func getTotalWorkouts() -> Int {
        return workoutHistory.filter { $0.isCompleted }.count
    }
    
    func getLongestStreak() -> Int {
        // Calculate longest streak from workout history
        var longestStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        let sortedWorkouts = workoutHistory.filter { $0.isCompleted }.sorted { $0.startTime < $1.startTime }
        
        for workout in sortedWorkouts {
            let workoutDate = calendar.startOfDay(for: workout.startTime)
            let previousDate = calendar.date(byAdding: .day, value: -1, to: workoutDate) ?? workoutDate
            
            if currentStreak == 0 || calendar.isDate(workoutDate, inSameDayAs: previousDate) {
                currentStreak += 1
            } else {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        return max(longestStreak, currentStreak)
    }
}

// MARK: - Location Manager Extension

extension WorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out low-quality locations
        guard location.horizontalAccuracy <= 20 else { return } // Only accept locations with accuracy better than 20 meters
        
        // Filter out locations that are too close together (reduces fidgety behavior)
        if let lastLocation = lastLocation {
            let distanceFromLast = location.distance(from: lastLocation)
            if distanceFromLast < 3 { return } // Skip locations less than 3 meters apart
        }
        
        print("Location update received: \(location.coordinate) - Accuracy: \(location.horizontalAccuracy)m")
        currentLocation = location
        
        if isWorkoutActive {
            if let lastLocation = lastLocation {
                let newDistance = location.distance(from: lastLocation)
                
                // Additional filtering for more stable distance calculation
                if newDistance > 0 && newDistance < 100 { // Reasonable distance between points
                    distance += newDistance
                    
                    // Add to route with additional smoothing
                    if shouldAddToRoute(location: location) {
                        routeCoordinates.append(location.coordinate)
                    }
                    print("Distance updated: \(distance)m")
                }
            }
            
            lastLocation = location
        }
    }
    
    private func shouldAddToRoute(location: CLLocation) -> Bool {
        // Only add to route if we have enough points or if it's significantly different
        if routeCoordinates.count < 2 {
            return true
        }
        
        guard let lastCoordinate = routeCoordinates.last else { return true }
        let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
        let distance = location.distance(from: lastLocation)
        let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
        
        // Calculate speed in m/s
        let speed = timeInterval > 0 ? distance / timeInterval : 0
        
        // Add point if it's at least 5 meters away from the last point
        // and the speed is reasonable (between 0.5 and 10 m/s, which is roughly 1.8-36 km/h)
        return distance >= 5 && speed >= 0.5 && speed <= 10
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed to: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse:
            if isWorkoutActive {
                locationManager.startUpdatingLocation()
                print("Location updates started")
            }
        case .authorizedAlways:
            if isWorkoutActive {
                locationManager.startUpdatingLocation()
                print("Location updates started")
            }
        case .denied, .restricted:
            print("Location permission denied or restricted")
        case .notDetermined:
            print("Location permission not determined")
        @unknown default:
            print("Unknown authorization status")
        }
    }
}

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let workout: WorkoutSession
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: workout.startTime)
    }
    
    private var formattedDuration: String {
        let minutes = Int(workout.duration) / 60
        let seconds = Int(workout.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedDistance: String {
        if workout.distance >= 1000 {
            return String(format: "%.1f km", workout.distance / 1000)
        } else {
            return String(format: "%.0f m", workout.distance)
        }
    }
    
    private var formattedPace: String {
        if workout.duration > 0 && workout.distance > 0 {
            let paceInSeconds = workout.duration / (workout.distance / 1000.0)
            let minutes = Int(paceInSeconds) / 60
            let seconds = Int(paceInSeconds) % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "--:--"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Workout Type Icon
            Image(systemName: workout.workoutType.icon)
                .font(.title3)
                .foregroundColor(workout.workoutType.color)
                .frame(width: 30)
            
            // Workout Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(workout.workoutType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    if let category = workout.runCategory {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundColor(category.color)
                            .fontWeight(.medium)
                    }
                }
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gold)
                
                HStack(spacing: 8) {
                    Text(formattedDistance)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formattedPace)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(workout.workoutType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ? Color.gold.opacity(0.3) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(isSelected ? Color.gold : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    let workout: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private var routeCoordinates: [CLLocationCoordinate2D] {
        workout.route?.map { $0.clCoordinate } ?? []
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gold)
                    .font(.headline)
                    
                    Spacer()
                    
                    Text("Workout Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.clear)
                    .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Workout Summary Card
                        GlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: workout.workoutType.icon)
                                        .font(.title)
                                        .foregroundColor(workout.workoutType.color)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(workout.workoutType.rawValue)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            if let category = workout.runCategory {
                                                Text("•")
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                                
                                                Text(category.rawValue)
                                                    .font(.title3)
                                                    .foregroundColor(category.color)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        
                                        Text(formatDate(workout.startTime))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Stats Grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    DetailStatCard(title: "Duration", value: formatDuration(workout.duration), icon: "clock")
                                    DetailStatCard(title: "Distance", value: formatDistance(workout.distance), icon: "location")
                                    DetailStatCard(title: "Pace", value: formatPace(workout.duration, workout.distance), icon: "speedometer")
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                                                // Route Map (if available)
                        if !routeCoordinates.isEmpty {
                            GlassCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "map")
                                            .font(.title2)
                                            .foregroundColor(.gold)
                                        
                                        Text("Route")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    Map(coordinateRegion: .constant(region))
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                }
                                .padding(20)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            // Set map region to show the entire route
            if !routeCoordinates.isEmpty {
                updateMapRegion()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    private func formatPace(_ duration: TimeInterval, _ distance: Double) -> String {
        if duration > 0 && distance > 0 {
            let paceInSeconds = duration / (distance / 1000.0)
            let minutes = Int(paceInSeconds) / 60
            let seconds = Int(paceInSeconds) % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "--:--"
        }
    }
    

    
    private func updateMapRegion() {
        let latitudes = routeCoordinates.map { $0.latitude }
        let longitudes = routeCoordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.2
        let spanLon = (maxLon - minLon) * 1.2
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.01), longitudeDelta: max(spanLon, 0.01))
        )
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.gold)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Workout Map View

struct WorkoutMapView: View {
    @ObservedObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    
    var body: some View {
        ZStack {
            // Map View with Route
            Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.follow))
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        // Save current workout time to daily goal before dismissing
                        if workoutManager.isWorkoutActive {
                            workoutManager.addToDailyGoal(workoutManager.elapsedTime)
                            workoutManager.endWorkout()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(workoutManager.workoutType.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text(formatTime(workoutManager.elapsedTime))
                            .font(.subheadline)
                            .foregroundColor(.gold)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if workoutManager.isWorkoutActive {
                            workoutManager.pauseWorkout()
                        } else {
                            workoutManager.resumeWorkout()
                        }
                    }) {
                        Image(systemName: workoutManager.isWorkoutActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(workoutManager.isWorkoutActive ? .red : .green)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .ignoresSafeArea()
                )
                
                Spacer()
                
                // Bottom Stats
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        StatCard(title: "Distance", value: formatDistance(workoutManager.distance), icon: "location")
                        StatCard(title: "Time", value: formatTime(workoutManager.elapsedTime), icon: "clock")
                        StatCard(title: "Pace", value: formatPace(workoutManager.currentPace), icon: "speedometer")
                    }
                    
                    // End Workout Button
                    Button(action: {
                        workoutManager.endWorkout()
                        dismiss()
                    }) {
                        Text("End Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.red.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .ignoresSafeArea()
                )
            }
        }
        .onAppear {
            // Update region to user's current location
            if let location = workoutManager.currentLocation {
                region.center = location.coordinate
            }
        }
        .onChange(of: workoutManager.currentLocation) { _, location in
            if let location = location {
                // Smooth region updates to reduce map jumping
                withAnimation(.easeInOut(duration: 0.5)) {
                    region.center = location.coordinate
                }
            }
        }
        .onReceive(workoutManager.$routeCoordinates) { coordinates in
            // Update route coordinates from workout manager
            routeCoordinates = coordinates
        }
        .onChange(of: workoutManager.isWorkoutActive) { _, isActive in
            if isActive {
                // Start new route when workout begins
                routeCoordinates.removeAll()
                if let location = workoutManager.currentLocation {
                    routeCoordinates.append(location.coordinate)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        if pace > 0 {
            let minutes = Int(pace)
            let seconds = Int((pace - Double(minutes)) * 60)
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "--:--"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.gold)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}



// MARK: - Main App View (Improved Welcome Screen)

struct MainAppView: View {
    let userPreferences: UserPreferences
    let authTracker: AuthenticationTracker
    @State private var pulse = false
    @State private var progressAnimation = false
    @State private var showingUserSettings = false
    @State private var showingWorkoutMap = false
    @State private var userSettingsInitialTab = 0
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.85)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Section (60% of screen)
                ProgressSection(
                    progress: workoutManager.getDailyGoalProgress(),
                    timeElapsed: Int(workoutManager.dailyGoalProgress),
                    isActive: workoutManager.isWorkoutActive,
                    onStart: { 
                        if workoutManager.isWorkoutActive {
                            workoutManager.pauseWorkout()
                        } else {
                            workoutManager.startWorkout(type: .running)
                            showingWorkoutMap = true
                        }
                    },
                    onStop: { 
                        if workoutManager.isWorkoutActive {
                            workoutManager.endWorkout()
                        }
                    },
                    onWorkoutMap: { },
                    currentStreak: workoutManager.getCurrentStreak(),
                    showingUserSettings: $showingUserSettings,
                    userSettingsInitialTab: $userSettingsInitialTab
                )
                
                // Bottom Section (40% of screen)
                VStack(spacing: 12) {
                    // Streaks Section
                    StreaksSection(currentStreak: workoutManager.getCurrentStreak())
            .padding(.horizontal, 30)
                        .padding(.top, 15)
                }
                .padding(.horizontal, 30)
            }
            .padding(.top, 70) // Add padding to account for the navigation bar with Dynamic Island spacing
            
            // Top Navigation Bar - positioned absolutely at the top
            VStack {
                TopNavigationBar(
                    showingUserSettings: $showingUserSettings
                )
                Spacer()
            }
            .ignoresSafeArea(.all, edges: .top)
        }
            .onAppear {
                pulse = true
            progressAnimation = true
            notificationManager.requestPermission()
        }
        .sheet(isPresented: $showingUserSettings) {
            UserSettingsView(userPreferences: userPreferences, authTracker: authTracker, initialTab: userSettingsInitialTab)
        }
        .fullScreenCover(isPresented: $showingWorkoutMap) {
            WorkoutMapView(workoutManager: workoutManager)
        }
        .statusBarHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let morningMessages = [
        "Somehow you've worked out 3 days in a row. Who even are you?? Don't break the illusion—get today's session in.",
        "Day 7 of cardio?! You're basically an athlete. Time to start looking down on the rest of us. One more rep, one more flex.",
        "You just beat your streak of 5 days! Experts are confused. Your couch is devastated. Don't let the couch win. Again.",
        "New record: 8 days. Is this growth or a glitch in the matrix? Test reality—go move your body.",
        "7-day streak unlocked! Please accept this imaginary badge. It's emotionally fulfilling and absolutely worthless. Still better than any NFT. Keep going.",
        "30 days straight? Do you even have rest days or are you powered by caffeine and existential dread? Whatever works. Just log today's cardio.",
        "You're 1 missed workout away from losing your streak. Not saying we'll cry, but… we'll cry. Spare us the emotional damage—just 10 minutes of movement today.",
        "That streak isn't going to save itself. You've come this far, don't let us down like our high school gym teachers did. Open CRDO. Be the gym class hero you never were.",
        "Rise and cardio, legend. Or snooze and lose. Your move. Just one small step for your body, one giant leap for your self-esteem.",
        "Still time to do cardio! Or sit in guilt and scroll memes. Honestly, both are exercise-adjacent. Do the one that helps your heart.",
        "You've done 15 workouts this month. That's more consistent than your skincare routine. Make it 16 and glow inside out.",
        "Your cardio stats are up 40%. We're scared. Are you okay? Channel the chaos. Keep the streak alive.",
        "Yes, we know these notifications are annoying. But so is starting over. Save future-you the stress. Move it.",
        "CRDO: reminding you to move so your future self doesn't file a complaint. Seriously. Avoid the lawsuit. Do some cardio.",
        "Congrats on your 10-day streak. NASA called. They want to study your discipline. Show them you're consistent, not just weird.",
        "Not to alarm you, but you're one workout away from being legally considered \"fit-ish.\" Lock it in. Hit start.",
        "Legend has it if you hit 14 days, a protein bar spawns in your kitchen. One more workout and you might find out.",
        "Don't let your streak become just another broken dream. Like your podcast. Do it for the streak. Do it for the dignity.",
        "The streak is strong with you. Unlike your knees, probably. Warm up. Then unleash chaos.",
        "CRDO streak: 11 days. Ego streak: infinity. Keep feeding both.",
        "You're making the rest of us look bad. Please stop. Or don't. Actually, keep going. Let's see 12.",
        "Is this discipline or just you running from your problems at 6mph? Either way, don't stop now."
    ]
    
    private let eveningMessages = [
        "You missed yesterday. Tragic. But not unrecoverable. Like your last relationship. Reignite the spark—with cardio.",
        "Your streak is dead… unless you pretend yesterday didn't happen. We won't tell. Do today's workout. We'll lie for you.",
        "Still time to do cardio! Or sit in guilt and scroll memes. Honestly, both are exercise-adjacent. Do the one that helps your heart.",
        "You've done 15 workouts this month. That's more consistent than your skincare routine. Make it 16 and glow inside out.",
        "Your cardio stats are up 40%. We're scared. Are you okay? Channel the chaos. Keep the streak alive.",
        "Yes, we know these notifications are annoying. But so is starting over. Save future-you the stress. Move it.",
        "CRDO: reminding you to move so your future self doesn't file a complaint. Seriously. Avoid the lawsuit. Do some cardio.",
        "Congrats on your 10-day streak. NASA called. They want to study your discipline. Show them you're consistent, not just weird.",
        "Not to alarm you, but you're one workout away from being legally considered \"fit-ish.\" Lock it in. Hit start.",
        "Legend has it if you hit 14 days, a protein bar spawns in your kitchen. One more workout and you might find out.",
        "Don't let your streak become just another broken dream. Like your podcast. Do it for the streak. Do it for the dignity.",
        "The streak is strong with you. Unlike your knees, probably. Warm up. Then unleash chaos.",
        "CRDO streak: 11 days. Ego streak: infinity. Keep feeding both.",
        "You're making the rest of us look bad. Please stop. Or don't. Actually, keep going. Let's see 12.",
        "Is this discipline or just you running from your problems at 6mph? Either way, don't stop now."
    ]
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                self.scheduleNotifications()
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleNotifications() {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule morning notification (7 AM)
        scheduleNotification(
            title: "CRDO",
            body: morningMessages.randomElement() ?? "Time to move!",
            hour: 7,
            minute: 0,
            identifier: "morning-crdo"
        )
        
        // Schedule late morning notification (11 AM)
        scheduleNotification(
            title: "CRDO",
            body: morningMessages.randomElement() ?? "Still time to workout!",
            hour: 11,
            minute: 0,
            identifier: "late-morning-crdo"
        )
        
        // Schedule afternoon notification (3 PM)
        scheduleNotification(
            title: "CRDO",
            body: eveningMessages.randomElement() ?? "Afternoon energy boost!",
            hour: 15,
            minute: 0,
            identifier: "afternoon-crdo"
        )
        
        // Schedule evening notification (7 PM)
        scheduleNotification(
            title: "CRDO",
            body: eveningMessages.randomElement() ?? "Evening workout time!",
            hour: 19,
            minute: 0,
            identifier: "evening-crdo"
        )
    }
    
    private func scheduleNotification(title: String, body: String, hour: Int, minute: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for \(hour):\(minute)")
            }
        }
    }
    
    func scheduleStreakNotification(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "CRDO Streak Update"
        
        let messages = [
            "🔥 \(streak)-day streak! You're on fire!",
            "💪 \(streak) days strong! Keep it up!",
            "🏆 \(streak) days in a row! You're unstoppable!",
            "⚡ \(streak) day streak! You're crushing it!",
            "🌟 \(streak) days! You're becoming a legend!"
        ]
        
        content.body = messages.randomElement() ?? "Amazing streak!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streak-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    let authTracker: AuthenticationTracker
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var rememberMe = false
    @State private var animationOffset: CGFloat = 1000
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 15) {
                    // App Logo/Title
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gold)
                            .scaleEffect(animationOffset == 0 ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationOffset)
                        
                        Text("CRDO")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.gold)
                            .opacity(animationOffset == 0 ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animationOffset)
                        
                        Text("Discipline built differently. Welcome to your new habit: CRDO.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .opacity(animationOffset == 0 ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8).delay(0.4), value: animationOffset)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gold)
                                .fontWeight(.semibold)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gold)
                                .fontWeight(.semibold)
                            
                            HStack {
                                if showingPassword {
                                    TextField("Enter your password", text: $password)
                                        .textFieldStyle(AuthTextFieldStyle())
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(AuthTextFieldStyle())
                                }
                                
                                Button(action: {
                                    showingPassword.toggle()
                                }) {
                                    Image(systemName: showingPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        
                        // Confirm Password Field (Sign Up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .foregroundColor(.gold)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    if showingConfirmPassword {
                                        TextField("Confirm your password", text: $confirmPassword)
                                            .textFieldStyle(AuthTextFieldStyle())
                                    } else {
                                        SecureField("Confirm your password", text: $confirmPassword)
                                            .textFieldStyle(AuthTextFieldStyle())
                                    }
                                    
                                    Button(action: {
                                        showingConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showingConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    }
                                }
                            }
                        }
                        
                        // Remember Me Toggle
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(rememberMe ? .gold : .gray)
                                        .font(.title3)
                                    
                                    Text("Remember me for 2 weeks")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        
                        // Action Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                authTracker.signIn(rememberMe: rememberMe)
                            }
                        }) {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.gold.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Color.gold, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 10)
                        
                        // Toggle Sign In/Sign Up
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                email = ""
                                password = ""
                                confirmPassword = ""
                                rememberMe = false
                            }
                        }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.caption)
                                .foregroundColor(.gold.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 30)
                    .opacity(animationOffset == 0 ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.6), value: animationOffset)
                    
                    Spacer()
                }
                .offset(y: -keyboardHeight * 0.3) // Shift content up when keyboard appears
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animationOffset = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
}

// MARK: - Auth Text Field Style

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

// MARK: - Authentication Tracker

class AuthenticationTracker: ObservableObject {
    static let shared = AuthenticationTracker()
    
    @Published var isAuthenticated = false
    @Published var shouldShowAuth = true
    
    private let lastSignInKey = "lastSignInDate"
    private let rememberMeKey = "rememberMe"
    private let rememberMeDateKey = "rememberMeDate"
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        let lastSignIn = UserDefaults.standard.object(forKey: lastSignInKey) as? Date ?? Date.distantPast
        let rememberMe = UserDefaults.standard.bool(forKey: rememberMeKey)
        let rememberMeDate = UserDefaults.standard.object(forKey: rememberMeDateKey) as? Date ?? Date.distantPast
        
        let now = Date()
        
        if rememberMe {
            // Check if within 2 weeks of remember me
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
            if rememberMeDate > twoWeeksAgo {
                isAuthenticated = true
                shouldShowAuth = false
                return
            }
        } else {
            // Check if within 3 days of last sign in
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
            if lastSignIn > threeDaysAgo {
                isAuthenticated = true
                shouldShowAuth = false
                return
            }
        }
        
        // Not authenticated, show auth screen
        isAuthenticated = false
        shouldShowAuth = true
    }
    
    func signIn(rememberMe: Bool = false) {
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastSignInKey)
        
        if rememberMe {
            UserDefaults.standard.set(true, forKey: rememberMeKey)
            UserDefaults.standard.set(now, forKey: rememberMeDateKey)
        } else {
            UserDefaults.standard.set(false, forKey: rememberMeKey)
            UserDefaults.standard.removeObject(forKey: rememberMeDateKey)
        }
        
        isAuthenticated = true
        shouldShowAuth = false
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: lastSignInKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        UserDefaults.standard.removeObject(forKey: rememberMeDateKey)
        
        isAuthenticated = false
        shouldShowAuth = true
    }
    
    func getDaysSinceLastSignIn() -> Int {
        let lastSignIn = UserDefaults.standard.object(forKey: lastSignInKey) as? Date ?? Date.distantPast
        let now = Date()
        return Calendar.current.dateComponents([.day], from: lastSignIn, to: now).day ?? 0
    }
}

