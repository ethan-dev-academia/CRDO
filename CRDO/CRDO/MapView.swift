import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Only update when moving5s
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var workoutStore = WorkoutStore()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isTimerRunning = false
    @State private var isPaused = false
    @State private var isEnded = false
    @State private var totalDistance: Double = 0
    @State private var lastLocation: CLLocation?
    @State private var showEndConfirmation = false
    @State private var speedReadings: [Double] = []
    @State private var peakSpeed: Double = 0
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var smoothedCoordinates: [CLLocationCoordinate2D] = []
    @Environment(\.dismiss) var dismiss
    
    var speedMph: Double {
        if isPaused || isEnded { return 0 }
        let speed = locationManager.location?.speed ?? -1
        if speed < 0 { return 0 }
        return speed * 2.237
    }
    
    var averageSpeed: Double {
        guard !speedReadings.isEmpty else { return 0 }
        return speedReadings.reduce(0, +) / Double(speedReadings.count)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LiveMapView(
                region: $region,
                routeCoordinates: routeCoordinates,
                showsUserLocation: true
            )
            .edgesIgnoringSafeArea(.all)
            .onReceive(locationManager.$location) { location in
                if let location = location {
                    region.center = location.coordinate
                    if isTimerRunning && !isPaused && !isEnded {
                        let smoothedCoordinate = smoothCoordinate(location.coordinate)
                        updateDistance(with: location)
                        updateSpeedStats()
                        routeCoordinates.append(smoothedCoordinate)
                    }
                }
            }
            
            // Top buttons
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("BACK")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.9))
                    }
                    Spacer()
                    if !isEnded {
                        if !isTimerRunning {
                            Button(action: {
                                startTimer()
                            }) {
                                Text("START")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.9))
                            }
                        } else {
                            HStack(spacing: 8) {
                                Button(action: {
                                    if isPaused {
                                        resumeTimer()
                                    } else {
                                        pauseTimer()
                                    }
                                }) {
                                    Text(isPaused ? "RESUME" : "PAUSE")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.9))
                                }
                                Button(action: {
                                    showEndConfirmation = true
                                }) {
                                    Text("END")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.9))
                                }
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("SPEED:")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.1f mph", speedMph))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 3)
                    .opacity(0.2)
                HStack {
                    Text("DISTANCE:")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isEnded ? .green : .white)
                    Spacer()
                    Text(String(format: "%.2f mi", totalDistance))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isEnded ? .green : .white)
                }
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 3)
                    .opacity(0.2)
                HStack {
                    Text("TIME:")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isEnded ? .green : .white)
                    Spacer()
                    HStack(spacing: 8) {
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(isEnded ? .green : .white)
                        if isPaused {
                            Text("PAUSED")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(Color.black.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.bottom, 0)
        }
        .navigationBarHidden(true)
        .alert("End Workout?", isPresented: $showEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) { endWorkout() }
        } message: {
            Text("Are you sure you want to end this workout?")
        }
    }
    
    private func updateDistance(with newLocation: CLLocation) {
        if let lastLocation = lastLocation {
            let distance = newLocation.distance(from: lastLocation)
            totalDistance += distance / 1609.34 // Convert meters to miles
        }
        lastLocation = newLocation
    }
    
    private func updateSpeedStats() {
        let currentSpeed = speedMph
        if currentSpeed > 0 {
            speedReadings.append(currentSpeed)
            if currentSpeed > peakSpeed {
                peakSpeed = currentSpeed
            }
        }
    }
    
    private func smoothCoordinate(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // Enhanced smoothing with larger window and speed-based filtering
        smoothedCoordinates.append(coordinate)
        
        // Keep last 10 points for better smoothing
        if smoothedCoordinates.count > 10 {
            smoothedCoordinates.removeFirst()
        }
        
        // Only smooth if we have enough points
        guard smoothedCoordinates.count >= 3 else {
            return coordinate
        }
        
        // Calculate weighted average (more weight to recent points)
        var totalWeight = 0.0
        var weightedLat = 0.0
        var weightedLon = 0.0      
        for (index, coord) in smoothedCoordinates.enumerated() {
            let weight = Double(index + 1) // More weight to recent points
            totalWeight += weight
            weightedLat += coord.latitude * weight
            weightedLon += coord.longitude * weight
        }
        
        let avgLat = weightedLat / totalWeight
        let avgLon = weightedLon / totalWeight
        
        // Apply additional smoothing if speed is low (likely GPS noise)
        let currentSpeed = locationManager.location?.speed ?? 0
        if currentSpeed < 1.0 { // Less than 1m/s
            // Use more aggressive smoothing for slow movement
            let recentCoords = Array(smoothedCoordinates.suffix(5))
            let simpleAvgLat = recentCoords.map { $0.latitude }.reduce(0, +) / Double(recentCoords.count)
            let simpleAvgLon = recentCoords.map { $0.longitude }.reduce(0, +) / Double(recentCoords.count)
            return CLLocationCoordinate2D(latitude: simpleAvgLat, longitude: simpleAvgLon)
        }
        
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
    
    private func startTimer() {
        isTimerRunning = true
        isPaused = false
        // Reset stats for new workout
        speedReadings.removeAll()
        peakSpeed = 0
        routeCoordinates.removeAll()
        smoothedCoordinates.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeTimer() {
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func endWorkout() {
        isEnded = true
        isTimerRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        // Save workout
        let workout = Workout(
            date: Date(),
            averageSpeed: averageSpeed,
            peakSpeed: peakSpeed,
            distance: totalDistance,
            time: elapsedTime,
            route: routeCoordinates.map { Coordinate($0) }
        )
        workoutStore.saveWorkout(workout)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

import MapKit

struct LiveMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeCoordinates: [CLLocationCoordinate2D]
    let showsUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: false)
        
        // Update polyline
        mapView.removeOverlays(mapView.overlays)
        if routeCoordinates.count > 1 {
            let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemGreen
                renderer.lineWidth = 5
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

#Preview {
    NavigationView {
        MapView()
    }
} 