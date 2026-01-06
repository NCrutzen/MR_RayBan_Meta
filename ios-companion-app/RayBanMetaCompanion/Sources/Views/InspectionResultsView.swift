import SwiftUI
import UIKit
import PDFKit

// MARK: - Shareable Item Wrapper

struct ShareableItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct InspectionResultsView: View {
    let result: InspectionResult
    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareableItem?
    @State private var showingCopiedToast = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Image Preview
                        imageSection

                        // Risk Summary
                        riskSummarySection

                        // Safety Compliance
                        safetyComplianceSection

                        // Hazards List
                        if !result.hazards.isEmpty {
                            hazardsSection
                        }

                        // Recommendations
                        if !result.recommendations.isEmpty {
                            recommendationsSection
                        }

                        // Share Actions
                        shareActionsSection

                        // Analysis Info
                        analysisInfoSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                // Copied toast
                if showingCopiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard.fill")
                            Text("Report copied to clipboard")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(MoyneRoberts.success)
                        )
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationTitle("Inspection Report")
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
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    // MARK: - Share Items Generation

    private func sharePDFReport() {
        if let url = generatePDFReport() {
            shareItem = ShareableItem(url: url)
        }
    }

    // MARK: - Share Actions Section

    private var shareActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Report")
                .font(.headline)
                .foregroundStyle(.white)

            // Share PDF Report button
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

            Text("Share a complete PDF report with photo and all details")
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary)
        }
    }

    // MARK: - PDF Generation

    private func generatePDFReport() -> URL? {
        let pageWidth: CGFloat = 595.2  // A4 width in points
        let pageHeight: CGFloat = 841.8 // A4 height in points
        let margin: CGFloat = 40

        let pdfMetaData = [
            kCGPDFContextCreator: "MR Smart Glasses - Smeba Fire Safety",
            kCGPDFContextAuthor: "Smeba Fire Safety / Moyne Roberts",
            kCGPDFContextTitle: "Fire Hazard Inspection Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let data = renderer.pdfData { context in
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
            "FIRE HAZARD INSPECTION REPORT".draw(at: CGPoint(x: margin, y: 25), withAttributes: titleAttrs)

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            "Smeba Fire Safety | Moyne Roberts".draw(at: CGPoint(x: margin, y: 52), withAttributes: subtitleAttrs)

            yOffset = 100

            // Date and Risk Level
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            "Date: \(result.formattedDate)".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttrs)

            let riskColor = riskUIColor(for: result.overallRisk)
            let riskAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 11),
                .foregroundColor: riskColor
            ]
            "Risk Level: \(result.overallRisk.displayName)".draw(at: CGPoint(x: pageWidth - margin - 120, y: yOffset), withAttributes: riskAttrs)

            yOffset += 30

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

            // Summary Section
            let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            "SUMMARY".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
            yOffset += 20

            let summaryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
            let summaryRect = CGRect(x: margin, y: yOffset, width: pageWidth - (margin * 2), height: 60)
            (result.summary as NSString).draw(in: summaryRect, withAttributes: summaryAttrs)
            yOffset += 50

            // Safety Compliance Section
            yOffset += 10
            "SAFETY COMPLIANCE".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
            yOffset += 20

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
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray
                ]
                item.name.draw(at: CGPoint(x: margin + 20, y: yOffset), withAttributes: itemAttrs)

                let statusAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: statusColor
                ]
                statusSymbol.draw(at: CGPoint(x: pageWidth - margin - 30, y: yOffset), withAttributes: statusAttrs)

                yOffset += 18
            }

            // Hazards Section
            if !result.hazards.isEmpty {
                yOffset += 15
                "IDENTIFIED HAZARDS".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
                yOffset += 20

                for hazard in result.hazards {
                    // Check if we need a new page
                    if yOffset > pageHeight - 150 {
                        context.beginPage()
                        yOffset = margin
                    }

                    let severityColor = riskUIColor(for: hazard.severity)

                    // Hazard type with severity
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
                    yOffset += 16

                    // Description
                    let descAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.darkGray
                    ]
                    let descRect = CGRect(x: margin + 15, y: yOffset, width: pageWidth - (margin * 2) - 15, height: 30)
                    (hazard.description as NSString).draw(in: descRect, withAttributes: descAttrs)
                    yOffset += 28

                    // Recommendation
                    let recLabelAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.italicSystemFont(ofSize: 10),
                        .foregroundColor: UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
                    ]
                    let recRect = CGRect(x: margin + 15, y: yOffset, width: pageWidth - (margin * 2) - 15, height: 30)
                    ("→ \(hazard.recommendation)" as NSString).draw(in: recRect, withAttributes: recLabelAttrs)
                    yOffset += 35
                }
            }

            // Recommendations Section
            if !result.recommendations.isEmpty {
                // Check if we need a new page
                if yOffset > pageHeight - 150 {
                    context.beginPage()
                    yOffset = margin
                }

                yOffset += 10
                "RECOMMENDATIONS".draw(at: CGPoint(x: margin, y: yOffset), withAttributes: sectionTitleAttrs)
                yOffset += 20

                for (index, rec) in result.recommendations.enumerated() {
                    if yOffset > pageHeight - 60 {
                        context.beginPage()
                        yOffset = margin
                    }

                    let recAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.darkGray
                    ]
                    let recRect = CGRect(x: margin + 20, y: yOffset, width: pageWidth - (margin * 2) - 20, height: 30)
                    ("\(index + 1). \(rec)" as NSString).draw(in: recRect, withAttributes: recAttrs)
                    yOffset += 25
                }
            }

            // Footer
            let footerY = pageHeight - 40
            UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).setFill()
            context.cgContext.fill(CGRect(x: 0, y: footerY, width: pageWidth, height: 40))

            let footerText = "Generated by MR Smart Glasses App • Analyzed by \(result.source.rawValue) • www.smeba.nl | www.moyneroberts.ie"
            let footerStyle = NSMutableParagraphStyle()
            footerStyle.alignment = .center
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.gray,
                .paragraphStyle: footerStyle
            ]
            (footerText as NSString).draw(in: CGRect(x: margin, y: footerY + 14, width: pageWidth - (margin * 2), height: 20), withAttributes: footerAttrs)
        }

        // Save to temp file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "FireHazardReport_\(Date().timeIntervalSince1970).pdf"
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

    // MARK: - Image Section

    private var imageSection: some View {
        Image(uiImage: result.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 200)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    // MARK: - Risk Summary

    private var riskSummarySection: some View {
        VStack(spacing: 16) {
            // Risk Level Badge
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: result.overallRisk.color).opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: result.overallRisk.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: result.overallRisk.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(result.overallRisk.displayName) Risk")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text("\(result.hazardCount) hazard(s) identified")
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                }

                Spacer()
            }

            // Summary
            Text(result.summary)
                .font(.body)
                .foregroundStyle(MoyneRoberts.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cleanCard(cornerRadius: 20, padding: 16)
    }

    // MARK: - Safety Compliance

    private var safetyComplianceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Safety Compliance")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)

                Spacer()

                if result.safetyCompliance.totalChecked > 0 {
                    Text("\(result.safetyCompliance.passedCount)/\(result.safetyCompliance.totalChecked) passed")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                }
            }

            VStack(spacing: 8) {
                ForEach(result.safetyCompliance.complianceItems, id: \.name) { item in
                    ComplianceRow(
                        name: item.name,
                        status: item.status,
                        isPositive: item.isPositive
                    )
                }
            }
        }
        .cleanCard(cornerRadius: 20, padding: 16)
    }

    // MARK: - Hazards Section

    private var hazardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identified Hazards")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(result.hazards) { hazard in
                HazardCardClean(hazard: hazard)
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(MoyneRoberts.accent))

                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundStyle(MoyneRoberts.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .cleanCard(cornerRadius: 16, padding: 16)
        }
    }

    // MARK: - Analysis Info

    private var analysisInfoSection: some View {
        HStack(spacing: 16) {
            // Analysis Source
            HStack(spacing: 6) {
                Image(systemName: result.source.iconName)
                    .foregroundStyle(MoyneRoberts.accent)
                Text(result.source.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Timestamp
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundStyle(.white.opacity(0.5))
                Text(result.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Report Generation

    private func generateReport() -> String {
        var report = """
        FIRE HAZARD INSPECTION REPORT
        Generated by MR Smart Glasses
        Moyne Roberts Fire Safety

        Date: \(result.formattedDate)
        Overall Risk Level: \(result.overallRisk.displayName)

        SUMMARY
        \(result.summary)

        """

        if !result.hazards.isEmpty {
            report += "\nIDENTIFIED HAZARDS\n"
            for (index, hazard) in result.hazards.enumerated() {
                report += """
                \(index + 1). \(hazard.type)
                   Severity: \(hazard.severity.displayName)
                   Description: \(hazard.description)
                   Recommendation: \(hazard.recommendation)

                """
            }
        }

        if !result.recommendations.isEmpty {
            report += "\nRECOMMENDATIONS\n"
            for (index, rec) in result.recommendations.enumerated() {
                report += "\(index + 1). \(rec)\n"
            }
        }

        report += """

        ---
        Analysis performed using \(result.source.rawValue)
        Report generated by MR Smart Glasses App
        www.moyneroberts.ie
        """

        return report
    }
}

// MARK: - Compliance Row

struct ComplianceRow: View {
    let name: String
    let status: Bool?
    let isPositive: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.primary)

            Spacer()

            if let status = status {
                let isPassed = isPositive ? status : !status
                Image(systemName: isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isPassed ? MoyneRoberts.success : MoyneRoberts.error)
            } else {
                Text("N/A")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Hazard Card (Legacy - for dark backgrounds)

struct HazardCard: View {
    let hazard: FireHazard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(hex: hazard.severity.color))

                Text(hazard.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Spacer()

                Text(hazard.severity.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: hazard.severity.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: hazard.severity.color).opacity(0.2))
                    )
            }

            // Description
            Text(hazard.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            // Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.accent)

                Text(hazard.recommendation)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MoyneRoberts.accent.opacity(0.1))
            )
        }
        .liquidGlassCard(cornerRadius: 16, padding: 14)
    }
}

