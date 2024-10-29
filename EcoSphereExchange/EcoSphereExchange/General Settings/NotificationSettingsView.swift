//
//  NotificationSettingsView.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-08.
//

import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var notificationPreferences: [String: Bool] {
        didSet {
            UserDefaults.standard.set(notificationPreferences, forKey: "notificationPreferences")
        }
    }
    
    @Published var notificationTimes: [String: Date] {
        didSet {
            let encodedData = try? JSONEncoder().encode(notificationTimes)
            UserDefaults.standard.set(encodedData, forKey: "notificationTimes")
        }
    }
    
    @Published var feedbackMessage: String?
    @Published var showAlert: Bool = false
    @Published var error: Error?
    
    // Initialize preferences and times from UserDefaults, if available
    init() {
        self.notificationPreferences = UserDefaults.standard.object(forKey: "notificationPreferences") as? [String: Bool] ?? [
            "promotions": true,
            "productUpdates": true,
            "flightDiscounts": true,
            "taxiDiscounts": true,
            "blogUpdates": true
        ]
        
        if let savedTimesData = UserDefaults.standard.data(forKey: "notificationTimes"),
           let decodedTimes = try? JSONDecoder().decode([String: Date].self, from: savedTimesData) {
            self.notificationTimes = decodedTimes
        } else {
            self.notificationTimes = [
                "productUpdates": Date(),
                "flightDiscounts": Date(),
                "taxiDiscounts": Date()
            ]
        }
        
        requestNotificationAuthorization()
    }
    
    // Request Notification Permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.updateNotificationSettings(isEnabled: granted)
            }
        }
    }
    
    // Schedule a notification for a specific type
    func scheduleNotification(for type: String) {
        guard notificationPreferences.keys.contains(type) else {
            feedbackMessage = "Invalid notification type: \(type)"
            showAlert = true
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = getNotificationTitle(for: type)
        content.body = getNotificationBody(for: type)
        content.sound = UNNotificationSound(named: UNNotificationSoundName(UserDefaults.standard.string(forKey: "notificationSound") ?? "default"))
        
        let trigger = getNotificationTrigger(for: type)
        
        let request = UNNotificationRequest(identifier: type, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    self.feedbackMessage = "Error scheduling \(type) notification."
                } else {
                    self.feedbackMessage = "\(type.capitalized) notification scheduled successfully."
                }
                self.showAlert = true
            }
        }
    }
    
    // Remove notification for a specific type
    func removeNotification(for type: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type])
        DispatchQueue.main.async {
            self.feedbackMessage = "\(type.capitalized) notification removed."
            self.showAlert = true
        }
    }
    
    // Localized titles based on notification type
    private func getNotificationTitle(for type: String) -> String {
        switch type {
        case "promotions":
            return NSLocalizedString("PROMO_TITLE", comment: "")
        case "productUpdates":
            return NSLocalizedString("PRODUCT_UPDATE_TITLE", comment: "")
        case "flightDiscounts":
            return NSLocalizedString("FLIGHT_DISCOUNT_TITLE", comment: "")
        case "taxiDiscounts":
            return NSLocalizedString("TAXI_DISCOUNT_TITLE", comment: "")
        case "blogUpdates":
            return NSLocalizedString("BLOG_UPDATE_TITLE", comment: "")
        default:
            return NSLocalizedString("NOTIFICATION_TITLE", comment: "")
        }
    }
    
    // Localized bodies based on notification type
    private func getNotificationBody(for type: String) -> String {
        switch type {
        case "promotions":
            return NSLocalizedString("PROMO_BODY", comment: "")
        case "productUpdates":
            return NSLocalizedString("PRODUCT_UPDATE_BODY", comment: "")
        case "flightDiscounts":
            return NSLocalizedString("FLIGHT_DISCOUNT_BODY", comment: "")
        case "taxiDiscounts":
            return NSLocalizedString("TAXI_DISCOUNT_BODY", comment: "")
        case "blogUpdates":
            return NSLocalizedString("BLOG_UPDATE_BODY", comment: "")
        default:
            return NSLocalizedString("NOTIFICATION_BODY", comment: "")
        }
    }
    
    // Get notification trigger based on type
    private func getNotificationTrigger(for type: String) -> UNNotificationTrigger {
        if let customTime = notificationTimes[type] {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.hour, .minute], from: customTime)
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        } else {
            switch type {
            case "promotions":
                return UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
            case "blogUpdates":
                return UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
            default:
                return UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
            }
        }
    }
}

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var selectedSound: String = UserDefaults.standard.string(forKey: "notificationSound") ?? "default"
    
    let availableSounds = ["default", "chime", "bell", "electronic"]
    
    var body: some View {
        VStack {
            List {
                // Toggle for each notification type
                ForEach(Array(notificationManager.notificationPreferences.keys), id: \.self) { key in
                    Toggle(key.capitalized, isOn: Binding(
                        get: { notificationManager.notificationPreferences[key] ?? false },
                        set: { newValue in
                            notificationManager.notificationPreferences[key] = newValue
                            if newValue {
                                notificationManager.scheduleNotification(for: key)
                            } else {
                                notificationManager.removeNotification(for: key)
                            }
                        }
                    ))
                    
                    // TimePicker for specific notification types
                    if key == "productUpdates" || key == "flightDiscounts" || key == "taxiDiscounts" {
                        DatePicker(
                            "Notification Time",
                            selection: Binding(
                                get: { notificationManager.notificationTimes[key] ?? Date() },
                                set: { newValue in notificationManager.notificationTimes[key] = newValue }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                    }
                }
                
                // Notification sound selection
                Section(header: Text("Notification Sound")) {
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound.capitalized)
                        }
                    }
                    .onChange(of: selectedSound) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "notificationSound")
                    }
                }
            }
            
            // Alert for feedback or errors
            .alert(isPresented: $notificationManager.showAlert) {
                Alert(
                    title: Text("Notification Status"),
                    message: Text(notificationManager.feedbackMessage ?? "No message"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationTitle("Notification Settings")
        .alert(item: $notificationManager.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}

// Current issue: Settings lost on app restart
// Solution: Implement UserDefaults persistence
func saveNotificationPreferences() {
    UserDefaults.standard.set(notificationPreferences, forKey: "userNotificationPreferences")
    UserDefaults.standard.synchronize()
}
