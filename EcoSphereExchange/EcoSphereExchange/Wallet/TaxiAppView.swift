//
//  CallTaxiView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//


import SwiftUI

struct CallTaxiView: View {
    @State private var driver: Driver?
    @State private var rideStatus: RideStatus = .findingDriver
    @State private var isCallButtonDisabled: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if rideStatus == .findingDriver {
                ProgressView("Finding a Driver...")
                    .padding()
            } else {
                if let driver = driver {
                    DriverInfoView(driver: driver)
                        .padding()
                }
                
                EstimatedArrivalTimeView(estimatedArrivalTime: driver?.estimatedArrivalTime ?? 5)
                    .padding()
                
                Button(action: callDriver) {
                    Text("Call Driver")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .opacity(isCallButtonDisabled ? 0.5 : 1.0)
                }
                .disabled(isCallButtonDisabled)
                .padding()
            }
            
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            integrateWithRideBookingServices()
        }
    }
    
    
    
    private func integrateWithRideBookingServices() {
        // Simulate integrating with multiple ride booking services
        
        // Simulate finding a driver from Uber API
        UberAPIManager.findDriver { result in
            switch result {
            case .success(let driver):
                updateDriverInfo(driver)
            case .failure(let error):
                print("Error finding Uber driver: \(error.localizedDescription)")
                // Handle error scenario
            }
        }
        
        // Simulate finding a driver from Lyft API
        LyftAPIManager.findDriver { result in
            switch result {
            case .success(let driver):
                updateDriverInfo(driver)
            case .failure(let error):
                print("Error finding Lyft driver: \(error.localizedDescription)")
                // Handle error scenario
            }
        }
        
        // Simulate finding a driver from Taxi Company API
        TaxiCompanyAPIManager.findDriver { result in
            switch result {
            case .success(let driver):
                updateDriverInfo(driver)
            case .failure(let error):
                print("Error finding taxi company driver: \(error.localizedDescription)")
                // Handle error scenario
            }
        }
    }
    
    private func callDriver() {
        guard let phoneNumber = driver?.phoneNumber,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [phoneNumber], applicationActivities: nil)
        window.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }


    private func updateDriverInfo(_ driver: Driver) {
        self.driver = driver
        rideStatus = .driverFound
    }
}

// Simulated Uber API Manager
struct UberAPIManager {
    static func findDriver(completion: @escaping (Result<Driver, Error>) -> Void) {
        // Simulate finding a driver from Uber API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let driver = Driver(name: "John Doe (Uber)", licensePlate: "ABC123", rating: 4.9, estimatedArrivalTime: 3, phoneNumber: "+1234567890")
            completion(.success(driver))
        }
    }
}

// Simulated Lyft API Manager
struct LyftAPIManager {
    static func findDriver(completion: @escaping (Result<Driver, Error>) -> Void) {
        // Simulate finding a driver from Lyft API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let driver = Driver(name: "Jane Smith (Lyft)", licensePlate: "XYZ987", rating: 4.8, estimatedArrivalTime: 5, phoneNumber: "+1234567890")
            completion(.success(driver))
        }
    }
}

// Simulated Taxi Company API Manager
struct TaxiCompanyAPIManager {
    static func findDriver(completion: @escaping (Result<Driver, Error>) -> Void) {
        // Simulate finding a driver from Taxi Company API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let driver = Driver(name: "Bob Johnson (Taxi)", licensePlate: "123XYZ", rating: 4.7, estimatedArrivalTime: 7, phoneNumber: "+1234567890")
            completion(.success(driver))
        }
    }
}

struct DriverInfoView: View {
    var driver: Driver
    
    var body: some View {
        VStack {
            Text("Your Driver")
                .font(.title)
                .foregroundColor(.black)
                .padding(.bottom, 8)
            
            Text(driver.name)
                .font(.headline)
                .foregroundColor(.black)
            
            Text("License Plate: \(driver.licensePlate)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text("Rating:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text(String(format: "%.1f", driver.rating))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct EstimatedArrivalTimeView: View {
    var estimatedArrivalTime: Int
    
    var body: some View {
        VStack {
            Text("Estimated Arrival Time")
                .font(.title3)
                .foregroundColor(.black)
                .padding(.bottom, 8)
            
            Text("\(estimatedArrivalTime) mins")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

enum RideStatus {
    case findingDriver
    case driverFound
}

// Simulated Driver Model
struct Driver {
    let name: String
    let licensePlate: String
    let rating: Double
    let estimatedArrivalTime: Int
    let phoneNumber: String
}
