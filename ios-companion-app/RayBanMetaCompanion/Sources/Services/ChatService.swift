import Foundation

/// Message model for chat conversations
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

/// Service for streaming chat with Orq.ai Instruction_Support_Agent deployment
@MainActor
class ChatService: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var error: String?

    // MARK: - Configuration

    private let apiKey: String?
    private let invokeURL = "https://api.orq.ai/v2/deployments/invoke"
    private let deploymentKey = "Instruction_Support_Agent"

    // MARK: - Streaming State

    private var currentTask: Task<Void, Never>?

    init() {
        // Load Orq.ai API key from environment variable
        let envKey = ProcessInfo.processInfo.environment["ORQ_API_KEY"]
        let plistKey = Bundle.main.object(forInfoDictionaryKey: "ORQ_API_KEY") as? String

        // Filter out unexpanded build variables like "$(ORQ_API_KEY)"
        let validPlistKey = plistKey?.hasPrefix("$(") == true ? nil : plistKey

        self.apiKey = envKey ?? validPlistKey

        if self.apiKey != nil {
            print("[ChatService] API key loaded successfully")
        } else {
            print("[ChatService] WARNING: No ORQ_API_KEY found")
        }
    }

    // MARK: - Public Methods

    /// Send a message and stream the response
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: content)
        messages.append(userMessage)

        // Check for API key
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            error = "No API key configured. Please set ORQ_API_KEY in environment variables."
            return
        }

        // Create placeholder for assistant response
        let assistantMessage = ChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)

        isStreaming = true
        error = nil

        // Cancel any existing streaming task
        currentTask?.cancel()

        currentTask = Task {
            await streamResponse(apiKey: apiKey, assistantMessageId: assistantMessage.id)
        }
    }

    /// Stop the current streaming response
    func stopStreaming() {
        currentTask?.cancel()
        currentTask = nil
        isStreaming = false

        // Mark the last message as not streaming
        if let lastIndex = messages.indices.last,
           messages[lastIndex].role == .assistant {
            messages[lastIndex].isStreaming = false
        }
    }

    /// Clear all messages
    func clearMessages() {
        stopStreaming()
        messages.removeAll()
        error = nil
    }

    // MARK: - Private Methods

    private func streamResponse(apiKey: String, assistantMessageId: UUID) async {
        do {
            // Build messages array for API
            let apiMessages = messages
                .filter { $0.role == .user || ($0.role == .assistant && !$0.content.isEmpty) }
                .map { message -> [String: Any] in
                    return [
                        "role": message.role.rawValue,
                        "content": message.content
                    ]
                }

            // Request body
            let requestBody: [String: Any] = [
                "key": deploymentKey,
                "messages": apiMessages,
                "context": [
                    "environments": [] as [String]
                ],
                "metadata": [
                    "source": "ios-companion-app",
                    "feature": "instruction_support"
                ]
            ]

            guard let url = URL(string: invokeURL) else {
                throw ChatError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 120
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            print("[ChatService] Sending request to deployment: \(deploymentKey)")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatError.invalidResponse
            }

            print("[ChatService] Response status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("[ChatService] API error: \(errorMessage)")
                throw ChatError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            // Parse response: { "choices": [{ "message": { "content": "..." } }] }
            let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let choices = responseJson?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("[ChatService] Failed to parse response")
                throw ChatError.invalidResponse
            }

            let finalContent = content

            print("[ChatService] Received response, length: \(finalContent.count)")

            // Update the message with full response
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                messages[index].content = finalContent
                messages[index].isStreaming = false
            }

        } catch {
            print("[ChatService] Error: \(error)")
            self.error = error.localizedDescription

            // Remove empty assistant message on error
            if let index = messages.firstIndex(where: { $0.id == assistantMessageId }),
               messages[index].content.isEmpty {
                messages.remove(at: index)
            }
        }

        isStreaming = false
    }
}

// MARK: - Errors

enum ChatError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noAPIKey:
            return "No API key configured"
        }
    }
}
