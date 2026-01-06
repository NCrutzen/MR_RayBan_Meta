import SwiftUI

struct FindAssetView: View {
    @StateObject private var apiService = AssetAPIService.shared
    @State private var jobIdText = "1563748" // Default job ID from the example
    @State private var assetSearchText = ""
    @State private var selectedAsset: JobAsset?
    @State private var showingAssetDetail = false
    @State private var showingCredentialsSetup = false
    @State private var isLoadingJob = false
    @State private var jobLoaded = false
    @State private var credentialsConfigured = false

    var filteredAssets: [JobAsset] {
        apiService.searchAssets(query: assetSearchText)
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection

                    if !credentialsConfigured {
                        credentialsWarningCard
                    } else if !jobLoaded {
                        jobLoadSection
                    } else {
                        jobInfoCard
                        assetSearchSection
                        assetListSection
                    }

                    if let error = apiService.lastError {
                        errorCard(error)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            TopBlurOverlay()
        }
        .sheet(isPresented: $showingAssetDetail) {
            if let asset = selectedAsset {
                JobAssetDetailView(asset: asset, job: apiService.currentJob)
            }
        }
        .sheet(isPresented: $showingCredentialsSetup, onDismiss: {
            // Refresh credentials state after sheet is dismissed
            credentialsConfigured = apiService.hasCredentials
        }) {
            APICredentialsSetupView()
        }
        .onAppear {
            credentialsConfigured = apiService.hasCredentials
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find Asset")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Load a job to view and search its assets")
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
    }

    // MARK: - Job Load Section

    private var jobLoadSection: some View {
        VStack(spacing: 16) {
            Text("Enter Job ID")
                .font(.headline)
                .foregroundStyle(MoyneRoberts.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: "number")
                    .foregroundStyle(MoyneRoberts.secondary)

                TextField("Job ID (e.g. 1563748)", text: $jobIdText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(MoyneRoberts.primary)
                    .keyboardType(.numberPad)

                if !jobIdText.isEmpty {
                    Button(action: { jobIdText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MoyneRoberts.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MoyneRoberts.cardBorder, lineWidth: 1)
            )

            Button(action: loadJob) {
                HStack(spacing: 8) {
                    if isLoadingJob {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.doc")
                    }
                    Text(isLoadingJob ? "Loading Job..." : "Load Job")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(jobIdText.isEmpty ? MoyneRoberts.accent.opacity(0.5) : MoyneRoberts.accent)
                )
            }
            .disabled(jobIdText.isEmpty || isLoadingJob)
        }
        .cleanCard(cornerRadius: 20, padding: 20)
    }

    // MARK: - Job Info Card

    private var jobInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let job = apiService.currentJob {
                        Text(job.jobNumber ?? "Job #\(job.id ?? "")")
                            .font(.headline)
                            .foregroundStyle(MoyneRoberts.primary)

                        if let desc = job.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(MoyneRoberts.secondary)
                        }

                        if let site = job.site?.name {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.caption)
                                Text(site)
                                    .font(.caption)
                            }
                            .foregroundStyle(MoyneRoberts.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(apiService.jobAssets.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(MoyneRoberts.accent)

                    Text("Assets")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                }
            }

            Button(action: { jobLoaded = false }) {
                Text("Load Different Job")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.accent)
            }
        }
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Asset Search Section

    private var assetSearchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MoyneRoberts.secondary)

            TextField("Search assets...", text: $assetSearchText)
                .textFieldStyle(.plain)
                .foregroundStyle(MoyneRoberts.primary)

            if !assetSearchText.isEmpty {
                Button(action: { assetSearchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MoyneRoberts.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MoyneRoberts.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(MoyneRoberts.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Asset List Section

    private var assetListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assets")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(filteredAssets.count) found")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
            }

            if filteredAssets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))

                    Text("No assets found")
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredAssets) { asset in
                    AssetRowCard(asset: asset) {
                        selectedAsset = asset
                        showingAssetDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Credentials Warning

    private var credentialsWarningCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(MoyneRoberts.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Not Configured")
                        .font(.headline)
                        .foregroundStyle(MoyneRoberts.primary)

                    Text("Set up your N-XT API credentials to load job assets")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                }

                Spacer()
            }

            Button(action: { showingCredentialsSetup = true }) {
                Text("Configure API")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MoyneRoberts.accent)
                    )
            }
        }
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Error Card

    private func errorCard(_ error: AssetAPIService.APIError) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundStyle(MoyneRoberts.error)

            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)

                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
            }

            Spacer()
        }
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Actions

    private func loadJob() {
        guard !jobIdText.isEmpty, !isLoadingJob else { return }

        isLoadingJob = true

        Task {
            do {
                _ = try await apiService.fetchJobDetails(jobId: jobIdText.trimmingCharacters(in: .whitespaces))
                jobLoaded = true
            } catch {
                // Error is already set in apiService.lastError
            }
            isLoadingJob = false
        }
    }
}

