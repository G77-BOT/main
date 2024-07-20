//
//  FirebaseApp.swift
//  EcoSphereExchange
//
//  Created by mahmmud abdolaziz on 2024-04-20.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

@main
struct EcoSphereExchangeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
                .environmentObject(CartManager())
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

class AuthViewModel: ObservableObject {
    @Published var user: User?
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                // Send verification email
                user.sendEmailVerification { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Store user profile data
                        self.storeUserProfile(user: user, completion: completion)
                    }
                }
            }
        }
    }

    private func storeUserProfile(user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let userProfile = [
            "uid": user.uid,
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ] as [String : Any]

        Firestore.firestore().collection("users").document(user.uid).setData(userProfile) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(user))
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                if user.isEmailVerified {
                    completion(.success(user))
                } else {
                    // Handle email verification
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Email not verified"])))
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

class FirestoreManager {
    private let db = Firestore.firestore()

    func fetchProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        db.collection("products").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let products = snapshot?.documents.compactMap { document -> Product? in
                    try? document.data(as: Product.self)
                } ?? []
                completion(.success(products))
            }
        }
    }

    func addOrder(order: Order, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("orders").addDocument(from: order)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func addBillingInfo(userId: String, billingInfo: BillingInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("users").document(userId).collection("billing").addDocument(from: billingInfo)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var price: Double
    var description: String
    var imageUrl: String
}

struct Order: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var products: [Product]
    var totalAmount: Double
    var date: Date
}

struct BillingInfo: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var cardNumber: String
    var expiryDate: String
    var cvv: String
}

class CartManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var paymentSuccess: Bool = false

    var total: Double {
        products.reduce(0) { $0 + $1.price }
    }

    func addProduct(_ product: Product) {
        products.append(product)
    }

    func removeProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
    }

    func pay(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Implement payment logic here, e.g., Stripe integration

        let order = Order(userId: userId, products: products, totalAmount: total, date: Date())
        FirestoreManager().addOrder(order: order) { result in
            switch result {
            case .success:
                self.paymentSuccess = true
                completion(.success(()))
            case .failure(let error):
                self.paymentSuccess = false
                completion(.failure(error))
            }
        }
    }
}
