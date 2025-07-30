//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan Yip on 7/25/25.
//  Refactored for efficiency & maintainability
//

import SwiftUI
import UserNotifications

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

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if vm.showingMainApp || vm.userPreferences.onboardingCompleted {
                MainAppView(userPreferences: vm.userPreferences)
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
    let currentStreak: Int
    
    @State private var glowAnimation = false
    @State private var pulseAnimation = false
    
    private var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
                Text(dynamicTitle)
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
            
            // Progress Bar
            VStack(spacing: 12) {
                HStack {
                    Text("Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(progressPercentage)% Complete")
                        .font(.subheadline)
                        .foregroundColor(.gold)
                }
                
                // Animated progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.gold, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(progress) * (UIScreen.main.bounds.width - 60), height: 20)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    // Shimmer effect
                    if isActive {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 20)
                            .offset(x: -30)
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: glowAnimation)
                    }
                }
            }
            .padding(.horizontal, 30)
            
            // Control Button
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
                    
                    Text(isActive ? "Pause" : "Start Workout")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isActive ? Color.red.opacity(0.8) : Color.gold.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.gold, lineWidth: 1)
                        )
                )
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: pulseAnimation)
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
    @State private var longestStreak = 12
    @State private var totalWorkouts = 23
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
                    value: longestStreak,
                    subtitle: "days",
                    icon: "🏆",
                    color: .gold,
                    isAnimated: false
                )
                
                // Total Workouts
                StreakCard(
                    title: "Total",
                    value: totalWorkouts,
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
    @State private var weekData = [3, 5, 2, 7, 4, 6, 1] // Days active this week
    @State private var barAnimation = false
    
    private var maxValue: Int {
        weekData.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("This Week")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("\(weekData.reduce(0, +)) workouts")
                    .font(.caption2)
                    .foregroundColor(.gold)
            }
            
            // Weekly bars
            HStack(spacing: 3) {
                ForEach(Array(weekData.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 1) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(value > 0 ? Color.gold : Color.gray.opacity(0.3))
                            .frame(height: CGFloat(value) / CGFloat(maxValue) * 24)
                            .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: barAnimation)
                        
                        Text(["S", "M", "T", "W", "T", "F", "S"][index])
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.horizontal, 2)
        .onAppear {
            barAnimation = true
        }
    }
}

// MARK: - User Settings View

struct UserSettingsView: View {
    let userPreferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
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
                    
                    UserSettingsTab()
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
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Profile Statistics Tab

struct ProfileStatisticsTab: View {
    let userPreferences: UserPreferences
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Preferences Summary (moved from main view)
                if userPreferences.onboardingCompleted {
                    UserPreferencesSummary(preferences: userPreferences)
                        .padding(.horizontal, 20)
                }

                // Additional statistics can be added here
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gold)
                        
                        Text("Coming Soon")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Detailed statistics and progress tracking will be available here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
                    }
    }
}

// MARK: - Main App View (Placeholder)

// MARK: - Main App View (Improved Welcome Screen)

struct MainAppView: View {
    let userPreferences: UserPreferences
    @State private var pulse = false
    @State private var progressAnimation = false
    @State private var currentProgress: Double = 0.0
    @State private var timeElapsed: Int = 0
    @State private var isActive = false
    @State private var showingUserSettings = false
    @State private var currentStreak = 7 // Shared streak data
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Timer for demo purposes - in real app this would be actual workout time
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                    progress: currentProgress,
                    timeElapsed: timeElapsed,
                    isActive: isActive,
                    onStart: { startWorkout() },
                    onStop: { stopWorkout() },
                    currentStreak: currentStreak
                )
                
                // Bottom Section (40% of screen)
                VStack(spacing: 12) {
                    // CRDO Playgrounds Button
                Button(action: {
                        // Placeholder action for CRDO Playgrounds
                }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title3)
                            
                            Text("CRDO Playgrounds")
                        .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.purple.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        )
                }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Streaks Section
                    StreaksSection(currentStreak: currentStreak)
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
        .onReceive(timer) { _ in
            if isActive && timeElapsed < 900 { // 15 minutes = 900 seconds
                timeElapsed += 1
                currentProgress = Double(timeElapsed) / 900.0
            }
        }
        .sheet(isPresented: $showingUserSettings) {
            UserSettingsView(userPreferences: userPreferences)
        }
        .statusBarHidden(true)
    }
    
    private func startWorkout() {
        isActive = true
        withAnimation(.easeInOut(duration: 0.5)) {
            progressAnimation = true
        }
    }
    
    private func stopWorkout() {
        isActive = false
        withAnimation(.easeInOut(duration: 0.5)) {
            progressAnimation = false
        }
        
        // Trigger streak notification when workout is completed
        if currentProgress >= 1.0 {
            notificationManager.scheduleStreakNotification(streak: currentStreak)
        }
    }
    
    private func triggerStreakNotification() {
        notificationManager.scheduleStreakNotification(streak: currentStreak)
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
        
        // Schedule evening notification (5 PM)
        scheduleNotification(
            title: "CRDO",
            body: eveningMessages.randomElement() ?? "Still time to workout!",
            hour: 17,
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