// MARK: - Asset Row Card

struct AssetRowCard: View {
    let asset: JobAsset
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(MoyneRoberts.accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: asset.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(MoyneRoberts.accent)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.displayType)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(MoyneRoberts.primary)

                    if let serial = asset.serialNumber {
                        Text(serial)
                            .font(.caption)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }

                    Text(asset.formattedLocation)
                        .font(.caption2)
                        .foregroundStyle(MoyneRoberts.secondary.opacity(0.8))
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(Color(hex: asset.statusColor))
                        .frame(width: 10, height: 10)

                    if let status = asset.status {
                        Text(status)
                            .font(.caption2)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary.opacity(0.5))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(MoyneRoberts.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(MoyneRoberts.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Job Asset Detail View

struct JobAssetDetailView: View {
    let asset: JobAsset
    let job: Job?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        assetHeaderCard

                        statusCard

                        locationCard

                        specificationsCard

                        serviceCard

                        if let items = asset.inspectionItems, !items.isEmpty {
                            inspectionItemsCard(items)
                        }

                        if let notes = asset.notes, !notes.isEmpty {
                            notesCard(notes)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                TopBlurOverlay()
            }
            .navigationTitle("Asset Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Card

    private var assetHeaderCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(MoyneRoberts.accent.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: asset.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(MoyneRoberts.accent)
            }

            VStack(spacing: 4) {
                Text(asset.displayType)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(MoyneRoberts.primary)

                if let serial = asset.serialNumber {
                    Text(serial)
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.secondary)
                        .textSelection(.enabled)
                }

                if let barcode = asset.barcode {
                    HStack(spacing: 4) {
                        Image(systemName: "barcode")
                            .font(.caption)
                        Text(barcode)
                            .font(.caption)
                    }
                    .foregroundStyle(MoyneRoberts.secondary.opacity(0.8))
                }
            }

            if let manufacturer = asset.manufacturer, let model = asset.model {
                Text("\(manufacturer) \(model)")
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
            } else if let desc = asset.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(MoyneRoberts.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .cleanCard(cornerRadius: 20, padding: 24)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: asset.statusColor))
                .frame(width: 12, height: 12)

            Text(asset.status ?? "Unknown")
                .font(.headline)
                .foregroundStyle(MoyneRoberts.primary)

            Spacer()

            if asset.isServiceOverdue {
                Text("OVERDUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(MoyneRoberts.error))
            }
        }
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(MoyneRoberts.accent)
                Text("Location")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)
            }

