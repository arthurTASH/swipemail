import Foundation

protocol GmailService {
    func fetchUnreadPrimaryMessages() async throws -> [GmailMessage]
}

struct DefaultGmailService: GmailService {
    private let unreadPrimaryQuery = GmailUnreadPrimaryQuery()
    private let tokenStore: SessionTokenStore
    private let environment: AppEnvironment
    private let logger: AppLogger
    private let analyticsService: AnalyticsService
    private let urlSession: URLSession

    init(
        tokenStore: SessionTokenStore,
        environment: AppEnvironment,
        logger: AppLogger,
        analyticsService: AnalyticsService,
        urlSession: URLSession = .shared
    ) {
        self.tokenStore = tokenStore
        self.environment = environment
        self.logger = logger
        self.analyticsService = analyticsService
        self.urlSession = urlSession
    }

    func fetchUnreadPrimaryMessages() async throws -> [GmailMessage] {
        guard let session = tokenStore.loadSession() else {
            throw AppError.auth(message: "A valid authenticated session is required before fetching Gmail messages.")
        }

        let request = try makeListMessagesRequest(accessToken: session.accessToken)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(message: "Gmail API did not return a valid HTTP response.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let apiError = decodeAPIError(from: data)
            logger.error(
                "Gmail list request failed.",
                metadata: [
                    "statusCode": String(httpResponse.statusCode),
                    "message": apiError ?? "unknown",
                ]
            )
            analyticsService.track(
                AnalyticsEvent(
                    name: "gmail_list_failed",
                    properties: ["statusCode": String(httpResponse.statusCode)]
                )
            )
            throw AppError.network(message: apiError ?? "Gmail API request failed.")
        }

        let payload: GmailListMessagesResponse
        do {
            payload = try JSONDecoder().decode(GmailListMessagesResponse.self, from: data)
        } catch {
            logger.error("Failed to decode Gmail list response.", metadata: ["message": error.localizedDescription])
            throw AppError.unknown(message: "Gmail API returned an unread-message payload that could not be decoded.")
        }

        analyticsService.track(
            AnalyticsEvent(
                name: "gmail_list_completed",
                properties: [
                    "resultCount": String(payload.messages?.count ?? 0),
                    "query": unreadPrimaryQuery.query,
                ]
            )
        )
        logger.info(
            "Fetched Gmail message identifiers.",
            metadata: [
                "resultCount": String(payload.messages?.count ?? 0),
                "query": unreadPrimaryQuery.query,
            ]
        )

        let messageReferences = payload.messages ?? []
        var messages: [GmailMessage] = []
        messages.reserveCapacity(messageReferences.count)

        for reference in messageReferences {
            let detail = try await fetchMessageDetail(
                id: reference.id,
                accessToken: session.accessToken
            )
            messages.append(projectMessage(from: detail))
        }

        return messages
    }

    private func makeListMessagesRequest(accessToken: String) throws -> URLRequest {
        guard var components = URLComponents(
            url: environment.gmailAPI.baseURL.appending(path: "/gmail/v1/users/me/messages"),
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.network(message: "Could not build the Gmail list request URL.")
        }

        components.queryItems = unreadPrimaryQuery.queryItems

        guard let url = components.url else {
            throw AppError.network(message: "Could not build the Gmail list request URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func decodeAPIError(from data: Data) -> String? {
        guard let payload = try? JSONDecoder().decode(GmailAPIErrorResponse.self, from: data) else {
            return nil
        }

        return payload.error.message
    }

    private func fetchMessageDetail(id: String, accessToken: String) async throws -> GmailMessageDetailResponse {
        let request = try makeMessageDetailRequest(id: id, accessToken: accessToken)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(message: "Gmail API did not return a valid HTTP response.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let apiError = decodeAPIError(from: data)
            logger.error(
                "Gmail message detail request failed.",
                metadata: [
                    "messageID": id,
                    "statusCode": String(httpResponse.statusCode),
                    "message": apiError ?? "unknown",
                ]
            )
            throw AppError.network(message: apiError ?? "Gmail message detail request failed.")
        }

        do {
            return try JSONDecoder().decode(GmailMessageDetailResponse.self, from: data)
        } catch {
            logger.error(
                "Failed to decode Gmail message detail response.",
                metadata: [
                    "messageID": id,
                    "message": error.localizedDescription,
                ]
            )
            throw AppError.unknown(message: "Gmail API returned a message payload that could not be decoded.")
        }
    }

    private func makeMessageDetailRequest(id: String, accessToken: String) throws -> URLRequest {
        guard var components = URLComponents(
            url: environment.gmailAPI.baseURL.appending(path: "/gmail/v1/users/me/messages/\(id)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.network(message: "Could not build the Gmail message detail URL.")
        }

        components.queryItems = [
            URLQueryItem(name: "format", value: "metadata"),
            URLQueryItem(name: "metadataHeaders", value: "From"),
            URLQueryItem(name: "metadataHeaders", value: "Subject"),
            URLQueryItem(name: "metadataHeaders", value: "Date"),
        ]

        guard let url = components.url else {
            throw AppError.network(message: "Could not build the Gmail message detail URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func projectMessage(from detail: GmailMessageDetailResponse) -> GmailMessage {
        GmailMessage(
            id: detail.id,
            threadID: detail.threadID,
            sender: parseSender(from: detail.headerValue(named: "From")) ?? "Unknown Sender",
            subject: detail.headerValue(named: "Subject")?.nilIfEmpty ?? "(No Subject)",
            preview: detail.snippet?.nilIfEmpty ?? "No preview available.",
            receivedAt: parseDate(from: detail.headerValue(named: "Date")),
            labelIDs: detail.labelIDs ?? []
        )
    }

    private func parseSender(from header: String?) -> String? {
        guard let header = header?.nilIfEmpty else {
            return nil
        }

        if let start = header.firstIndex(of: "<"), start > header.startIndex {
            let displayName = header[..<start].trimmingCharacters(in: .whitespacesAndNewlines)
            if !displayName.isEmpty {
                return displayName.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }

        return header
    }

    private func parseDate(from header: String?) -> Date? {
        guard let header = header?.nilIfEmpty else {
            return nil
        }

        return gmailHeaderDateFormatter.date(from: header)
    }
}

private struct GmailUnreadPrimaryQuery {
    let maxResults = 20

    // Gmail returns message lists newest first, so the query only needs to
    // constrain the slice to unread messages in the primary inbox.
    let query = "category:primary is:unread"

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "labelIds", value: "INBOX"),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "q", value: query),
        ]
    }
}

private struct GmailListMessagesResponse: Decodable {
    let messages: [MessageReference]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?

    struct MessageReference: Decodable {
        let id: String
        let threadID: String

        private enum CodingKeys: String, CodingKey {
            case id
            case threadID = "threadId"
        }
    }
}

private struct GmailMessageDetailResponse: Decodable {
    let id: String
    let threadID: String
    let labelIDs: [String]?
    let snippet: String?
    let payload: Payload?

    func headerValue(named name: String) -> String? {
        payload?.headers?.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case threadID = "threadId"
        case labelIDs = "labelIds"
        case snippet
        case payload
    }

    struct Payload: Decodable {
        let headers: [Header]?
    }

    struct Header: Decodable {
        let name: String
        let value: String
    }
}

private struct GmailAPIErrorResponse: Decodable {
    let error: GmailAPIErrorPayload

    struct GmailAPIErrorPayload: Decodable {
        let code: Int
        let message: String
    }
}

private let gmailHeaderDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
    return formatter
}()

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
