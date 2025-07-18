//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan yip on 7/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStore = WorkoutStore()
    @StateObject private var userProfile = UserProfile()
    @StateObject private var userStats = UserStats()
    @State private var showProfile = false
    @State private var showPersonalStats = false
    
    // Device-specific adaptations
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // Adaptive sizing based on device
    private var adaptiveSpacing: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 40
        } else if UIScreen.main.bounds.height > 800 {
            return 35
        } else {
            return 30
        }
    }

    private var adaptiveIconSize: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 80
        } else if UIScreen.main.bounds.height > 800 {
            return 70
        } else {
            return 60
        }
    }

    private var adaptiveTitleSize: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 32
        } else if UIScreen.main.bounds.height > 800 {
            return 28
        } else {
            return 24
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    // Profile Photo
                    Button(action: {
                        showProfile = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer()
                    
                    // App Title
                    Text("CRDO")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: {
                        // Add settings functionality here
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black)
                
                // Main Content
                VStack(spacing: adaptiveSpacing) {
                    Spacer()
                    
                    // App Icon and Tagline
                    VStack(spacing: 15) {
                        Image(systemName: "figure.run")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .font(.system(size: adaptiveIconSize))
                        
                        Text("Revolutionizing Fitness")
                            .font(.system(size: adaptiveTitleSize, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Your Personal Fitness Companion")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Main Action Buttons
                    VStack(spacing: 15) {
                        NavigationLink(destination: MapView()) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18))
                                Text("Start Workout")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        NavigationLink(destination: WorkoutHistoryView()) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18))
                                Text("Workout History")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showPersonalStats = true
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                Text("Personal Stats")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(userProfile: userProfile)
        }
        .sheet(isPresented: $showPersonalStats) {
            PersonalStatsView(userStats: userStats)
        }
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfile
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // User Info
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    VStack(spacing: 8) {
                        Text(userProfile.userName)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(userProfile.userDescription)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                
                // Profile Options
                VStack(spacing: 15) {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.system(size: 20))
                            Text("Edit Profile")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Add settings functionality here
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                            Text("Settings")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Add help functionality here
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                            Text("Help & Support")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: userProfile)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfile
    @State private var tempUserName: String
    @State private var tempUserDescription: String
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self._tempUserName = State(initialValue: userProfile.userName)
        self._tempUserDescription = State(initialValue: userProfile.userDescription)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Profile Photo Section
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                    
                    Text("Edit Profile")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // Form Fields
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $tempUserName)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        TextField("Enter your description", text: $tempUserDescription)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    userProfile.userName = tempUserName
                    userProfile.userDescription = tempUserDescription
                    dismiss()
                }) {
                    Text("Save Changes")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct PersonalStatsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userStats: UserStats
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Personal Stats")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Level Stats
                    VStack(spacing: 20) {
                        StatCard(
                            title: "Runner Level",
                            value: "Level \(userStats.runnerLevel)",
                            subtitle: "\(userStats.totalWorkouts) workouts completed",
                            color: .blue,
                            icon: "figure.run"
                        )
                        
                        StatCard(
                            title: "Endurance Level",
                            value: "Level \(userStats.enduranceLevel)",
                            subtitle: String(format: "%.1f miles total", userStats.totalDistance),
                            color: .green,
                            icon: "heart.fill"
                        )
                        
                        StatCard(
                            title: "Speed Level",
                            value: "Level \(userStats.speedLevel)",
                            subtitle: formatTime(userStats.totalTime),
                            color: .red,
                            icon: "bolt.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Overall Stats
                    VStack(spacing: 15) {
                        Text("Overall Progress")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ProgressRow(title: "Total Workouts", value: "\(userStats.totalWorkouts)", color: .blue)
                            ProgressRow(title: "Total Distance", value: String(format: "%.1f miles", userStats.totalDistance), color: .green)
                            ProgressRow(title: "Total Time", value: formatTime(userStats.totalTime), color: .orange)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Level Progress Bars
                    VStack(spacing: 15) {
                        Text("Level Progress")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 15) {
                            LevelProgressBar(
                                title: "Runner",
                                level: userStats.runnerLevel,
                                progress: userStats.progressForLevel(userStats.runnerLevel, experience: userStats.totalWorkouts * 5),
                                color: .blue
                            )
                            
                            LevelProgressBar(
                                title: "Endurance",
                                level: userStats.enduranceLevel,
                                progress: userStats.progressForLevel(userStats.enduranceLevel, experience: Int(userStats.totalDistance * 10)),
                                color: .green
                            )
                            
                            LevelProgressBar(
                                title: "Speed",
                                level: userStats.speedLevel,
                                progress: userStats.progressForLevel(userStats.speedLevel, experience: Int(userStats.totalDistance * 5)),
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Personal Stats")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct LevelProgressBar: View {
    let title: String
    let level: Int
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(title) Level \(level)")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}
