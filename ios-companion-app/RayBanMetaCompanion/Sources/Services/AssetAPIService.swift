import Foundation

/// Service for fetching asset details from N-XT API
@MainActor
final class AssetAPIService: ObservableObject {
    static let shared = AssetAPIService()

    @Published var isLoading = false
    @Published var lastError: APIError?
    @Published var currentJob: Job?
    @Published var jobAssets: [JobAsset] = []

    private let keychain = KeychainManager.shared

    // MARK: - API Configuration

    private let nxtAPIBaseURL = "https://acc.sb.n-xt.org/nxt/api"

    // Environment variable keys for Xcode scheme configuration
    private enum EnvKeys {
        static let clientId = "NXT_CLIENT_ID"
        static let clientSecret = "NXT_CLIENT_SECRET"
        static let audience = "NXT_AUDIENCE"
        static let domain = "NXT_AUTH0_DOMAIN"
    }

    private init() {
        // Auto-configure from environment variables if available
        configureFromEnvironmentIfNeeded()
    }

    /// Configure credentials from Xcode environment variables
    private func configureFromEnvironmentIfNeeded() {
        // Only configure if not already set in keychain
        guard !keychain.hasAuth0Credentials else { return }

        // Check for environment variables
        if let clientId = ProcessInfo.processInfo.environment[EnvKeys.clientId],
           let clientSecret = ProcessInfo.processInfo.environment[EnvKeys.clientSecret],
           let audience = ProcessInfo.processInfo.environment[EnvKeys.audience] {

            let domain = ProcessInfo.processInfo.environment[EnvKeys.domain] ?? "moyneroberts.eu.auth0.com"

            print("[AssetAPIService] Configuring from environment variables")
            keychain.saveAuth0Credentials(
                clientId: clientId,
                clientSecret: clientSecret,
                audience: audience,
                domain: domain
            )
        }
    }

    // MARK: - Error Types

    enum APIError: LocalizedError {
        case missingCredentials
        case authenticationFailed(String)
        case networkError(Error)
        case invalidResponse
        case assetNotFound
        case serverError(Int, String?)

