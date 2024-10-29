import SwiftUI

struct FlightBookingView: View {
    @StateObject private var viewModel = FlightBookingViewModel()
    @State private var showingFilters = false
    @State private var showingSort = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Form
                FlightSearchForm(viewModel: viewModel)
                    .padding()
                
                // Filters and Sort
                HStack {
                    Button(action: { showingFilters = true }) {
                        HStack {
                            Image(systemName: "line.horizontal.3.decrease.circle")
                            Text("Filters")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSort = true }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("Searching flights...")
                        .padding()
                } else if !viewModel.flights.isEmpty {
                    // Flight Results
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.flights) { flight in
                                FlightCard(flight: flight)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                } else if viewModel.hasSearched {
                    // No Results View
                    NoFlightsView()
                }
            }
            .navigationTitle("Flight Booking")
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSort) {
                SortView(viewModel: viewModel)
            }
            .alert("Best Time to Buy", isPresented: $viewModel.showingPriceAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.priceAlertMessage)
            }
        }
    }
}

struct FlightSearchForm: View {
    @ObservedObject var viewModel: FlightBookingViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("From", text: $viewModel.origin)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                TextField("To", text: $viewModel.destination)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                DatePicker("Departure", selection: $viewModel.departureDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                if viewModel.isRoundTrip {
                    DatePicker("Return", selection: $viewModel.returnDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            
            Toggle("Round Trip", isOn: $viewModel.isRoundTrip)
            
            Button(action: viewModel.searchFlights) {
                Text("Search Flights")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isValidSearch)
        }
    }
}

struct FlightCard: View {
    let flight: Flight
    
