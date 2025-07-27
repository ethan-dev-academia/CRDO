//
//  Config.swift
//  CRDO
//
//  Created by Ethan yip on 7/25/25.
//

import Foundation

struct Config {
    // MARK: - Supabase Configuration
    // Replace these with your actual Supabase project credentials
    static let supabaseURL = "https://kclxioralrxaxavodhbl.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjbHhpb3JhbHJ4YXhhdm9kaGJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM0OTQ2MjAsImV4cCI6MjA2OTA3MDYyMH0.4P_qIoLPCCXG1cDKj49YD944JnEIdgb4Ht6WnutwAMQ"
    
    // MARK: - App Configuration
    static let appName = "CRDO"
    static let appVersion = "1.0.0"
    
    // MARK: - Database Table Names
    struct Tables {
        static let userProfiles = "user_profiles"
        static let workoutSessions = "workout_sessions"
        static let cityProgress = "city_progress"
    }
    
    // MARK: - Default Values
    struct Defaults {
        static let workoutDuration = 900 // 15 minutes in seconds
        static let progressPerWorkout = 1
        static let maxWorkoutHistory = 50
    }
} 
