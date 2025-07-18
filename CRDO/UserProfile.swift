import Foundation

class UserProfile: ObservableObject {
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var userDescription: String {
        didSet {
            UserDefaults.standard.set(userDescription, forKey: "userDescription")
        }
    }
    
    init() {
        // Load saved data from UserDefaults, or use defaults if not found
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
        self.userDescription = UserDefaults.standard.string(forKey: "userDescription") ?? "Fitness Enthusiast"
    }
    
    // Method to reset profile to defaults
    func resetToDefaults() {
        userName = "User"
        userDescription = "Fitness Enthusiast"
    }
    
    // Method to save all data (useful for future database integration)
    func saveProfile() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(userDescription, forKey: "userDescription")
    }
} 