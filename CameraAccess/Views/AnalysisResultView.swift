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
                    // Photo thumbnail
                    photoSection

                    // Risk Level Card
                    riskLevelCard

                    // Summary Card
                    summaryCard

                    // Hazards Card
                    if !result.hazards.isEmpty {
                        hazardsCard
                    }

                    // Compliance Checklist
                    if !result.complianceItems.isEmpty {
                        complianceCard
                    }

                    // Recommendations Card
                    if !result.recommendations.isEmpty {
                        recommendationsCard
                    }

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color.mrBackground)
            .navigationTitle("Analyse Resultaat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sluiten") {
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
                    Text("Risico Niveau")
                        .font(.subheadline)
                        .foregroundColor(.mrTextSecondary)
                    Text(riskLevelText)
                        .font(.title2.bold())
                        .foregroundColor(riskColor)
                }

                Spacer()

                RiskLevelBadge(level: result.riskLevel)
            }
        }
        .padding()
        .mrCardStyle()
    }

    private var riskIcon: String {
        switch result.riskLevel.lowercased() {
        case "low": return "checkmark.shield.fill"
        case "medium": return "exclamationmark.triangle.fill"
        case "high": return "flame.fill"
        case "critical": return "xmark.octagon.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var riskColor: Color {
        switch result.riskLevel.lowercased() {
        case "low": return .mrRiskLow
        case "medium": return .mrRiskMedium
        case "high": return .mrRiskHigh
        case "critical": return .mrRiskCritical
        default: return .mrTextSecondary
        }
    }

    private var riskLevelText: String {
        switch result.riskLevel.lowercased() {
        case "low": return "Laag Risico"
        case "medium": return "Gemiddeld Risico"
        case "high": return "Hoog Risico"
        case "critical": return "Kritiek Risico"
        default: return "Onbekend"
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Samenvatting", systemImage: "doc.text.fill")
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

    // MARK: - Hazards Card

    private var hazardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Geïdentificeerde Gevaren", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.mrSecondary)

            ForEach(result.hazards, id: \.self) { hazard in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.mrSecondary)
                        .frame(width: 20)
                    Text(hazard)
                        .font(.body)
                        .foregroundColor(.mrTextPrimary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.mrSecondary.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Compliance Card

    private var complianceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Compliance Checklist", systemImage: "checklist")
                .font(.headline)
                .foregroundColor(.mrTextPrimary)

            ForEach(result.complianceItems) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.status ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(item.status ? .mrRiskLow : .mrSecondary)
                        .frame(width: 20)
                    Text(item.item)
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

    // MARK: - Recommendations Card

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Aanbevelingen", systemImage: "lightbulb.fill")
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onNewScan) {
                Label("Nieuwe Scan", systemImage: "camera.fill")
            }
            .buttonStyle(MRPrimaryButtonStyle())

            Button(action: { showShareSheet = true }) {
                Label("Deel Rapport", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(MRSecondaryButtonStyle())
        }
        .padding(.top, 8)
    }
}
