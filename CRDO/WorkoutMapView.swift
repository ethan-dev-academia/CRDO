import SwiftUI
import MapKit
import CoreLocation

// MARK: - Workout Map View

struct WorkoutMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var workoutRoute: [CLLocationCoordinate2D] = []
    @State private var isTrackingWorkout = false
    @State private var workoutStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var distance: Double = 0.0
    @State private var pace: Double = 0.0
    @State private var currentSpeed: Double = 0.0
    @State private var averageSpeed: Double = 0.0
    @State private var elevation: Double = 0.0
    @State private var caloriesBurned: Double = 0.0
    @State private var showingGPSDetails = false
    
    // Timer for workout duration
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var distanceString: String {
        String(format: "%.2f", distance / 1000) // Convert to kilometers
    }
    
    private var paceString: String {
        if pace > 0 {
            let minutes = Int(pace) / 60
            let seconds = Int(pace) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "--:--"
    }
    
    private var speedString: String {
        String(format: "%.1f", currentSpeed * 3.6) // Convert m/s to km/h
    }
    
    private var averageSpeedString: String {
        String(format: "%.1f", averageSpeed * 3.6) // Convert m/s to km/h
    }
    
    private var elevationString: String {
        String(format: "%.0f", elevation)
    }
    
    private var caloriesString: String {
        String(format: "%.0f", caloriesBurned)
    }
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: workoutAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    WorkoutAnnotationView(annotation: annotation)
                }
            }
            .overlay(
                // Route line overlay
                Path { path in
                    if workoutRoute.count > 1 {
                        path.move(to: locationManager.point(for: workoutRoute[0]))
                        for i in 1..<workoutRoute.count {
                            path.addLine(to: locationManager.point(for: workoutRoute[i]))
                        }
                    }
                }
                .stroke(Color.gold, lineWidth: 4)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            )
            .ignoresSafeArea()
            
            // Top Navigation Bar
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.gold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    Text("RUNNING WORKOUT")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.gold)
                    
                    Spacer()
                    
                    // GPS Details Button
                    Button(action: {
                        showingGPSDetails.toggle()
                    }) {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gold.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Manual GPS Request Button (for testing)
                    Button(action: {
                        locationManager.requestLocationPermission()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Workout Stats Panel
                VStack(spacing: 16) {
                    // Stats Row
                    HStack(spacing: 20) {
                        StatCard(title: "TIME", value: timeString, icon: "clock.fill")
                        StatCard(title: "DISTANCE", value: "\(distanceString) km", icon: "figure.run")
                        StatCard(title: "PACE", value: "\(paceString)/km", icon: "speedometer")
                    }
                    
                    // Additional Stats Row
                    HStack(spacing: 20) {
                        StatCard(title: "SPEED", value: "\(speedString) km/h", icon: "speedometer")
                        StatCard(title: "ELEVATION", value: "\(elevationString) m", icon: "mountain.2.fill")
                        StatCard(title: "CALORIES", value: "\(caloriesString)", icon: "flame.fill")
                    }
                    
                    // Control Button
                    Button(action: {
                        if isTrackingWorkout {
                            stopWorkout()
                        } else {
                            startWorkout()
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: isTrackingWorkout ? "stop.fill" : "play.fill")
                                .font(.title2)
                            
                            Text(isTrackingWorkout ? "STOP WORKOUT" : "START WORKOUT")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(isTrackingWorkout ? Color.red.opacity(0.8) : Color.gold.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(isTrackingWorkout ? Color.red : Color.gold, lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
            
            // GPS Details Overlay
            if showingGPSDetails {
                GPSDetailsOverlay(locationManager: locationManager, onClose: {
                    showingGPSDetails = false
                })
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showingGPSDetails)
            }
            
            // GPS Status Indicator (for debugging)
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(locationManager.isLocationEnabled ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(locationManager.isLocationEnabled ? "GPS ON" : "GPS OFF")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            #if targetEnvironment(simulator)
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                                Text("SIMULATOR")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            #endif
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.7))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 120)
                Spacer()
            }
        }
        .statusBarHidden(true)
        .onAppear {
            print("WorkoutMapView appeared, requesting location permission")
            locationManager.requestLocationPermission()
        }
        .onReceive(timer) { _ in
            if isTrackingWorkout {
                elapsedTime = Date().timeIntervalSince(workoutStartTime ?? Date())
                updatePace()
            }
        }
        .onReceive(locationManager.$location) { location in
            if let location = location, isTrackingWorkout {
                handleNewLocation(location)
            }
        }
    }
    
    private var workoutAnnotations: [WorkoutAnnotation] {
        var annotations: [WorkoutAnnotation] = []
        
        if !workoutRoute.isEmpty {
            // Start point
            annotations.append(WorkoutAnnotation(
                id: 0,
                coordinate: workoutRoute[0],
                type: .start
            ))
            
            // End point (if different from start)
            if workoutRoute.count > 1 {
                annotations.append(WorkoutAnnotation(
                    id: workoutRoute.count - 1,
                    coordinate: workoutRoute.last!,
                    type: .end
                ))
            }
        }
        
        return annotations
    }
    
    private func startWorkout() {
        isTrackingWorkout = true
        workoutStartTime = Date()
        workoutRoute.removeAll()
        distance = 0.0
        pace = 0.0
        
        // Add initial location if available
        if let location = locationManager.location {
            workoutRoute.append(location.coordinate)
        }
    }
    
    private func stopWorkout() {
        isTrackingWorkout = false
        // Here you would save the workout data
        print("Workout completed: \(distanceString) km in \(timeString)")
    }
    
    private func handleNewLocation(_ location: CLLocation) {
        if isTrackingWorkout {
            // Add new point to route
            workoutRoute.append(location.coordinate)
            
            // Calculate distance
            if workoutRoute.count > 1 {
                let previousLocation = CLLocation(latitude: workoutRoute[workoutRoute.count - 2].latitude,
                                                longitude: workoutRoute[workoutRoute.count - 2].longitude)
                distance += location.distance(from: previousLocation)
            }
            
            // Update GPS metrics
            currentSpeed = location.speed > 0 ? location.speed : 0
            elevation = location.altitude
            updateCaloriesBurned()
            updateAverageSpeed()
            
            // Update map region to follow user
            withAnimation(.easeInOut(duration: 0.5)) {
                locationManager.region.center = location.coordinate
            }
        }
    }
    
    private func updateCaloriesBurned() {
        // Simple calorie calculation based on distance and time
        // In a real app, you'd use more sophisticated algorithms
        let weight = 70.0 // kg - would come from user profile
        let speed = currentSpeed * 3.6 // km/h
        let timeHours = elapsedTime / 3600
        
        // Calories = MET * weight * time
        let met = speed > 0 ? (speed * 0.1 + 3.5) : 3.5
        caloriesBurned = met * weight * timeHours
    }
    
    private func updateAverageSpeed() {
        if elapsedTime > 0 && distance > 0 {
            averageSpeed = distance / elapsedTime
        }
    }
    
    private func updatePace() {
        if distance > 0 && elapsedTime > 0 {
            pace = elapsedTime / (distance / 1000) // seconds per kilometer
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationAccuracy: CLLocationAccuracy = 0
    @Published var isLocationEnabled = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters for more precision
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("Running in iOS Simulator - GPS will be simulated")
        #else
        print("Running on device - GPS will use real location")
        #endif
    }
    
    func requestLocationPermission() {
        print("Requesting location permission...")
        
        #if targetEnvironment(simulator)
        // Simulate GPS for simulator
        print("Simulator detected - providing simulated location")
        simulateLocationUpdates()
        return
        #endif
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("Location status: not determined, requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorized, starting updates")
            startUpdatingLocation()
        @unknown default:
            print("Unknown authorization status")
            break
        }
    }
    
    func startUpdatingLocation() {
        print("Starting location updates...")
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Simulator Support
    
    private func simulateLocationUpdates() {
        print("Starting simulated location updates")
        isLocationEnabled = true
        
        // Create a simulated location (San Francisco)
        let simulatedLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            course: 0.0,
            speed: 2.0, // 2 m/s = ~7.2 km/h
            timestamp: Date()
        )
        
        // Update location immediately
        self.location = simulatedLocation
        self.locationAccuracy = simulatedLocation.horizontalAccuracy
        
        // Start simulated movement
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard self.isLocationEnabled else {
                timer.invalidate()
                return
            }
            
            // Simulate movement along a path
            let timeInterval = Date().timeIntervalSince1970
            let latitudeOffset = sin(timeInterval * 0.001) * 0.0001
            let longitudeOffset = cos(timeInterval * 0.001) * 0.0001
            
            let newLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.7749 + latitudeOffset,
                    longitude: -122.4194 + longitudeOffset
                ),
                altitude: 10.0 + sin(timeInterval * 0.01) * 5.0,
                horizontalAccuracy: 5.0,
                verticalAccuracy: 5.0,
                course: (timeInterval * 10).truncatingRemainder(dividingBy: 360),
                speed: 2.0 + sin(timeInterval * 0.1) * 0.5,
                timestamp: Date()
            )
            
            self.location = newLocation
            self.locationAccuracy = newLocation.horizontalAccuracy
            
            // Update region to follow simulated movement
            withAnimation(.easeInOut(duration: 0.5)) {
                self.region.center = newLocation.coordinate
            }
            
            print("Simulated location: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        self.location = location
        self.locationAccuracy = location.horizontalAccuracy
        self.isLocationEnabled = true
        
        // Update region to follow user
        withAnimation(.easeInOut(duration: 0.5)) {
            region.center = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        self.isLocationEnabled = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorized, starting updates")
            startUpdatingLocation()
            isLocationEnabled = true
        default:
            print("Location not authorized, stopping updates")
            stopUpdatingLocation()
            isLocationEnabled = false
        }
    }
    
    // Helper function to convert coordinate to map point
    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        // This is a simplified conversion - in a real app you'd use MKMapView's conversion methods
        return CGPoint(x: coordinate.longitude, y: coordinate.latitude)
    }
}

