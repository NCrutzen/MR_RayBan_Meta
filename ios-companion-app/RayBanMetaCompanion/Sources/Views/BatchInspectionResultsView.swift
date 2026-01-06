import SwiftUI
import UIKit
import PDFKit

struct BatchInspectionResultsView: View {
    let results: [InspectionResult]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResultIndex = 0
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Summary Card
                        batchSummaryCard

                        // Results Navigator
                        if results.count > 1 {
                            resultsNavigator
                        }

                        // Current Result Detail
                        if let currentResult = currentResult {
                            resultDetailSection(currentResult)
                        }

                        // Share Section
                        shareSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                TopBlurOverlay()
            }
            .navigationTitle("Batch Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: sharePDFReport) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: generateShareItems())
        }
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Report")
                .font(.headline)
                .foregroundStyle(.white)

            Button(action: sharePDFReport) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.richtext")
                    Text("Share PDF Report")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MoyneRoberts.accent)
                )
            }

            Text("Share a complete PDF report with all \(results.count) photos and details")
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary)
        }
    }

    // MARK: - Share Items Generation

    private func generateShareItems() -> [Any] {
        if let url = pdfURL {
            return [url]
        }
        return []
    }

    private func sharePDFReport() {
        pdfURL = generateBatchPDFReport()
        showingShareSheet = true
    }

    private var currentResult: InspectionResult? {
        guard selectedResultIndex < results.count else { return nil }
        return results[selectedResultIndex]
    }

    // MARK: - PDF Generation

    private func generateBatchPDFReport() -> URL? {
        let pageWidth: CGFloat = 595.2  // A4 width in points
        let pageHeight: CGFloat = 841.8 // A4 height in points
        let margin: CGFloat = 40

        let pdfMetaData = [
            kCGPDFContextCreator: "MR Smart Glasses - Smeba Fire Safety",
            kCGPDFContextAuthor: "Smeba Fire Safety / Moyne Roberts",
            kCGPDFContextTitle: "Batch Fire Hazard Inspection Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let data = renderer.pdfData { context in
            // First page - Summary
            context.beginPage()

            var yOffset: CGFloat = margin

            // Header with branding
            let headerColor = UIColor(red: 0.1, green: 0.15, blue: 0.27, alpha: 1.0)
            headerColor.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: 80))

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.white
            ]
            "BATCH FIRE HAZARD INSPECTION REPORT".draw(at: CGPoint(x: margin, y: 25), withAttributes: titleAttrs)

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            "Smeba Fire Safety | Moyne Roberts".draw(at: CGPoint(x: margin, y: 52), withAttributes: subtitleAttrs)

            yOffset = 100

            // Summary stats
            let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            "INSPECTION SUMMARY".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
            yOffset += 25

            let statsAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]

            "Date: \(formattedDate)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttrs)
            yOffset += 18
            "Photos Analyzed: \(results.count)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttrs)
            yOffset += 18

            let riskColor = riskUIColor(for: overallBatchRisk)
            let riskAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: riskColor
            ]
            "Overall Risk Level: \(overallBatchRisk.displayName)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: riskAttrs)
            yOffset += 18

            "Total Hazards Found: \(totalHazards)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttrs)
            yOffset += 18
            "Critical/High Severity: \(criticalCount)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: statsAttrs)
            yOffset += 40

            // Photo thumbnails overview
            "PHOTOS OVERVIEW".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
            yOffset += 25

            let thumbSize: CGFloat = 80
            let thumbSpacing: CGFloat = 10
            let _ = Int((pageWidth - margin * 2 + thumbSpacing) / (thumbSize + thumbSpacing))
            var thumbX = margin
            var thumbY = yOffset

            for (index, result) in results.enumerated() {
                if thumbX + thumbSize > pageWidth - margin {
                    thumbX = margin
                    thumbY += thumbSize + thumbSpacing + 20
                }

                // Check for new page
                if thumbY + thumbSize > pageHeight - 100 {
                    context.beginPage()
                    thumbY = margin
                    thumbX = margin
                }

                // Draw thumbnail
                result.image.draw(in: CGRect(x: thumbX, y: thumbY, width: thumbSize, height: thumbSize))

                // Draw risk indicator
                let indicatorColor = riskUIColor(for: result.overallRisk)
                indicatorColor.setFill()
                context.cgContext.fillEllipse(in: CGRect(x: thumbX + thumbSize - 15, y: thumbY, width: 15, height: 15))

                // Photo number
                let numAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 9),
                    .foregroundColor: UIColor.darkGray
                ]
                "#\(index + 1)".draw(at: CGPoint(x: thumbX, y: thumbY + thumbSize + 2), withAttributes: numAttrs)

                thumbX += thumbSize + thumbSpacing
            }

            // Individual photo pages
            for (index, result) in results.enumerated() {
                context.beginPage()
                yOffset = margin

                // Photo header
                headerColor.setFill()
                context.cgContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: 60))

                let photoTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.white
                ]
                "PHOTO \(index + 1) OF \(results.count)".draw(at: CGPoint(x: margin, y: 20), withAttributes: photoTitleAttrs)

                let photoRiskColor = riskUIColor(for: result.overallRisk)
                let photoRiskAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: photoRiskColor
                ]
                "\(result.overallRisk.displayName) Risk".draw(at: CGPoint(x: pageWidth - margin - 100, y: 22), withAttributes: photoRiskAttrs)

                yOffset = 80

                // Image
                let imageMaxWidth = pageWidth - (margin * 2)
                let imageMaxHeight: CGFloat = 200
                let imageAspect = result.image.size.width / result.image.size.height
                var imageWidth = imageMaxWidth
                var imageHeight = imageWidth / imageAspect
                if imageHeight > imageMaxHeight {
                    imageHeight = imageMaxHeight
                    imageWidth = imageHeight * imageAspect
                }
                let imageX = (pageWidth - imageWidth) / 2
                result.image.draw(in: CGRect(x: imageX, y: yOffset, width: imageWidth, height: imageHeight))

                yOffset += imageHeight + 20

                // Summary
                "SUMMARY".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
                yOffset += 18

                let summaryAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray
                ]
                let summaryRect = CGRect(x: margin, y: yOffset, width: pageWidth - (margin * 2), height: 50)
                (result.summary as NSString).draw(in: summaryRect, withAttributes: summaryAttrs)
                yOffset += 45

                // Hazards
                if !result.hazards.isEmpty {
                    "IDENTIFIED HAZARDS".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
                    yOffset += 20

                    for hazard in result.hazards {
                        if yOffset > pageHeight - 120 {
                            context.beginPage()
                            yOffset = margin
                        }

                        let severityColor = riskUIColor(for: hazard.severity)

                        let hazardTitleAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 11),
                            .foregroundColor: UIColor.black
                        ]
                        "• \(hazard.type)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: hazardTitleAttrs)

                        let severityAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 10),
                            .foregroundColor: severityColor
                        ]
                        "[\(hazard.severity.displayName)]".draw(at: CGPoint(x: margin + 180, y: yOffset), withAttributes: severityAttrs)
                        yOffset += 15

                        let descAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor.darkGray
                        ]
                        let descRect = CGRect(x: margin + 15, y: yOffset, width: pageWidth - (margin * 2) - 15, height: 28)
                        (hazard.description as NSString).draw(in: descRect, withAttributes: descAttrs)
                        yOffset += 26

                        let recAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.italicSystemFont(ofSize: 10),
                            .foregroundColor: UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
                        ]
                        let recRect = CGRect(x: margin + 15, y: yOffset, width: pageWidth - (margin * 2) - 15, height: 28)
                        ("→ \(hazard.recommendation)" as NSString).draw(in: recRect, withAttributes: recAttrs)
                        yOffset += 32
                    }
                }

                // Safety Compliance
                if yOffset > pageHeight - 150 {
                    context.beginPage()
                    yOffset = margin
                }

                yOffset += 10
                "SAFETY COMPLIANCE".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
                yOffset += 18

                for item in result.safetyCompliance.complianceItems {
                    let statusSymbol: String
                    let statusColor: UIColor
                    if let status = item.status {
                        let isPassed = item.isPositive ? status : !status
                        statusSymbol = isPassed ? "✓" : "✗"
                        statusColor = isPassed ? UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) : UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
                    } else {
                        statusSymbol = "—"
                        statusColor = UIColor.gray
                    }

                    let itemAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.darkGray
                    ]
                    item.name.draw(at: CGPoint(x: margin + 15, y: yOffset), withAttributes: itemAttrs)

                    let statusAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 11),
                        .foregroundColor: statusColor
                    ]
                    statusSymbol.draw(at: CGPoint(x: pageWidth - margin - 25, y: yOffset), withAttributes: statusAttrs)

                    yOffset += 16
                }

                // Footer on each page
                let footerY = pageHeight - 35
                UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).setFill()
                context.cgContext.fill(CGRect(x: 0, y: footerY, width: pageWidth, height: 35))

                let footerStyle = NSMutableParagraphStyle()
                footerStyle.alignment = .center
                let footerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.gray,
                    .paragraphStyle: footerStyle
                ]
                let footerText = "MR Smart Glasses App • www.smeba.nl | www.moyneroberts.ie • Page \(index + 2) of \(results.count + 1)"
                (footerText as NSString).draw(in: CGRect(x: margin, y: footerY + 12, width: pageWidth - (margin * 2), height: 18), withAttributes: footerAttrs)
            }
        }

        // Save to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "BatchFireHazardReport_\(Date().timeIntervalSince1970).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    private func riskUIColor(for risk: RiskLevel) -> UIColor {
        switch risk {
        case .critical:
            return UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        case .high:
            return UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
        case .medium:
            return UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
        case .low:
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }

    private func riskUIColor(for severity: HazardSeverity) -> UIColor {
        switch severity {
        case .critical:
            return UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        case .high:
            return UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
        case .medium:
            return UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
        case .low:
            return UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }

    // MARK: - Batch Summary Card

    private var batchSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Overall risk indicator
                ZStack {
                    Circle()
                        .fill(Color(hex: overallBatchRisk.color).opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: overallBatchRisk.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: overallBatchRisk.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Batch Inspection Complete")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text("\(results.count) photos analyzed")
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                }

                Spacer()
            }

            Divider()

            // Statistics
            HStack(spacing: 0) {
                BatchStatItem(
                    value: "\(totalHazards)",
                    label: "Total Hazards",
                    color: totalHazards > 0 ? MoyneRoberts.warning : MoyneRoberts.success
                )

                Divider()
                    .frame(height: 40)

                BatchStatItem(
                    value: "\(criticalCount)",
                    label: "Critical/High",
                    color: criticalCount > 0 ? MoyneRoberts.error : MoyneRoberts.success
                )

                Divider()
                    .frame(height: 40)

                BatchStatItem(
                    value: overallBatchRisk.displayName,
                    label: "Risk Level",
                    color: Color(hex: overallBatchRisk.color)
                )
            }
        }
        .cleanCard(cornerRadius: 20, padding: 16)
    }

    // MARK: - Results Navigator

    private var resultsNavigator: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos (\(selectedResultIndex + 1)/\(results.count))")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        Button(action: { selectedResultIndex = index }) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: result.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(10)
                                    .clipped()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                index == selectedResultIndex ? MoyneRoberts.accent : Color.clear,
                                                lineWidth: 3
                                            )
                                    )

                                // Risk indicator badge
                                Circle()
                                    .fill(Color(hex: result.overallRisk.color))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text("\(result.hazardCount)")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Result Detail Section

    private func resultDetailSection(_ result: InspectionResult) -> some View {
        VStack(spacing: 16) {
            // Image Preview
            Image(uiImage: result.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 180)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            // Risk Level
            HStack(spacing: 12) {
                Image(systemName: result.overallRisk.iconName)
                    .font(.title2)
                    .foregroundStyle(Color(hex: result.overallRisk.color))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(result.overallRisk.displayName) Risk")
                        .font(.headline)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text("\(result.hazardCount) hazard(s) identified")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                }

                Spacer()
            }
            .cleanCard(cornerRadius: 12, padding: 12)

            // Summary
            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cleanCard(cornerRadius: 12, padding: 12)

            // Hazards
            if !result.hazards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hazards")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach(result.hazards) { hazard in
                        CompactHazardRow(hazard: hazard)
                    }
                }
            }

            // Compliance
            CompactComplianceCard(compliance: result.safetyCompliance)
        }
    }

    // MARK: - Computed Properties

    private var totalHazards: Int {
        results.reduce(0) { $0 + $1.hazardCount }
    }

    private var criticalCount: Int {
        results.reduce(0) { $0 + $1.criticalHazardCount }
    }

    private var overallBatchRisk: RiskLevel {
        if results.contains(where: { $0.overallRisk == .critical }) {
            return .critical
        } else if results.contains(where: { $0.overallRisk == .high }) {
            return .high
        } else if results.contains(where: { $0.overallRisk == .medium }) {
            return .medium
        } else {
            return .low
        }
    }

    // MARK: - Report Generation

    private func generateBatchReport() -> String {
        var report = """
        BATCH FIRE HAZARD INSPECTION REPORT
        Generated by MR Smart Glasses
        Smeba Fire Safety / Moyne Roberts

        Date: \(formattedDate)
        Photos Analyzed: \(results.count)
        Overall Risk Level: \(overallBatchRisk.displayName)
        Total Hazards Found: \(totalHazards)
        Critical/High Severity: \(criticalCount)

        """

        for (index, result) in results.enumerated() {
            report += """

            ========================================
            PHOTO \(index + 1) OF \(results.count)
            ========================================
            Risk Level: \(result.overallRisk.displayName)
            Hazards: \(result.hazardCount)

            Summary: \(result.summary)

            """

            if !result.hazards.isEmpty {
                report += "\nIdentified Hazards:\n"
                for (hIndex, hazard) in result.hazards.enumerated() {
                    report += """
                    \(hIndex + 1). \(hazard.type) [\(hazard.severity.displayName)]
                       \(hazard.description)
                       Recommendation: \(hazard.recommendation)

                    """
                }
            }

            if !result.recommendations.isEmpty {
                report += "\nRecommendations:\n"
                for rec in result.recommendations {
                    report += "• \(rec)\n"
                }
            }
        }

        report += """

        ========================================
        END OF REPORT
        ========================================
        Analysis performed using Claude AI
        Report generated by MR Smart Glasses App
        www.moyneroberts.ie | www.smeba.nl
        """

        return report
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Batch Stat Item

struct BatchStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(MoyneRoberts.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Hazard Row

struct CompactHazardRow: View {
    let hazard: FireHazard

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: hazard.severity.color))
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(hazard.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MoyneRoberts.primary)

                Text(hazard.description)
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(hazard.severity.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color(hex: hazard.severity.color))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(hex: hazard.severity.color).opacity(0.15))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Compact Compliance Card

