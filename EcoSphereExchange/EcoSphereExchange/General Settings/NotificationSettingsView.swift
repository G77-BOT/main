//
//  NotificationSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        VStack {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .padding()
            
            Button(action: {
                requestNotificationAuthorization()
                scheduleNotifications()
            }) {
                Text("Send Test Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Notification Settings")
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotifications() {
        // Clear previously scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule notifications for different events
        scheduleBlogNotification()
        scheduleTechnologyArticleNotification()
        scheduleTaxiDiscountNotification()
        scheduleFlightBookingDiscountNotification()
        scheduleSendMoneyDiscountNotification()
        scheduleHotelBookingDiscountNotification()
        scheduleProductNotifications()
        schedulePromotionNotifications()
        // Add more notification types as needed
    }
    
    private func scheduleBlogNotification() {
        let blogContent = UNMutableNotificationContent()
        blogContent.title = "New Blog Available"
        blogContent.body = "Check out our latest blog post!"
        blogContent.sound = UNNotificationSound.default
        
        let blogTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let blogRequest = UNNotificationRequest(identifier: "blogNotification", content: blogContent, trigger: blogTrigger)
        UNUserNotificationCenter.current().add(blogRequest)
    }
    
    private func scheduleTechnologyArticleNotification() {
        let techArticleContent = UNMutableNotificationContent()
        techArticleContent.title = "New Technology Article"
        techArticleContent.body = "Stay updated with our latest technology article!"
        techArticleContent.sound = UNNotificationSound.default
        
        let techArticleTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let techArticleRequest = UNNotificationRequest(identifier: "techArticleNotification", content: techArticleContent, trigger: techArticleTrigger)
        UNUserNotificationCenter.current().add(techArticleRequest)
    }
    
    private func scheduleTaxiDiscountNotification() {
        let discountContent = UNMutableNotificationContent()
        discountContent.title = "Exclusive Taxi Discount"
        discountContent.body = "Unlock 20% off your next ride with code TAXI20. Don't miss out!"
        discountContent.sound = UNNotificationSound.default
        
        // Define the date components for scheduling the notification
        var dateComponents = DateComponents()
        dateComponents.hour = 10 // Schedule at 10 AM
        dateComponents.minute = 0 // Schedule at the start of the hour
        
        // Create a calendar trigger with the defined date components
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create a request with a unique identifier, content, and trigger
        let request = UNNotificationRequest(identifier: "taxiDiscountNotification", content: discountContent, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling taxi discount notification: \(error.localizedDescription)")
            } else {
                print("Taxi discount notification scheduled successfully.")
            }
        }
    }

    }
    
private func scheduleFlightBookingDiscountNotification() {
    let discountContent = UNMutableNotificationContent()
    discountContent.title = "Exclusive Flight Booking Discount"
    discountContent.body = "Unlock 25% off your next flight booking with code FLY25. Limited time offer!"
    discountContent.sound = UNNotificationSound.default
    
    // Define the date components for scheduling the notification
    var dateComponents = DateComponents()
    dateComponents.hour = 9 // Schedule at 9 AM
    dateComponents.minute = 0 // Schedule at the start of the hour
    
    // Create a calendar trigger with the defined date components
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    
    // Create a request with a unique identifier, content, and trigger
    let request = UNNotificationRequest(identifier: "flightBookingDiscountNotification", content: discountContent, trigger: trigger)
    
    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling flight booking discount notification: \(error.localizedDescription)")
        } else {
            print("Flight booking discount notification scheduled successfully.")
        }
    }
}
    
private func scheduleSendMoneyDiscountNotification() {
    let discountContent = UNMutableNotificationContent()
    discountContent.title = "Send Money Discount"
    discountContent.body = "Get 50% off on your next money transfer. Limited time offer!"
    discountContent.sound = UNNotificationSound.default
    
    // Define the date components for scheduling the notification
    var dateComponents = DateComponents()
    dateComponents.hour = 12 // Schedule at 12 PM
    dateComponents.minute = 0 // Schedule at the start of the hour
    
    // Create a calendar trigger with the defined date components
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    
    // Create a request with a unique identifier, content, and trigger
    let request = UNNotificationRequest(identifier: "sendMoneyDiscountNotification", content: discountContent, trigger: trigger)
    
    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling send money discount notification: \(error.localizedDescription)")
        } else {
            print("Send money discount notification scheduled successfully.")
        }
    }
}

    
    
private func scheduleHotelBookingDiscountNotification() {
    // Define the notification content
    let discountContent = UNMutableNotificationContent()
    discountContent.title = "Hotel Booking Discount"
    discountContent.body = "Unlock exclusive discounts on hotel bookings. Book now and save!"
    discountContent.sound = UNNotificationSound.default
    
    // Define the trigger for scheduling the notification
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // Schedule the notification 3 Hour from now
    
    // Create a request with a unique identifier, content, and trigger
    let request = UNNotificationRequest(identifier: "hotelBookingDiscountNotification", content: discountContent, trigger: trigger)
    
    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling hotel booking discount notification: \(error.localizedDescription)")
        } else {
            print("Hotel booking discount notification scheduled successfully.")
        }
    }
}

    
private func scheduleProductNotifications() {
    // Define the notification content
    let productContent = UNMutableNotificationContent()
    productContent.title = "New Product Available"
    productContent.body = "Discover our latest arrivals and exclusive offers. Don't miss out!"
    productContent.sound = UNNotificationSound.default
    
    // Define the trigger for scheduling the notification
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // Schedule the notification 6 Hour from now
    
    // Create a request with a unique identifier, content, and trigger
    let request = UNNotificationRequest(identifier: "productNotification", content: productContent, trigger: trigger)
    
    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling product notification: \(error.localizedDescription)")
        } else {
            print("Product notification scheduled successfully.")
        }
    }
}
    
private func schedulePromotionNotifications() {
    // Define the notification content
    let promotionContent = UNMutableNotificationContent()
    promotionContent.title = "Exclusive Promotion Alert"
    promotionContent.body = "Hurry! Limited-time offer: Get up to 50% off on selected items. Shop now!"
    promotionContent.sound = UNNotificationSound.default
    
    // Define the trigger for scheduling the notification
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // Schedule the notification 7 Hour from now
    
    // Create a request with a unique identifier, content, and trigger
    let request = UNNotificationRequest(identifier: "promotionNotification", content: promotionContent, trigger: trigger)
    
    // Add the request to the notification center
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling promotion notification: \(error.localizedDescription)")
        } else {
            print("Promotion notification scheduled successfully.")
        }
    }
}
