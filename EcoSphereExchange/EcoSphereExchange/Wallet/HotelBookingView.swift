//
//  HotelBookingView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-07.
//

import SwiftUI

struct HotelBookingView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Discover Hotels")
                    .font(.title)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Hotel.allHotels) { hotel in
                            NavigationLink(destination: HotelDetailView(hotel: hotel, isPresented: $isPresented)) {
                                HotelCardView(hotel: hotel)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Hotels")
        }
    }
}

struct HotelCardView: View {
    let hotel: Hotel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(hotel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .cornerRadius(10)
            
            Text(hotel.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(hotel.location)
                .foregroundColor(.gray)
            
            HStack {
                ForEach(0..<hotel.starRating) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                Text("$\(hotel.pricePerNight)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct HotelDetailView: View {
    let hotel: Hotel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(hotel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
            Text(hotel.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(hotel.location)
                .foregroundColor(.gray)
            
            HStack {
                ForEach(0..<hotel.starRating) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text("Price per night: $\(hotel.pricePerNight)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Spacer()
            
            Button(action: {
                // Implement hotel booking functionality here
                isPresented = false
            }) {
                Text("Book Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct Hotel: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let starRating: Int
    let pricePerNight: Int
    let imageName: String
    
    static let allHotels: [Hotel] = [
        Hotel(name: "Hotel A", location: "City A", starRating: 4, pricePerNight: 100, imageName: "hotel_a"),
        Hotel(name: "Hotel B", location: "City B", starRating: 5, pricePerNight: 150, imageName: "hotel_b"),
        Hotel(name: "Hotel C", location: "City C", starRating: 3, pricePerNight: 80, imageName: "hotel_c"),
        Hotel(name: "Hotel D", location: "City D", starRating: 4, pricePerNight: 120, imageName: "hotel_d"),
        Hotel(name: "Hotel E", location: "City E", starRating: 5, pricePerNight: 200, imageName: "hotel_e"),
        Hotel(name: "Hotel F", location: "City F", starRating: 3, pricePerNight: 90, imageName: "hotel_f")
    ]
}