// MARK: - Stat Card

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
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
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

// MARK: - Workout Annotation

struct WorkoutAnnotation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    
    enum AnnotationType {
        case start, end, waypoint
    }
}

// MARK: - Workout Annotation View

struct WorkoutAnnotationView: View {
    let annotation: WorkoutAnnotation
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                )
            
            if annotation.type == .start || annotation.type == .end {
                Text(annotation.type == .start ? "START" : "END")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.7))
                    )
            }
        }
    }
    
    private var iconName: String {
        switch annotation.type {
        case .start:
            return "flag.fill"
        case .end:
            return "flag.checkered"
        case .waypoint:
            return "circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch annotation.type {
        case .start:
            return .green
        case .end:
            return .red
        case .waypoint:
            return .gold
        }
    }
}

// MARK: - GPS Details Overlay

struct GPSDetailsOverlay: View {
    @ObservedObject var locationManager: LocationManager
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("GPS DETAILS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gold)
                
                Spacer()
                
                Button("Close") {
                    onClose()
                }
                .foregroundColor(.gold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.black.opacity(0.9))
            
            // GPS Information
            ScrollView {
                VStack(spacing: 16) {
                    // Location Details
                    GPSDetailCard(
                        title: "Current Location",
                        value: locationString,
                        subtitle: "GPS Coordinates",
                        icon: "location.fill"
                    )
                    
                    // Accuracy
                    GPSDetailCard(
                        title: "GPS Accuracy",
                        value: accuracyString,
                        subtitle: "Location Precision",
                        icon: "target"
                    )
                    
                    // Speed Details
                    GPSDetailCard(
                        title: "Current Speed",
                        value: speedString,
                        subtitle: "Real-time Velocity",
                        icon: "speedometer"
                    )
                    
                    // Altitude
                    GPSDetailCard(
                        title: "Altitude",
                        value: altitudeString,
                        subtitle: "Elevation Above Sea Level",
                        icon: "mountain.2.fill"
                    )
                    
                    // Heading
                    GPSDetailCard(
                        title: "Heading",
                        value: headingString,
                        subtitle: "Direction of Travel",
                        icon: "location.north.fill"
                    )
                    
                    // Signal Strength
                    GPSDetailCard(
                        title: "GPS Signal",
                        value: signalStrengthString,
                        subtitle: "Satellite Connection",
                        icon: "antenna.radiowaves.left.and.right"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(Color.black.opacity(0.95))
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.top, 100)
    }
    
    private var locationString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulator Mode"
            #else
            return "Not Available"
            #endif
        }
        return String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    private var accuracyString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulated"
            #else
            return "Not Available"
            #endif
        }
        return String(format: "±%.1f meters", location.horizontalAccuracy)
    }
    
    private var speedString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulated"
            #else
            return "Not Available"
            #endif
        }
        let speedKmh = location.speed * 3.6
        return String(format: "%.1f km/h", speedKmh > 0 ? speedKmh : 0)
    }
    
    private var altitudeString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulated"
            #else
            return "Not Available"
            #endif
        }
        return String(format: "%.0f meters", location.altitude)
    }
    
    private var headingString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulated"
            #else
            return "Not Available"
            #endif
        }
        let heading = location.course
        if heading >= 0 {
            let direction = getDirection(heading)
            return String(format: "%.0f° %@", heading, direction)
        }
        return "Not Available"
    }
    
    private var signalStrengthString: String {
        guard let location = locationManager.location else { 
            #if targetEnvironment(simulator)
            return "Simulated"
            #else
            return "Not Available"
            #endif
        }
        let accuracy = location.horizontalAccuracy
        
        switch accuracy {
        case 0..<5:
            return "Excellent"
        case 5..<10:
            return "Good"
        case 10..<20:
            return "Fair"
        case 20..<50:
            return "Poor"
        default:
            return "Very Poor"
        }
    }
    
    private func getDirection(_ heading: CLLocationDirection) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((heading + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - GPS Detail Card

struct GPSDetailCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.gold)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.gold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gold.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    WorkoutMapView()
} 