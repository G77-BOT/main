import Foundation
import XCTest

final class TestSuite {
    static func runAllTests() {
        // Unit tests
        XCTContext.runActivity(named: "Security Tests") { _ in
            SecurityTests.runAll()
        }
        
        // Integration tests
        XCTContext.runActivity(named: "API Integration") { _ in
            APIIntegrationTests.runAll()
        }
        
        // Performance tests
        XCTContext.runActivity(named: "Performance") { _ in
            PerformanceTests.runAll()

        }
        // Add UI testing scenarios
        XCTContext.runActivity(named: "UI Tests") { _ in
            UITests.runAll()
        }

    
    }

}
