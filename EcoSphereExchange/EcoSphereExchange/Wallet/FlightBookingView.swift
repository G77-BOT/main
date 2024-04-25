//
//  FlightBookingView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

struct FlightBookingView: View {
    @State private var origin: String = ""
    @State private var destination: String = ""
    @State private var departureDate: Date = Date()
    @State private var returnDate: Date = Date()
    @State private var isShowingResults: Bool = false
    @State private var flights: [Flight] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Flight Booking")
                    .font(.title)
                
                Form {
                    Section(header: Text("Flight Details")) {
                        TextField("Origin", text: $origin)
                        TextField("Destination", text: $destination)
                        DatePicker("Departure Date", selection: $departureDate, displayedComponents: .date)
                        DatePicker("Return Date", selection: $returnDate, displayedComponents: .date)
                    }
                }
                
                Button(action: {
                    searchFlights()
                    isShowingResults = true
                }) {
                    Text("Search Flights")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(origin.isEmpty || destination.isEmpty)
                
                if isShowingResults {
                    FlightResultsView(flights: flights)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Flights")
        }
    }
    
    private func searchFlights() {
        // Simulate flight search with AI algorithm
        // Replace with actual implementation
        
        // Simulating flights found
        flights = [
            Flight(airline: "Airline A", origin: "Origin A", destination: "Destination A", departureDate: departureDate, returnDate: returnDate),
            Flight(airline: "Airline B", origin: "Origin B", destination: "Destination B", departureDate: departureDate, returnDate: returnDate),
            Flight(airline: "Airline C", origin: "Origin C", destination: "Destination C", departureDate: departureDate, returnDate: returnDate),
            Flight(airline: "Airline D", origin: "Origin D", destination: "Destination D", departureDate: departureDate, returnDate: returnDate),
        ]
    }
}

struct FlightResultsView: View {
    var flights: [Flight]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Flight Results")
                .font(.title)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(flights) { flight in
                        FlightCardView(flight: flight)
                    }
                }
                .padding()
            }
        }
    }
}

struct FlightCardView: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.airline)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Origin: \(flight.origin)")
                .foregroundColor(.gray)
            
            Text("Destination: \(flight.destination)")
                .foregroundColor(.gray)
            
            Text("Departure Date: \(formattedDate(flight.departureDate))")
                .foregroundColor(.gray)
            
            Text("Return Date: \(formattedDate(flight.returnDate))")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}

struct Flight: Identifiable {
    let id = UUID()
    let airline: String
    let origin: String
    let destination: String
    let departureDate: Date
    let returnDate: Date
}