            Text(asset.formattedLocation)
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)

            if let site = job?.site {
                Divider()
                    .background(MoyneRoberts.cardBorder)

                VStack(alignment: .leading, spacing: 4) {
                    if let name = site.name {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(MoyneRoberts.primary)
                    }
                    if let address = site.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                    if let city = site.city, let postcode = site.postcode {
                        Text("\(city), \(postcode)")
                            .font(.caption)
                            .foregroundStyle(MoyneRoberts.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Specifications Card

    private var specificationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(MoyneRoberts.accent)
                Text("Specifications")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)
            }

            VStack(spacing: 8) {
                if let manufacturer = asset.manufacturer {
                    specRow(label: "Manufacturer", value: manufacturer)
                }
                if let model = asset.model {
                    specRow(label: "Model", value: model)
                }
                if let capacity = asset.capacity {
                    specRow(label: "Capacity", value: capacity)
                }
                if let rating = asset.rating {
                    specRow(label: "Rating", value: rating)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(MoyneRoberts.primary)
        }
    }

    // MARK: - Service Card

    private var serviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(MoyneRoberts.accent)
                Text("Service Information")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Service")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                    Text(asset.formattedLastService)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(MoyneRoberts.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Due")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                    Text(asset.formattedNextService)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(asset.isServiceOverdue ? MoyneRoberts.error : MoyneRoberts.primary)
                }
            }

            if let expiry = asset.formattedExpiry {
                Divider()
                    .background(MoyneRoberts.cardBorder)

                HStack {
                    Text("Expiry Date")
                        .font(.caption)
                        .foregroundStyle(MoyneRoberts.secondary)
                    Spacer()
                    Text(expiry)
                        .font(.subheadline)
                        .foregroundStyle(MoyneRoberts.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Inspection Items Card

    private func inspectionItemsCard(_ items: [InspectionItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(MoyneRoberts.accent)
                Text("Inspection Checklist")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)
            }

            VStack(spacing: 8) {
                ForEach(items, id: \.identifier) { item in
                    HStack {
                        Text(item.name ?? "Item")
                            .font(.subheadline)
                            .foregroundStyle(MoyneRoberts.secondary)

                        Spacer()

                        if let result = item.result {
                            let isPassed = result.lowercased().contains("ok") || result.lowercased().contains("pass")
                            Image(systemName: isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isPassed ? MoyneRoberts.success : MoyneRoberts.error)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cleanCard(cornerRadius: 16, padding: 16)
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(MoyneRoberts.accent)
                Text("Notes")
                    .font(.headline)
                    .foregroundStyle(MoyneRoberts.primary)
            }

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cleanCard(cornerRadius: 16, padding: 16)
    }
}

// MARK: - API Credentials Setup View

struct APICredentialsSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var audience = ""
    @State private var domain = "moyneroberts.eu.auth0.com"
    @State private var isSaving = false
    @State private var showingSuccess = false

    private let keychain = KeychainManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        infoSection

                        credentialsForm

                        saveButton

                        if keychain.hasAuth0Credentials {
                            clearButton
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("API Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                loadExistingCredentials()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var infoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(MoyneRoberts.accent)

            Text("Secure API Configuration")
                .font(.headline)
                .foregroundStyle(MoyneRoberts.primary)

            Text("Your credentials are stored securely in the iOS Keychain and never leave your device.")
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary)
                .multilineTextAlignment(.center)
        }
        .cleanCard(cornerRadius: 16, padding: 20)
    }

    private var credentialsForm: some View {
        VStack(spacing: 16) {
            credentialField(title: "Domain", text: $domain, placeholder: "moyneroberts.eu.auth0.com")
            credentialField(title: "Client ID", text: $clientId, placeholder: "Your client ID")
            credentialField(title: "Client Secret", text: $clientSecret, placeholder: "Your client secret", isSecure: true)
            credentialField(title: "Audience", text: $audience, placeholder: "API audience URL")
        }
        .cleanCard(cornerRadius: 16, padding: 20)
    }

    private func credentialField(title: String, text: Binding<String>, placeholder: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(MoyneRoberts.secondary)

            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MoyneRoberts.background)
                    )
                    .foregroundStyle(MoyneRoberts.primary)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(MoyneRoberts.background)
                    )
                    .foregroundStyle(MoyneRoberts.primary)
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveCredentials) {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else if showingSuccess {
                    Image(systemName: "checkmark")
                }
                Text(showingSuccess ? "Saved!" : "Save Credentials")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? MoyneRoberts.accent : MoyneRoberts.accent.opacity(0.5))
            )
        }
        .disabled(!isFormValid || isSaving)
    }

    private var clearButton: some View {
        Button(action: clearCredentials) {
            Text("Clear Saved Credentials")
                .font(.subheadline)
                .foregroundStyle(MoyneRoberts.error)
        }
    }

    private var isFormValid: Bool {
        !clientId.isEmpty && !clientSecret.isEmpty && !audience.isEmpty && !domain.isEmpty
    }

    private func loadExistingCredentials() {
        domain = keychain.retrieve(for: .auth0Domain) ?? "moyneroberts.eu.auth0.com"
        clientId = keychain.retrieve(for: .auth0ClientId) ?? ""
        audience = keychain.retrieve(for: .auth0Audience) ?? ""
    }

    private func saveCredentials() {
        isSaving = true

        keychain.saveAuth0Credentials(
            clientId: clientId,
            clientSecret: clientSecret,
            audience: audience,
            domain: domain
        )

        isSaving = false
        showingSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }

    private func clearCredentials() {
        keychain.clearAll()
        clientId = ""
        clientSecret = ""
        audience = ""
        domain = "moyneroberts.eu.auth0.com"
    }
}

#Preview {
    FindAssetView()
}

#Preview("Asset Detail") {
    JobAssetDetailView(asset: .mockFireExtinguisher, job: .mock)
}
