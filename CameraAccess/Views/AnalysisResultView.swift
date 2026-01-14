/*
 * AnalysisResultView.swift
 *
 * View displaying the fire hazard analysis results from Orq.ai.
 */

import SwiftUI

struct AnalysisResultView: View {
    let result: AnalysisResult
    let onDismiss: () -> Void
    let onNewScan: () -> Void

    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard

                    // Photo thumbnail
                    photoSection

                    // Risk Level Card
                    riskLevelCard

                    // Summary Card
                    summaryCard

                    // Safety Compliance Card
                    if !result.safetyCompliance.isEmpty {
                        complianceCard
                    }

                    // Identified Hazards
                    if !result.identifiedHazards.isEmpty {
                        hazardsSection
                    }

                    // Recommendations Card
                    if !result.recommendations.isEmpty {
                        recommendationsCard
                    }

                    // Footer Card
                    footerCard

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color.mrBackground)
            .navigationTitle("Analysis Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.mrPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.mrPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(photo: result.photo)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(result.header.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.mrPrimary)
                .multilineTextAlignment(.center)

            Text(result.header.company)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mrTextSecondary)

            HStack(spacing: 16) {
                if !result.header.location.isEmpty && result.header.location != "Unknown" {
                    Label(result.header.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.mrTextSecondary)
                }
                if !result.header.date.isEmpty {
                    Label(result.header.date, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.mrTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.mrPrimary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Image(uiImage: result.photo)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipped()
            .cornerRadius(12)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding(12)
                }
            )
    }

    // MARK: - Risk Level Card

    private var riskLevelCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: riskIcon)
                    .font(.system(size: 40))
                    .foregroundColor(riskColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk Level")
                        .font(.subheadline)
                        .foregroundColor(.mrTextSecondary)
                    Text(result.header.riskLevel.uppercased())
                        .font(.title2.bold())
                        .foregroundColor(riskColor)
                }

                Spacer()

                RiskLevelBadge(level: result.header.riskLevel)
            }
        }
        .padding()
        .mrCardStyle()
    }

    private var riskIcon: String {
        switch result.header.riskLevel.lowercased() {
        case "low": return "checkmark.shield.fill"
        case "medium": return "exclamationmark.triangle.fill"
        case "high": return "flame.fill"
        case "critical": return "xmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var riskColor: Color {
        switch result.header.riskLevel.lowercased() {
        case "low": return .mrRiskLow
        case "medium": return .mrRiskMedium
        case "high": return .mrRiskHigh
        case "critical": return .mrRiskCritical
        default: return .mrTextSecondary
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Summary", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundColor(.mrTextPrimary)

            Text(result.summary)
                .font(.body)
                .foregroundColor(.mrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .mrCardStyle()
    }

    // MARK: - Compliance Card

    private var complianceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Safety Compliance", systemImage: "checklist")
                .font(.headline)
                .foregroundColor(.mrTextPrimary)

            ForEach(result.safetyCompliance) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.status ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(item.status ? .mrRiskLow : .mrSecondary)
                        .frame(width: 20)
                    Text(item.label)
                        .font(.body)
                        .foregroundColor(.mrTextPrimary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .mrCardStyle()
    }

    // MARK: - Hazards Section

    private var hazardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Identified Hazards", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.mrSecondary)

            ForEach(result.identifiedHazards) { hazard in
                hazardCard(hazard)
            }
        }
    }

    private func hazardCard(_ hazard: AnalysisResult.Hazard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(hazard.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.mrTextPrimary)
                Spacer()
                RiskLevelBadge(level: hazard.riskLevel)
            }

            Text(hazard.description)
                .font(.body)
                .foregroundColor(.mrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !hazard.recommendedAction.isEmpty {
                Divider()
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.mrAccent)
                        .frame(width: 20)
                    Text(hazard.recommendedAction)
                        .font(.callout)
                        .foregroundColor(.mrTextPrimary)
                }
            }
        }
        .padding()
        .background(Color.mrSecondary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Recommendations Card

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.mrAccent)

            ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.body.bold())
                        .foregroundColor(.mrAccent)
                        .frame(width: 24)
                    Text(recommendation)
                        .font(.body)
                        .foregroundColor(.mrTextPrimary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.mrAccent.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Footer Card

    private var footerCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Generated by:")
                    .font(.caption)
                    .foregroundColor(.mrTextSecondary)
                Text(result.footer.generatedBy)
                    .font(.caption.bold())
                    .foregroundColor(.mrTextPrimary)
            }
            HStack {
                Text("Analyzed by:")
                    .font(.caption)
                    .foregroundColor(.mrTextSecondary)
                Text(result.footer.analyzedBy)
                    .font(.caption.bold())
                    .foregroundColor(.mrTextPrimary)
            }
            if !result.footer.links.isEmpty {
                HStack(spacing: 12) {
                    ForEach(result.footer.links, id: \.self) { link in
                        Text(link)
                            .font(.caption)
                            .foregroundColor(.mrPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.mrBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mrTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onNewScan) {
                Label("New Scan", systemImage: "camera.fill")
            }
            .buttonStyle(MRPrimaryButtonStyle())

            Button(action: { showShareSheet = true }) {
                Label("Share Report", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(MRSecondaryButtonStyle())
        }
        .padding(.top, 8)
    }
}

// ShareSheet is defined in PhotoPreviewView.swift
