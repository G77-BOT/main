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
                ForEach(0..<hotel.starRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                Text("$\(hotel.pricePerNight)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Add link to open hotel website
            Link("Book now", destination: URL(string: hotel.website)!)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
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
    
    @State private var isBookingInProgress = false
    @State private var isBookingSuccess = false
    
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
                ForEach(0..<hotel.starRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text("Price per night: $\(hotel.pricePerNight)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Spacer()
            
            if !isBookingSuccess {
                Button(action: bookHotel) {
                    Text("Book Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .opacity(isBookingInProgress ? 0.5 : 1.0)
                }
                .disabled(isBookingInProgress)
            } else {
                Text("Booking successful! Check your email for confirmation.")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private func bookHotel() {
        // Simulate booking process with AI logic
        isBookingInProgress = true
        // Placeholder implementation for AI booking logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isBookingInProgress = false
            isBookingSuccess = true
            
            // Send email confirmation
            sendEmailConfirmation()
        }
    }
    
    private func sendEmailConfirmation() {
        // Placeholder implementation for sending email confirmation
        // Integrate with a real email sending service/API
        let hotelDetails = "Name: \(hotel.name)\nLocation: \(hotel.location)\nPrice: $\(hotel.pricePerNight)"
        let emailContent = "Thank you for booking with us!\n\nYour hotel details:\n\(hotelDetails)\n\nWe look forward to welcoming you and hope you enjoy your stay with us. Feel free to contact us for any further assistance or recommendations.\n\nBest Regards,\nThe Hotel Team"
        // Simulate sending email confirmation
        EmailService.sendEmail(to: "user@example.com", subject: "Hotel Booking Confirmation", content: emailContent) { success in
            // Handle email sending result
            if success {
                isPresented = false // Dismiss the view after successful booking
            } else {
                // Handle email sending failure
                print("Failed to send email confirmation")
            }
        }
    }
}

struct Hotel: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let starRating: Int
    let pricePerNight: Int
    let imageName: String
    let website: String // URL for hotel website
    
    static let allHotels: [Hotel] = [
        Hotel(name: "Hotel A", location: "City A", starRating: 4, pricePerNight: 100, imageName: "hotel_a", website: "https://www.hotel-a.com"),
        Hotel(name: "Hotel B", location: "City B", starRating: 5, pricePerNight: 150, imageName: "hotel_b", website: "https://www.hotel-b.com"),
        Hotel(name: "Hotel C", location: "City C", starRating: 3, pricePerNight: 80, imageName: "hotel_c", website: "https://www.hotel-c.com"),
        Hotel(name: "Hotel D", location: "City D", starRating: 4, pricePerNight: 120, imageName: "hotel_d", website: "https://www.hotel-d.com"),
        Hotel(name: "Hotel E", location: "City E", starRating: 5, pricePerNight: 200, imageName: "hotel_e", website: "https://www.hotel-e.com"),
        Hotel(name: "Hotel F", location: "City F", starRating: 3, pricePerNight: 90, imageName: "hotel_f", website: "https://www.hotel-f.com")
    ]
}

struct EmailService {
    static func sendEmail(to recipient: String, subject: String, content: String, completion: @escaping (Bool) -> Void) {
        // Placeholder implementation for sending email
        // Integrate with a real email sending service/API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("Email sent to: \(recipient)\nSubject: \(subject)\nContent: \(content)")
            completion(true) // Simulate success
        }
    }
}
