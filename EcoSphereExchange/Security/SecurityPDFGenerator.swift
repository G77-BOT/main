import UIKit
import PDFKit

final class SecurityPDFGenerator {
    private let details: SecurityReportDetails
    private let pdfMetadata: [String: Any]
    
    init(details: SecurityReportDetails) {
        self.details = details
        self.pdfMetadata = [
            kCGPDFContextCreator as String: "EcoSphere Security",
            kCGPDFContextAuthor as String: "Security System",
            kCGPDFContextTitle as String: "Security Report",
            kCGPDFContextSubject as String: "Device Security Analysis"
        ]
    }
    
    func generateReport() -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, pdfMetadata)
        
        generateCoverPage()
        generateExecutiveSummary()
        generateVulnerabilityAnalysis()
        generateAnomalyReport()
        generateRecommendations()
        generateRequiredActions()
        generateTechnicalDetails()
        
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
    
    private func generateCoverPage() {
        UIGraphicsBeginPDFPage()
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        
        let title = "Security Analysis Report"
        let dateString = DateFormatter.localizedString(from: details.timestamp, dateStyle: .full, timeStyle: .medium)
        
        drawText(title, at: CGPoint(x: 50, y: 100), attributes: titleAttributes)
        drawText("Generated: \(dateString)", at: CGPoint(x: 50, y: 150))
        drawText("Risk Level: \(details.report.riskLevel.rawValue.uppercased())", at: CGPoint(x: 50, y: 200))
    }
    
    private func generateExecutiveSummary() {
        UIGraphicsBeginPDFPage()
        let summary = """
        Security Score: \(details.report.securityScore)/100
        Risk Level: \(details.report.riskLevel.rawValue)
        Vulnerabilities Found: \(details.threatAnalysis.vulnerabilities.count)
        Anomalies Detected: \(details.threatAnalysis.anomalies.count)
        """
        
        drawSectionTitle("Executive Summary", at: CGPoint(x: 50, y: 50))
        drawText(summary, at: CGPoint(x: 50, y: 100))
    }
    
    private func generateVulnerabilityAnalysis() {
        UIGraphicsBeginPDFPage()
        drawSectionTitle("Vulnerability Analysis", at: CGPoint(x: 50, y: 50))
        
        var yPosition = 100
        for vulnerability in details.threatAnalysis.vulnerabilities {
            let vulnerabilityText = """
            Type: \(vulnerability.type.rawValue)
            Severity: \(vulnerability.severity.rawValue)
            Description: \(vulnerability.description)
            Mitigation: \(vulnerability.mitigation)
            """
            
            drawText(vulnerabilityText, at: CGPoint(x: 50, y: yPosition))
            yPosition += 120
            
            if yPosition > 700 {
                UIGraphicsBeginPDFPage()
                yPosition = 50
            }
        }
    }
    
    private func generateAnomalyReport() {
        UIGraphicsBeginPDFPage()
        drawSectionTitle("Anomaly Detection Report", at: CGPoint(x: 50, y: 50))
        
        var yPosition = 100
        for anomaly in details.threatAnalysis.anomalies {
            let anomalyText = """
            Type: \(anomaly.type.rawValue)
            Confidence: \(String(format: "%.2f", anomaly.confidence))
            Details: \(anomaly.details)
            Detected: \(DateFormatter.localizedString(from: anomaly.detectionTime, dateStyle: .medium, timeStyle: .short))
            """
            
            drawText(anomalyText, at: CGPoint(x: 50, y: yPosition))
            yPosition += 120
        }
    }
    
    private func generateRecommendations() {
        UIGraphicsBeginPDFPage()
        drawSectionTitle("Security Recommendations", at: CGPoint(x: 50, y: 50))
        
        var yPosition = 100
        for (index, recommendation) in details.recommendations.enumerated() {
            drawText("\(index + 1). \(recommendation)", at: CGPoint(x: 50, y: yPosition))
            yPosition += 30
        }
    }
    
    private func generateRequiredActions() {
        if !details.requiredActions.isEmpty {
            UIGraphicsBeginPDFPage()
            drawSectionTitle("Required Actions", at: CGPoint(x: 50, y: 50))
            
            var yPosition = 100
            for (index, action) in details.requiredActions.enumerated() {
                drawText("\(index + 1). \(action)", at: CGPoint(x: 50, y: yPosition))
                yPosition += 30
            }
        }
    }
    
    private func generateTechnicalDetails() {
        UIGraphicsBeginPDFPage()
        drawSectionTitle("Technical Details", at: CGPoint(x: 50, y: 50))
        
        let technicalInfo = """
        Device Model: \(details.report.deviceModel)
        System Version: \(details.report.systemVersion)
        Security Features:
        \(details.report.securityFeatures.map { "- \($0.key): \($0.value)" }.joined(separator: "\n"))
        """
        
        drawText(technicalInfo, at: CGPoint(x: 50, y: 100))
    }
    
    private func drawSectionTitle(_ title: String, at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        drawText(title, at: point, attributes: attributes)
    }
    
    private func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any]? = nil) {
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let finalAttributes = attributes ?? defaultAttributes
        (text as NSString).draw(at: point, withAttributes: finalAttributes)
    }
}
