import Foundation

class UserStats: ObservableObject {
    @Published var runnerLevel: Int
    @Published var enduranceLevel: Int
    @Published var speedLevel: Int
    @Published var totalWorkouts: Int
    @Published var totalDistance: Double
    @Published var totalTime: TimeInterval
    
    init() {
        // Initialize with default values first
        self.runnerLevel = 1
        self.enduranceLevel = 1
        self.speedLevel = 1
        self.totalWorkouts = 0
        self.totalDistance = 0
        self.totalTime = 0
        
        // Now load saved values from UserDefaults
        loadFromUserDefaults()
    }
    
    private func loadFromUserDefaults() {
        let savedRunnerLevel = UserDefaults.standard.integer(forKey: "runnerLevel")
        if savedRunnerLevel > 0 {
            self.runnerLevel = savedRunnerLevel
        }
        
        let savedEnduranceLevel = UserDefaults.standard.integer(forKey: "enduranceLevel")
        if savedEnduranceLevel > 0 {
            self.enduranceLevel = savedEnduranceLevel
        }
        
        let savedSpeedLevel = UserDefaults.standard.integer(forKey: "speedLevel")
        if savedSpeedLevel > 0 {
            self.speedLevel = savedSpeedLevel
        }
        
        self.totalWorkouts = UserDefaults.standard.integer(forKey: "totalWorkouts")
        self.totalDistance = UserDefaults.standard.double(forKey: "totalDistance")
        self.totalTime = UserDefaults.standard.double(forKey: "totalTime")
    }
    
    // Save methods for each property
    private func saveRunnerLevel() {
        UserDefaults.standard.set(runnerLevel, forKey: "runnerLevel")
    }
    
    private func saveEnduranceLevel() {
        UserDefaults.standard.set(enduranceLevel, forKey: "enduranceLevel")
    }
    
    private func saveSpeedLevel() {
        UserDefaults.standard.set(speedLevel, forKey: "speedLevel")
    }
    
    private func saveTotalWorkouts() {
        UserDefaults.standard.set(totalWorkouts, forKey: "totalWorkouts")
    }
    
    private func saveTotalDistance() {
        UserDefaults.standard.set(totalDistance, forKey: "totalDistance")
    }
    
    private func saveTotalTime() {
        UserDefaults.standard.set(totalTime, forKey: "totalTime")
    }
    
    // Public methods to update stats with automatic saving
    func updateRunnerLevel(_ level: Int) {
        runnerLevel = level
        saveRunnerLevel()
    }
    
    func updateEnduranceLevel(_ level: Int) {
        enduranceLevel = level
        saveEnduranceLevel()
    }
    
    func updateSpeedLevel(_ level: Int) {
        speedLevel = level
        saveSpeedLevel()
    }
    
    func updateTotalWorkouts(_ count: Int) {
        totalWorkouts = count
        saveTotalWorkouts()
    }
    
    func updateTotalDistance(_ distance: Double) {
        totalDistance = distance
        saveTotalDistance()
    }
    
    func updateTotalTime(_ time: TimeInterval) {
        totalTime = time
        saveTotalTime()
    }
    
    // Calculate experience needed for next level (simple formula)
    func experienceForLevel(_ level: Int) -> Int {
        return level * 100
    }
    
    // Get progress percentage for current level
    func progressForLevel(_ level: Int, experience: Int) -> Double {
        let currentLevelExp = experienceForLevel(level - 1)
        let nextLevelExp = experienceForLevel(level)
        let progress = Double(experience - currentLevelExp) / Double(nextLevelExp - currentLevelExp)
        return min(max(progress, 0.0), 1.0)
    }
    
    // Update stats after a workout
    func updateStats(distance: Double, time: TimeInterval) {
        totalWorkouts += 1
        totalDistance += distance
        totalTime += time
        
        // Save the updated values
        saveTotalWorkouts()
        saveTotalDistance()
        saveTotalTime()
        
        // Simple leveling system based on workouts and distance
        let newRunnerLevel = min(99, 1 + (totalWorkouts / 5))
        let newEnduranceLevel = min(99, 1 + Int(totalDistance / 10))
        let newSpeedLevel = min(99, 1 + Int(totalDistance / 5))
        
        if newRunnerLevel > runnerLevel {
            updateRunnerLevel(newRunnerLevel)
        }
        if newEnduranceLevel > enduranceLevel {
            updateEnduranceLevel(newEnduranceLevel)
        }
        if newSpeedLevel > speedLevel {
            updateSpeedLevel(newSpeedLevel)
        }
    }
    
    // Reset stats to defaults
    func resetStats() {
        updateRunnerLevel(1)
        updateEnduranceLevel(1)
        updateSpeedLevel(1)
        updateTotalWorkouts(0)
        updateTotalDistance(0)
        updateTotalTime(0)
    }
} 