// MARK: - Hazard Card Clean (for white card backgrounds)

struct HazardCardClean: View {
    let hazard: FireHazard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(hex: hazard.severity.color))

                Text(hazard.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(MoyneRoberts.primary)

                Spacer()

                Text(hazard.severity.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: hazard.severity.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: hazard.severity.color).opacity(0.15))
                    )
            }

            // Description
            Text(hazard.description)
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary)

            // Recommendation
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.accent)

                Text(hazard.recommendation)
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(MoyneRoberts.accent.opacity(0.08))
            )
        }
        .cleanCard(cornerRadius: 16, padding: 14)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create activity items with a custom text provider
        var activityItems: [Any] = []

        for item in items {
            if let text = item as? String {
                activityItems.append(ReportTextItemSource(text: text))
            } else {
                activityItems.append(item)
            }
        }

        let controller = UIActivityViewController(
            activityItems: activityItems.isEmpty ? items : activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Custom Text Item Source for Sharing

class ReportTextItemSource: NSObject, UIActivityItemSource {
    let text: String

    init(text: String) {
        self.text = text
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Fire Hazard Inspection Report - Smeba Fire Safety"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.plain-text"
    }
}

#Preview {
    InspectionResultsView(
        result: InspectionResult(
            id: UUID(),
            timestamp: Date(),
            image: UIImage(systemName: "photo")!,
            overallRisk: .medium,
            hazards: [
                FireHazard(
                    type: "Blocked Exit",
                    description: "Storage boxes blocking emergency exit door",
                    severity: .high,
                    recommendation: "Remove all obstructions from exit pathway immediately"
                ),
                FireHazard(
                    type: "Electrical Hazard",
                    description: "Overloaded power strip with daisy-chained extensions",
                    severity: .medium,
                    recommendation: "Replace with properly rated power distribution"
                )
            ],
            safetyCompliance: SafetyCompliance(
                fireExtinguisherVisible: true,
                exitSignsVisible: false,
                clearEgressPath: false,
                electricalHazards: true,
                flammableMaterialsStored: nil
            ),
            summary: "This area shows moderate fire risk with blocked exits and electrical concerns that require immediate attention.",
            recommendations: [
                "Clear the emergency exit pathway immediately",
                "Install proper exit signage",
                "Replace overloaded power strips",
                "Schedule professional electrical inspection"
            ],
            source: .claudeAI
        )
    )
}
