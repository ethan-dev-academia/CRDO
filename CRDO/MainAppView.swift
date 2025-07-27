//
//  MainAppView.swift
//  CRDO
//
//  Created by Ethan yip on 7/25/25.
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var selectedTab = 0
    @State private var showingProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // City View
            CityView()
                .tabItem {
                    Image(systemName: "building.2.fill")
                    Text("City")
                }
                .tag(0)
            
            // Workout View
            WorkoutView()
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Workout")
                }
                .tag(1)
            
            // Progress View
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
            
            // Profile View
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.gold)
        .onAppear {
            // Set tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - City View
struct CityView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var cityProgress: CityProgress?
    
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
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your City")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Level \(cityProgress?.currentLevel ?? 1)")
                            .font(.subheadline)
                            .foregroundColor(.gold)
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(cityProgress?.totalProgress ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gold)
                        
                        Text("Progress Points")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // City visualization placeholder
                VStack(spacing: 15) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gold)
                    
                    Text("Your city is growing!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Complete workouts to unlock new buildings and expand your city.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Quick stats
                HStack(spacing: 20) {
                    StatCard(
                        icon: "building.2",
                        title: "Buildings",
                        value: "\(cityProgress?.buildingsUnlocked ?? 0)"
                    )
                    
                    StatCard(
                        icon: "flame",
                        title: "Streak",
                        value: "\(supabaseManager.userProfile?.currentStreak ?? 0)"
                    )
                    
                    StatCard(
                        icon: "figure.run",
                        title: "Workouts",
                        value: "\(supabaseManager.userProfile?.totalWorkouts ?? 0)"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            loadCityProgress()
        }
    }
    
    private func loadCityProgress() {
        guard let userId = supabaseManager.currentUser?.id.uuidString else { return }
        
        Task {
            do {
                let progress = try await supabaseManager.getUserCityProgress(userId: userId)
                await MainActor.run {
                    self.cityProgress = progress
                }
            } catch {
                print("Error loading city progress: \(error)")
            }
        }
    }
}

// MARK: - Workout View
struct WorkoutView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var isWorkoutActive = false
    @State private var workoutDuration: TimeInterval = 0
    @State private var timer: Timer?
    
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
            
            VStack(spacing: 30) {
                // Header
                Text("Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Workout timer
                VStack(spacing: 20) {
                    Text(timeString(from: workoutDuration))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.gold)
                    
                    if isWorkoutActive {
                        Text("Workout in progress...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Ready to build your city?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Workout controls
                VStack(spacing: 20) {
                    if isWorkoutActive {
                        Button("End Workout") {
                            endWorkout()
                        }
                        .buttonStyle(GlassButtonStyle())
                    } else {
                        Button("Start Workout") {
                            startWorkout()
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    
                    Text("Every 15 minutes of activity = 1 building progress")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        workoutDuration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            workoutDuration += 1
        }
    }
    
    private func endWorkout() {
        isWorkoutActive = false
        timer?.invalidate()
        timer = nil
        
        // Save workout session
        saveWorkoutSession()
    }
    
    private func saveWorkoutSession() {
        guard let userId = supabaseManager.currentUser?.id.uuidString else { return }
        
        let session = WorkoutSession(
            id: nil,
            userId: userId,
            duration: Int(workoutDuration),
            caloriesBurned: Int(workoutDuration / 60 * 10), // Rough estimate
            workoutType: "General",
            cityProgressEarned: Int(workoutDuration / 900), // 15 minutes = 1 progress point
            createdAt: Date()
        )
        
        Task {
            do {
                try await supabaseManager.saveWorkoutSession(session: session)
                
                // Update user stats
                let currentStreak = (supabaseManager.userProfile?.currentStreak ?? 0) + 1
                let longestStreak = max(currentStreak, supabaseManager.userProfile?.longestStreak ?? 0)
                let totalWorkouts = (supabaseManager.userProfile?.totalWorkouts ?? 0) + 1
                
                try await supabaseManager.updateUserStreak(
                    userId: userId,
                    currentStreak: currentStreak,
                    longestStreak: longestStreak
                )
                
                await supabaseManager.updateUserProfile([
                    "total_workouts": totalWorkouts
                ])
                
            } catch {
                print("Error saving workout session: \(error)")
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Progress View
struct ProgressView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var workoutSessions: [WorkoutSession] = []
    
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
            
            VStack(spacing: 20) {
                // Header
                Text("Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Stats overview
                VStack(spacing: 15) {
                    StatCard(
                        icon: "flame.fill",
                        title: "Current Streak",
                        value: "\(supabaseManager.userProfile?.currentStreak ?? 0) days"
                    )
                    
                    StatCard(
                        icon: "trophy.fill",
                        title: "Longest Streak",
                        value: "\(supabaseManager.userProfile?.longestStreak ?? 0) days"
                    )
                    
                    StatCard(
                        icon: "figure.run",
                        title: "Total Workouts",
                        value: "\(supabaseManager.userProfile?.totalWorkouts ?? 0)"
                    )
                }
                .padding(.horizontal, 20)
                
                // Recent workouts
                VStack(alignment: .leading, spacing: 15) {
                    Text("Recent Workouts")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(workoutSessions.prefix(10), id: \.id) { session in
                                WorkoutSessionRow(session: session)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadWorkoutSessions()
        }
    }
    
    private func loadWorkoutSessions() {
        guard let userId = supabaseManager.currentUser?.id.uuidString else { return }
        
        Task {
            do {
                let sessions = try await supabaseManager.getUserWorkoutSessions(userId: userId, limit: 10)
                await MainActor.run {
                    self.workoutSessions = sessions
                }
            } catch {
                print("Error loading workout sessions: \(error)")
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
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
            
            VStack(spacing: 30) {
                // Header
                Text("Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // User info
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gold)
                    
                    VStack(spacing: 5) {
                        Text(supabaseManager.userProfile?.username ?? "User")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(supabaseManager.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Profile options
                VStack(spacing: 15) {
                    ProfileOptionRow(
                        icon: "person.circle",
                        title: "Edit Profile",
                        action: {
                            // TODO: Implement edit profile
                        }
                    )
                    
                    ProfileOptionRow(
                        icon: "gear",
                        title: "Settings",
                        action: {
                            // TODO: Implement settings
                        }
                    )
                    
                    ProfileOptionRow(
                        icon: "questionmark.circle",
                        title: "Help & Support",
                        action: {
                            // TODO: Implement help
                        }
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Sign out button
                Button("Sign Out") {
                    Task {
                        await supabaseManager.signOut()
                    }
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gold)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(session.workoutType)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(session.duration / 60) minutes")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("+\(session.cityProgressEarned)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gold)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gold.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MainAppView()
} 