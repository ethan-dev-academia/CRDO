//
//  SupabaseManager.swift
//  CRDO
//
//  Created by Ethan yip on 7/25/25.
//

import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    
    private init() {
        // Initialize Supabase client with your project URL and anon key
        guard let supabaseURL = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
        
        // Check if user is already signed in
        Task {
            await checkCurrentUser()
        }
    }
    
    // MARK: - Authentication Methods
    
    @MainActor
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            await createUserProfile(for: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            await loadUserProfile(for: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    

    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            // Sign out from Supabase
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            self.userProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func checkCurrentUser() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            await loadUserProfile(for: session.user)
        } catch {
            // User is not authenticated
            self.currentUser = nil
            self.isAuthenticated = false
            self.userProfile = nil
        }
    }
    
    // MARK: - User Profile Management
    
    @MainActor
    private func createUserProfile(for user: User) async {
        let profile = UserProfile(
            id: nil,
            userId: user.id.uuidString,
            username: nil,
            email: user.email,
            fitnessLevel: nil,
            goals: [],
            currentStreak: 0,
            longestStreak: 0,
            totalWorkouts: 0,
            onboardingCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await client
                .from("user_profiles")
                .insert(profile)
                .execute()
            
            self.userProfile = profile
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
    

    
    @MainActor
    private func loadUserProfile(for user: User) async {
        do {
            let response: [UserProfile] = try await client
                .from("user_profiles")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .execute()
                .value
            
            self.userProfile = response.first
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    @MainActor
    func updateUserProfile(_ updates: [String: Any]) async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            // Create a proper update structure
            var updateData: [String: String] = [:]
            
            for (key, value) in updates {
                if let boolValue = value as? Bool {
                    updateData[key] = boolValue ? "true" : "false"
                } else if let intValue = value as? Int {
                    updateData[key] = String(intValue)
                } else if let stringValue = value as? String {
                    updateData[key] = stringValue
                }
            }
            
            try await client
                .from("user_profiles")
                .update(updateData)
                .eq("user_id", value: userId)
                .execute()
            
            // Reload profile
            await loadUserProfile(for: currentUser!)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func completeOnboarding() async {
        await updateUserProfile(["onboarding_completed": true])
    }
    
    // MARK: - Database Operations
    
    func saveWorkoutSession(session: WorkoutSession) async throws {
        try await client
            .from("workout_sessions")
            .insert(session)
            .execute()
    }
    
    func getUserWorkoutSessions(userId: String, limit: Int = 50) async throws -> [WorkoutSession] {
        let response: [WorkoutSession] = try await client
            .from("workout_sessions")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response
    }
    
    func saveCityProgress(progress: CityProgress) async throws {
        try await client
            .from("city_progress")
            .upsert(progress)
            .execute()
    }
    
    func getUserCityProgress(userId: String) async throws -> CityProgress? {
        let response: [CityProgress] = try await client
            .from("city_progress")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    func updateUserStreak(userId: String, currentStreak: Int, longestStreak: Int) async throws {
        let updateData: [String: String] = [
            "current_streak": String(currentStreak),
            "longest_streak": String(longestStreak),
            "last_workout_date": Date().iso8601
        ]
        
        try await client
            .from("user_profiles")
            .update(updateData)
            .eq("user_id", value: userId)
            .execute()
    }
    
    // MARK: - Real-time Subscriptions
    
    // TODO: Update real-time subscription for new Supabase API
    // func subscribeToUserProgress(userId: String, onUpdate: @escaping (CityProgress) -> Void) -> RealtimeChannelV2 {
    //     return client.realtime
    //         .channel("public:city_progress")
    //         .on(.postgresChanges(event: .update, schema: "public", table: "city_progress")) { payload in
    //             if let progress = try? payload.decode(as: CityProgress.self),
    //                progress.userId == userId {
    //                 onUpdate(progress)
    //             }
    //         }
    //         .subscribe()
    // }
}

// MARK: - Data Models

struct UserProfile: Codable {
    let id: String?
    let userId: String
    let username: String?
    let email: String?
    let fitnessLevel: String?
    let goals: [String]?
    let currentStreak: Int
    let longestStreak: Int
    let totalWorkouts: Int
    let onboardingCompleted: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case email
        case fitnessLevel = "fitness_level"
        case goals
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalWorkouts = "total_workouts"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WorkoutSession: Codable {
    let id: String?
    let userId: String
    let duration: Int // in seconds
    let caloriesBurned: Int?
    let workoutType: String
    let cityProgressEarned: Int
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case duration
        case caloriesBurned = "calories_burned"
        case workoutType = "workout_type"
        case cityProgressEarned = "city_progress_earned"
        case createdAt = "created_at"
    }
}

struct CityProgress: Codable {
    let id: String?
    let userId: String
    let totalProgress: Int
    let buildingsUnlocked: Int
    let currentLevel: Int
    let cityData: [String: String]? // JSON data for city state
    let lastUpdated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case totalProgress = "total_progress"
        case buildingsUnlocked = "buildings_unlocked"
        case currentLevel = "current_level"
        case cityData = "city_data"
        case lastUpdated = "last_updated"
    }
}

// MARK: - Extensions

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 
