import Foundation
import CoreLocation

enum WorkoutCategory: String, CaseIterable, Codable {
    case short = "Short Run"
    case oneMile = "1 Mile"
    case threeK = "3K"
    case fiveK = "5K"
    case tenK = "10K"
    case halfMarathon = "Half Marathon"
    case marathon = "Marathon"
    case ultra = "Ultra"
    
    static func category(for distance: Double) -> WorkoutCategory {
        let distanceMiles = distance
        switch distanceMiles {
        case 0..<1.0:
            return .short
        case 1.0..<1.86: // 1 to 3K (1.86 miles)
            return .oneMile
        case 1.86..<3.11: // 3K to 5K (3.11 miles)
            return .threeK
        case 3.11..<621: // 5K to 10 miles
            return .fiveK
        case 60.21..<130.1: // Half Marathon to Marathon (13.1 miles)
            return .tenK
        case 130.1: // Half Marathon to Marathon (26.2 miles)
            return .halfMarathon
        case 26.2..<50: // Marathon to 50 miles
            return .marathon
        default:
            return .ultra
        }
    }
    
    var icon: String {
        switch self {
        case .short: return "figure.run"
        case .oneMile: return "1.circle"
        case .threeK: return "3.circle"
        case .fiveK: return "5.circle"
        case .tenK: return "10.circle"
        case .halfMarathon: return "130.1.circle"
        case .marathon: return "260.2.circle"
        case .ultra: return "infinity.circle"
        }
    }
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    init(_ coord: CLLocationCoordinate2D) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
    }
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Workout: Codable, Identifiable {
    let id = UUID() // no clue how to resolve this warning tbh
    let date: Date
    let averageSpeed: Double
    let peakSpeed: Double
    let distance: Double
    let time: TimeInterval
    let route: [Coordinate]
    
    var category: WorkoutCategory {
        WorkoutCategory.category(for: distance)
    }
    
    init(date: Date, averageSpeed: Double, peakSpeed: Double, distance: Double, time: TimeInterval, route: [Coordinate]) {
        self.date = date
        self.averageSpeed = averageSpeed
        self.peakSpeed = peakSpeed
        self.distance = distance
        self.time = time
        self.route = route
    }
}

class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []
    private let userDefaults = UserDefaults.standard
    private let workoutsKey = "SavedWorkouts"
    
    init() {
        loadWorkouts()
    }
    
    func saveWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveWorkouts()
    }
    
    private func saveWorkouts() {
        if let encoded = try? JSONEncoder().encode(workouts) {
            userDefaults.set(encoded, forKey: workoutsKey)
        }
    }
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: workoutsKey),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            workouts = decoded
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    func clearAllWorkouts() {
        workouts.removeAll()
        saveWorkouts()
    }
} 