        var errorDescription: String? {
            switch self {
            case .missingCredentials:
                return "API credentials not configured. Please set up in Settings."
            case .authenticationFailed(let message):
                return "Authentication failed: \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .assetNotFound:
                return "Asset not found"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message ?? "Unknown error")"
            }
        }
    }

    // MARK: - Authentication

    /// Get a valid access token, refreshing if necessary
    func getAccessToken() async throws -> String {
        // Check if we have a valid cached token
        if let token = keychain.accessToken {
            return token
        }

        // Need to fetch a new token
        return try await refreshAccessToken()
    }

    /// Refresh the access token using client credentials
    private func refreshAccessToken() async throws -> String {
        print("[AssetAPIService] Refreshing access token...")

        guard let clientId = keychain.retrieve(for: .auth0ClientId),
              let clientSecret = keychain.retrieve(for: .auth0ClientSecret),
              let audience = keychain.retrieve(for: .auth0Audience),
              let domain = keychain.retrieve(for: .auth0Domain) else {
            print("[AssetAPIService] ERROR: Missing credentials")
            throw APIError.missingCredentials
        }

        print("[AssetAPIService] Auth0 domain: \(domain)")
        let tokenURL = URL(string: "https://\(domain)/oauth/token")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // 15 second timeout

        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "audience": audience,
            "grant_type": "client_credentials"
        ]

        request.httpBody = try JSONEncoder().encode(body)

        print("[AssetAPIService] Requesting token from Auth0...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[AssetAPIService] ERROR: Invalid response type")
            throw APIError.invalidResponse
        }

        print("[AssetAPIService] Auth0 response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8)
            print("[AssetAPIService] ERROR: Auth failed - \(errorMessage ?? "unknown")")
            throw APIError.authenticationFailed(errorMessage ?? "Unknown error")
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let expires_in: Int
            let token_type: String
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        print("[AssetAPIService] Token received, expires in \(tokenResponse.expires_in)s")

        // Save token to keychain
        keychain.saveAccessToken(tokenResponse.access_token, expiresIn: tokenResponse.expires_in)

        return tokenResponse.access_token
    }

    // MARK: - Job Lookup

    /// Fetch job details by job ID - assets are in response.d.site.assets
    func fetchJobDetails(jobId: String, retryCount: Int = 0) async throws -> Job {
        print("[AssetAPIService] Fetching job: \(jobId) (attempt \(retryCount + 1))")
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        do {
            let token = try await getAccessToken()
            print("[AssetAPIService] Got token (first 20 chars): \(String(token.prefix(20)))...")

            guard let url = URL(string: "\(nxtAPIBaseURL)/jobs/\(jobId)") else {
                throw APIError.invalidResponse
            }

            print("[AssetAPIService] URL: \(url)")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 30 // 30 second timeout

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("[AssetAPIService] Job API response status: \(httpResponse.statusCode)")

            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                // Debug: print raw JSON
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[AssetAPIService] Response preview: \(String(jsonString.prefix(500)))...")
                }

                do {
                    let jobResponse = try decoder.decode(JobResponse.self, from: data)
                    currentJob = jobResponse.d
                    jobAssets = jobResponse.d.site?.assets ?? []
                    print("[AssetAPIService] Job loaded: \(jobResponse.d.jobNumber ?? "unknown"), assets: \(jobAssets.count)")
                    return jobResponse.d
                } catch {
                    print("[AssetAPIService] JSON decode error: \(error)")
                    throw APIError.invalidResponse
                }
            case 404:
                throw APIError.assetNotFound
            case 401:
                // Token rejected - only retry once
                if retryCount < 1 {
                    print("[AssetAPIService] 401 - clearing token and retrying once...")
                    keychain.delete(.accessToken)
                    keychain.delete(.tokenExpiry)
                    return try await fetchJobDetails(jobId: jobId, retryCount: retryCount + 1)
                } else {
                    print("[AssetAPIService] 401 - auth failed after retry. Check audience/credentials.")
                    let errorMessage = String(data: data, encoding: .utf8)
                    print("[AssetAPIService] 401 Response body: \(errorMessage ?? "empty")")
                    throw APIError.authenticationFailed("Token rejected by N-XT API. Check audience configuration.")
                }
            default:
                let errorMessage = String(data: data, encoding: .utf8)
                print("[AssetAPIService] Server error: \(errorMessage ?? "unknown")")
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch let error as APIError {
            print("[AssetAPIService] API Error: \(error.localizedDescription)")
            lastError = error
            throw error
        } catch {
            print("[AssetAPIService] Network Error: \(error)")
            let apiError = APIError.networkError(error)
            lastError = apiError
            throw apiError
        }
    }

    /// Find a specific asset within loaded job assets
    func findAsset(bySerialNumber serialNumber: String) -> JobAsset? {
        return jobAssets.first { asset in
            asset.serialNumber?.lowercased() == serialNumber.lowercased() ||
            asset.barcode?.lowercased() == serialNumber.lowercased() ||
            asset.id == serialNumber
        }
    }

    /// Search assets by partial match
    func searchAssets(query: String) -> [JobAsset] {
        guard !query.isEmpty else { return jobAssets }
        let lowercasedQuery = query.lowercased()
        return jobAssets.filter { asset in
            asset.serialNumber?.lowercased().contains(lowercasedQuery) == true ||
            asset.barcode?.lowercased().contains(lowercasedQuery) == true ||
            asset.description?.lowercased().contains(lowercasedQuery) == true ||
            asset.assetType?.lowercased().contains(lowercasedQuery) == true ||
            asset.location?.lowercased().contains(lowercasedQuery) == true
        }
    }

    // MARK: - Credential Management

    /// Configure API credentials (should be called from settings)
    func configureCredentials(clientId: String, clientSecret: String, audience: String, domain: String) {
        keychain.saveAuth0Credentials(
            clientId: clientId,
            clientSecret: clientSecret,
            audience: audience,
            domain: domain
        )
    }

    /// Check if credentials are configured
    var hasCredentials: Bool {
        keychain.hasAuth0Credentials
    }

    /// Clear all stored credentials and tokens
    func clearCredentials() {
        keychain.clearAll()
    }
}
