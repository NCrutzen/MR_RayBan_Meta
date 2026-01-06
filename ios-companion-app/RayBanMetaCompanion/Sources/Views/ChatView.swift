import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @State private var inputText = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AnimatedGradientBackground()

                VStack(spacing: 0) {
                    // Header
                    ChatHeader(onClear: {
                        chatService.clearMessages()
                    })

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if chatService.messages.isEmpty {
                                    ChatEmptyStateView()
                                        .padding(.top, 60)
                                } else {
                                    ForEach(chatService.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                }

                                // Error message
                                if let error = chatService.error {
                                    ChatErrorBanner(message: error)
                                }

                                // Spacer for input area
                                Color.clear.frame(height: 120)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .onTapGesture {
                            // Dismiss keyboard when tapping on messages
                            isInputFocused = false
                        }
                        .onChange(of: chatService.messages.count) { _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: chatService.messages.last?.content) { _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: keyboardHeight) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                scrollToBottom(proxy: proxy)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }

                // Input area pinned to bottom, above keyboard
                VStack {
                    Spacer()
                    ChatInputBar(
                        text: $inputText,
                        isStreaming: chatService.isStreaming,
                        isFocused: $isInputFocused,
                        keyboardHeight: keyboardHeight,
                        onSend: sendMessage,
                        onStop: { chatService.stopStreaming() }
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatService.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        inputText = ""
        isInputFocused = false

        Task {
            await chatService.sendMessage(message)
        }
    }
}

// MARK: - Chat Header

struct ChatHeader: View {
    let onClear: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Support Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Ask questions about fire safety")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onClear) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A2744").opacity(0.9),
                    Color(hex: "1A2744").opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Empty State

struct ChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))

            Text("Start a Conversation")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Text("Ask about fire safety regulations,\ninspection procedures, or equipment.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                // Assistant avatar
                Circle()
                    .fill(MoyneRoberts.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    )
            } else {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content.isEmpty ? " " : message.content)
                    .font(.body)
                    .foregroundStyle(message.role == .user ? .white : MoyneRoberts.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? MoyneRoberts.accent : Color.white)
                    )
                    .overlay(
                        Group {
                            if message.isStreaming {
                                HStack(spacing: 4) {
                                    Spacer()
                                    StreamingIndicator()
                                }
                                .padding(.trailing, 14)
                                .padding(.bottom, 10)
                            }
                        },
                        alignment: .bottomTrailing
                    )

                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                // User avatar
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    )
            } else {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Streaming Indicator

struct StreamingIndicator: View {
    @State private var dotIndex = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(MoyneRoberts.accent)
                    .frame(width: 4, height: 4)
                    .opacity(dotIndex == index ? 1.0 : 0.3)
            }
        }
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

// MARK: - Error Banner

struct ChatErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(MoyneRoberts.error)

            Text(message)
                .font(.caption)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MoyneRoberts.error.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MoyneRoberts.error.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    var isFocused: FocusState<Bool>.Binding
    let keyboardHeight: CGFloat
    let onSend: () -> Void
    let onStop: () -> Void

    private var isKeyboardVisible: Bool {
        keyboardHeight > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                // Text input
                TextField("Ask about fire safety...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .focused(isFocused)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !isStreaming {
                            onSend()
                        }
                    }

                // Send/Stop button
                Button(action: {
                    if isStreaming {
                        onStop()
                    } else {
                        onSend()
                    }
                }) {
                    Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isStreaming ? MoyneRoberts.error : MoyneRoberts.accent)
                        )
                }
                .disabled(!isStreaming && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(!isStreaming && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, isKeyboardVisible ? keyboardHeight : 100) // Above keyboard or tab bar
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    ChatView()
}
