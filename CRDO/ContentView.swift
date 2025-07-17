//
//  ContentView.swift
//  CRDO
//
//  Created by Ethan yip on 7/16/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var workoutStore = WorkoutStore()
    @State private var showProfile = false
    
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
                    
                    // Invisible spacer to balance the layout
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black)
                
                // Main Content
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Icon and Tagline
                    VStack(spacing: 15) {
                        Image(systemName: "figure.run")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .font(.system(size: 60))
                        
                        Text("Revolutionizing Fitness")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
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
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatisticsView: View {
    let workoutStore: WorkoutStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Statistics")
                    .font(.largeTitle)
                    .padding()
                
                if workoutStore.workouts.isEmpty {
                    Text("No workouts yet")
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 15) {
                        StatCard(title: "Total Workouts", value: "\(workoutStore.workouts.count)")
                        StatCard(title: "Total Distance", value: String(format: "%.1f mi", workoutStore.workouts.reduce(0) { $0 + $1.distance }))
                        StatCard(title: "Total Time", value: formatTotalTime(workoutStore.workouts.reduce(0) { $0 + $1.time }))
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTotalTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
