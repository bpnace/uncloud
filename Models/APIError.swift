import Foundation

// Shared API error types used by all API services
enum APIError: Error {
    case missingAPIKey
    case networkError
    case serverError
    case rateLimitExceeded
    case invalidResponse
    case jsonParsingError
    case unknown(String)
} 