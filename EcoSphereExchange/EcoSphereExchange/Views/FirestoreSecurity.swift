service cloud.firestore {
  match /databases/{database}/documents {
    
    // User data security rules
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Nested match for user-specific subcollections
      match /billing/{billingId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Product data security rules
    match /products/{productId} {
      allow read: if request.auth != null; // Allow authenticated users to read products
      allow write: if request.auth != null && request.auth.token.admin == true; // Only admins can write
    }
    
    // Order data security rules
    match /orders/{orderId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Reviews data security rules
    match /products/{productId}/reviews/{reviewId} {
      allow read: if request.auth != null; // Allow authenticated users to read reviews
      allow write: if request.auth != null && request.auth.uid == request.resource.data.userId; // Users can write their own reviews
    }
    
    // Admin-specific data security rules
    match /admin/{document=**} {
      allow read, write: if request.auth != null && request.auth.token.admin == true; // Only admins can read/write
    }
  }
}