    var body: some View {
        VStack(spacing: 12) {
            // Airline Info
            HStack {
                Image(flight.airline.lowercased())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(flight.airline)
                        .font(.headline)
                    Text(flight.flightNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                PriceTag(price: flight.price)
            }
            
            Divider()
            
            // Flight Details
            HStack(spacing: 20) {
                // Departure
                FlightTimeView(
                    time: flight.departureTime,
                    airport: flight.origin,
                    isOrigin: true
                )
                
                // Flight Path
                FlightPathView(duration: flight.duration)
                
                // Arrival
                FlightTimeView(
                    time: flight.arrivalTime,
                    airport: flight.destination,
                    isOrigin: false
                )
            }
            
            Divider()
            
            // Additional Info
            HStack {
                Label("\(flight.stops) stops", systemImage: "airplane")
                Spacer()
                Label(flight.aircraft, systemImage: "info.circle")
                Spacer()
                Label("\(flight.seatsAvailable) seats left", systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            // Book Button
            Button(action: {}) {
                Text("Book Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct FlightTimeView: View {
    let time: Date
    let airport: String
    let isOrigin: Bool
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: isOrigin ? .leading : .trailing) {
            Text(timeFormatter.string(from: time))
                .font(.headline)
            Text(airport)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct FlightPathView: View {
    let duration: TimeInterval
    
    var durationText: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .frame(width: 8, height: 8)
                Rectangle()
                    .frame(height: 1)
                Circle()
                    .frame(width: 8, height: 8)
            }
            .foregroundColor(.gray)
            
            Text(durationText)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct PriceTag: View {
    let price: Double
    
    var body: some View {
        Text("$\(String(format: "%.2f", price))")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

struct NoFlightsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Flights Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your search criteria")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: FlightBookingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Price Range")) {
                    PriceRangeSlider(range: $viewModel.priceRange)
                }
                
                Section(header: Text("Airlines")) {
                    ForEach(viewModel.availableAirlines, id: \.self) { airline in
                        Toggle(airline, isOn: binding(for: airline))
                    }
                }
                
                Section(header: Text("Stops")) {
                    Picker("Maximum Stops", selection: $viewModel.maxStops) {
                        Text("Non-stop").tag(0)
                        Text("1 stop").tag(1)
                        Text("2+ stops").tag(2)
                    }
                }
                
                Section(header: Text("Departure Time")) {
                    TimeRangePicker(range: $viewModel.departureTimeRange)
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func binding(for airline: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedAirlines.contains(airline) },
            set: { isSelected in
                if isSelected {
                    viewModel.selectedAirlines.insert(airline)
                } else {
                    viewModel.selectedAirlines.remove(airline)
                }
            }
        )
    }
}

struct SortView: View {
    @ObservedObject var viewModel: FlightBookingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(FlightSortOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.description)
                            Spacer()
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.sortOption = option
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class FlightBookingViewModel: ObservableObject {
    @Published var origin = ""
    @Published var destination = ""
    @Published var departureDate = Date()
    @Published var returnDate = Date()
    @Published var isRoundTrip = false
    @Published var flights: [Flight] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var showingPriceAlert = false
    @Published var priceAlertMessage = ""
    
    // Filters
    @Published var priceRange: ClosedRange<Double> = 100...1000
    @Published var selectedAirlines: Set<String> = []
    @Published var maxStops = 1
    @Published var departureTimeRange: ClosedRange<Date> = Date()...Date().addingTimeInterval(86400)
    
    // Sort
    @Published var sortOption: FlightSortOption = .price
    
    private let priceTracker = FlightPriceTrackerAlgorithm()
    
    var isValidSearch: Bool {
        !origin.isEmpty && !destination.isEmpty
    }
    
    var availableAirlines: [String] {
        ["American Airlines", "Delta", "United", "Southwest", "JetBlue", "Emirates", "British Airways"]
    }
    
    func searchFlights() {
        isLoading = true
        hasSearched = true
        
        // Create route for price tracking
        let route = FlightRoute(
            origin: origin,
            destination: destination,
            date: departureDate
        )
        
        // Analyze prices using the algorithm
        let analysis = priceTracker.trackFlightPrices(route: route)
        
        // Update UI based on analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.flights = self.generateFlights()
            self.isLoading = false
            
            // Show price alert if beneficial
            if let recommendation = analysis.recommendations.first {
                switch recommendation {
                case .buyNow(let reason):
                    self.showPriceAlert("Recommended to book now: \(reason)")
                case .wait(let days, let reason):
                    self.showPriceAlert("Wait \(days) days before booking: \(reason)")
                case .considerAlternative(let route, _):
                    self.showPriceAlert("Consider alternative route: \(route.origin) to \(route.destination)")
                }
            }
        }
    }
    
    private func showPriceAlert(_ message: String) {
        priceAlertMessage = message
        showingPriceAlert = true
    }
    
    private func generateFlights() -> [Flight] {
        // Simulate flight generation
        var flights: [Flight] = []
        
        for _ in 0..<15 {
            let flight = Flight(
                id: UUID(),
                airline: availableAirlines.randomElement() ?? "",
                flightNumber: "FL\(Int.random(in: 100...999))",
                origin: origin,
                destination: destination,
                departureTime: departureDate,
                arrivalTime: departureDate.addingTimeInterval(Double.random(in: 7200...28800)),
                price: Double.random(in: 200...1000),
                stops: Int.random(in: 0...2),
                aircraft: "Boeing 737",
                seatsAvailable: Int.random(in: 1...50)
            )
            flights.append(flight)
        }
        
        return applyFiltersAndSort(flights)
    }
    
    private func applyFiltersAndSort(_ flights: [Flight]) -> [Flight] {
        var filtered = flights
        
        // Apply filters
        filtered = filtered.filter { flight in
            let priceInRange = priceRange.contains(flight.price)
            let airlineSelected = selectedAirlines.isEmpty || selectedAirlines.contains(flight.airline)
            let stopsInRange = flight.stops <= maxStops
            
            return priceInRange && airlineSelected && stopsInRange
        }
        
        // Apply sorting
        filtered.sort { first, second in
            switch sortOption {
            case .price:
                return first.price < second.price
            case .duration:
                return first.duration < second.duration
            case .departureTime:
                return first.departureTime < second.departureTime
            case .airline:
                return first.airline < second.airline
            }
        }
        
        return filtered
    }
}

struct Flight: Identifiable {
    let id: UUID
    let airline: String
    let flightNumber: String
    let origin: String
    let destination: String
    let departureTime: Date
    let arrivalTime: Date
    let price: Double
    let stops: Int
    let aircraft: String
    let seatsAvailable: Int
    
    var duration: TimeInterval {
        arrivalTime.timeIntervalSince(departureTime)
    }
}

enum FlightSortOption: CaseIterable {
    case price
    case duration
    case departureTime
    case airline
    
    var description: String {
        switch self {
        case .price: return "Price (Lowest First)"
        case .duration: return "Duration (Shortest First)"
        case .departureTime: return "Departure Time"
        case .airline: return "Airline"
        }
    }
}
