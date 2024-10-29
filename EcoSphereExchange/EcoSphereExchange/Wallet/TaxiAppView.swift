import SwiftUI
import MapKit

struct TaxiAppView: View {
    @StateObject private var viewModel = TaxiAppViewModel()
    @State private var region = MKCoordinateRegion()
    @State private var showingServicePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: .constant(.follow),
                    annotationItems: viewModel.annotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        VStack {
                            Image(systemName: annotation.imageName)
                                .font(.title)
                                .foregroundColor(annotation.color)
                            Text(annotation.title)
                                .font(.caption)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Floating panels
                VStack {
                    if viewModel.isSearchingDriver {
                        SearchingDriverView()
                    }
                    
                    Spacer()
                    
                    // Bottom Panel
                    RideDetailsPanel(viewModel: viewModel)
                        .transition(.move(edge: .bottom))
                }
                
                // Service Selection Sheet
                if showingServicePicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingServicePicker = false
                        }
                    
                    ServicePickerView(viewModel: viewModel)
                        .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Ride Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshPrices) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Price Alert", isPresented: $viewModel.showingPriceAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.priceAlertMessage)
            }
        }
        .onAppear {
            viewModel.startLocationUpdates()
        }
    }
}

struct SearchingDriverView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding nearby drivers...")
                .font(.headline)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .padding()
    }
}

struct RideDetailsPanel: View {
    @ObservedObject var viewModel: TaxiAppViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Location & Destination
            VStack(spacing: 12) {
                LocationField(
                    icon: "location.fill",
                    text: viewModel.currentLocation,
                    color: .blue
                )
                
                LocationField(
                    icon: "mappin.circle.fill",
                    text: viewModel.destination,
                    color: .red
                )
            }
            .padding()
            
            // Service Selection
            if let comparison = viewModel.priceComparison {
                ServiceComparisonView(comparison: comparison, selectedService: $viewModel.selectedService)
            }
            
            // Book Button
            Button(action: viewModel.bookRide) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Book Ride")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 5)
    }
}

struct LocationField: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .lineLimit(1)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ServiceComparisonView: View {
    let comparison: PriceComparison
    @Binding var selectedService: RideService?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Available Services")
                .font(.headline)
            
            ForEach(Array(comparison.prices.keys), id: \.self) { service in
                ServiceRow(
                    service: service,
                    price: comparison.prices[service] ?? 0,
                    isSelected: selectedService == service
                ) {
                    selectedService = service
                }
            }
        }
    }
}

struct ServiceRow: View {
    let service: RideService
    let price: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(service.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(service.name)
                        .font(.headline)
                    Text("\(Int(service.estimatedTime)) min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("$\(String(format: "%.2f", price))")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class TaxiAppViewModel: ObservableObject {
    @Published var currentLocation = "Current Location"
    @Published var destination = "Destination"
    @Published var isSearchingDriver = false
    @Published var isLoading = false
    @Published var selectedService: RideService?
    @Published var priceComparison: PriceComparison?
    @Published var showingPriceAlert = false
    @Published var priceAlertMessage = ""
    @Published var annotations: [MapAnnotation] = []
    
    private let rideTracker = RideTrackerAlgorithm()
    private var timer: Timer?
    
    init() {
        startPriceTracking()
    }
    
    func startLocationUpdates() {
        // Implement location updates
    }
    
    func refreshPrices() {
        isLoading = true
        
        let route = RideRoute(
            origin: Location(latitude: 0, longitude: 0, address: currentLocation),
            destination: Location(latitude: 0, longitude: 0, address: destination),
            time: Date()
        )
        
        let analysis = rideTracker.analyzePrices(route: route)
        
        DispatchQueue.main.async {
            self.priceComparison = analysis.priceComparison
            self.selectedService = analysis.bestOption.service
            self.isLoading = false
            
            // Show price alerts
            if let alert = analysis.priceAlerts.first {
                switch alert {
                case .significantPriceDrop(let service, let change):
                    self.showPriceAlert("\(service.name) prices dropped by \(Int(abs(change * 100)))%!")
                case .priceSpike(let service, let change):
                    self.showPriceAlert("\(service.name) prices increased by \(Int(change * 100))%")
                case .bestTimeToBook(let time):
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    self.showPriceAlert("Best time to book: \(formatter.string(from: time))")
                }
            }
        }
    }
    
    func bookRide() {
        guard let service = selectedService else { return }
        
        isSearchingDriver = true
        
        // Simulate booking process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSearchingDriver = false
            self.showPriceAlert("Ride booked with \(service.name)!")
        }
    }
    
    private func startPriceTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }
    
    private func showPriceAlert(_ message: String) {
        priceAlertMessage = message
        showingPriceAlert = true
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let imageName: String
    let color: Color
}

// View Modifiers
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension RideService {
    var iconName: String {
        switch self {
        case .uber: return "uber_icon"
        case .lyft: return "lyft_icon"
        case .taxi: return "taxi_icon"
        }
    }
    
    var name: String {
        switch self {
        case .uber: return "Uber"
        case .lyft: return "Lyft"
        case .taxi: return "Local Taxi"
        }
    }
    
    var estimatedTime: TimeInterval {
        // Implement actual time estimation
        return Double.random(in: 5...15)
    }
}