struct CompactComplianceCard: View {
    let compliance: SafetyCompliance

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety Compliance")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                ForEach(compliance.complianceItems, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(MoyneRoberts.primary)

                        Spacer()

                        if let status = item.status {
                            let isPassed = item.isPositive ? status : !status
                            Image(systemName: isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(isPassed ? MoyneRoberts.success : MoyneRoberts.error)
                        } else {
                            Text("N/A")
                                .font(.caption2)
                                .foregroundStyle(MoyneRoberts.secondary.opacity(0.6))
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
    }
}

#Preview {
    BatchInspectionResultsView(results: [
        InspectionResult(
            id: UUID(),
            timestamp: Date(),
            image: UIImage(systemName: "photo")!,
            overallRisk: .medium,
            hazards: [
                FireHazard(
                    type: "Blocked Exit",
                    description: "Storage boxes blocking emergency exit",
                    severity: .high,
                    recommendation: "Remove obstructions immediately"
                )
            ],
            safetyCompliance: SafetyCompliance(
                fireExtinguisherVisible: true,
                exitSignsVisible: false
            ),
            summary: "Moderate risk detected with blocked exit.",
            recommendations: ["Clear exit pathway"],
            source: .claudeAI
        ),
        InspectionResult(
            id: UUID(),
            timestamp: Date(),
            image: UIImage(systemName: "photo.fill")!,
            overallRisk: .low,
            hazards: [],
            safetyCompliance: SafetyCompliance(
                fireExtinguisherVisible: true,
                exitSignsVisible: true,
                clearEgressPath: true
            ),
            summary: "Area appears safe with proper fire safety measures.",
            recommendations: [],
            source: .claudeAI
        )
    ])
}
