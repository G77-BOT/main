//
//  CallTaxiView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//


import SwiftUI
import MapKit
import CoreLocation

struct TaxiAppView: View {
    @Binding var isPresented: Bool
    @State private var pickupLocation: CLLocationCoordinate2D?
    @State private var dropOffLocation: CLLocationCoordinate2D?
    @State private var selectedVehicleType: VehicleType = .standard
    @State private var isBookingInProgress: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                MapView(pickupLocation: $pickupLocation, dropOffLocation: $dropOffLocation)
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: 300)

                VehicleTypePicker(selectedVehicleType: $selectedVehicleType)
                    .padding()

                EstimatedFareView(selectedVehicleType: selectedVehicleType)
                    .padding()

                BookRideButton(isBookingInProgress: $isBookingInProgress, onBookRide: bookRide)
                    .padding()

                Spacer()
            }
            .navigationTitle("Taxi App")
        }
    }

    private func bookRide() {
        // Implement booking logic
    }
}

struct MapView: View {
    @Binding var pickupLocation: CLLocationCoordinate2D?
    @Binding var dropOffLocation: CLLocationCoordinate2D?

    var body: some View {
        let annotations = getAnnotations()
        Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: .constant(.follow), annotationItems: annotations) { annotation in
            MapPin(coordinate: annotation.coordinate, tint: annotation.tint)
        }
        .gesture(
            DragGesture().onEnded { gesture in
                let location = gesture.location
                let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

                if pickupLocation == nil {
                    pickupLocation = coordinate
                } else if dropOffLocation == nil {
                    dropOffLocation = coordinate
                } else {
                    pickupLocation = coordinate
                    dropOffLocation = nil
                }
            }
        )
    }

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let mapView = MKMapView()

    private func getAnnotations() -> [Annotation] {
        var annotations: [Annotation] = []

        if let pickupLocation = pickupLocation {
            annotations.append(Annotation(coordinate: pickupLocation, tint: .green))
        }

        if let dropOffLocation = dropOffLocation {
            annotations.append(Annotation(coordinate: dropOffLocation, tint: .red))
        }

        return annotations
    }

    struct Annotation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let tint: Color
    }
}

struct VehicleTypePicker: View {
    @Binding var selectedVehicleType: VehicleType

    var body: some View {
        Picker("Select Vehicle Type", selection: $selectedVehicleType) {
            ForEach(VehicleType.allCases, id: \.self) { vehicleType in
                Text(vehicleType.rawValue.capitalized)
                    .tag(vehicleType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct EstimatedFareView: View {
    var selectedVehicleType: VehicleType

    var body: some View {
        VStack {
            Text("Estimated Fare")
                .font(.headline)

            Text("\(selectedVehicleType.rawValue.capitalized) - $\(selectedVehicleType.estimatedFare, specifier: "%.2f")")
                .font(.title)
                .foregroundColor(.blue)
        }
    }
}

struct BookRideButton: View {
    @Binding var isBookingInProgress: Bool
    var onBookRide: () -> Void

    var body: some View {
        Button(action: onBookRide) {
            if isBookingInProgress {
                ProgressView()
                    .padding()
            } else {
                Text("Book Ride")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

enum VehicleType: String, CaseIterable {
    case standard
    case premium

    var estimatedFare: Double {
        switch self {
        case .standard:
            return 25.0
        case .premium:
            return 40.0
        }
    }
}
