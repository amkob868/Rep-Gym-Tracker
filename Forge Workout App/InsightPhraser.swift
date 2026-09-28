import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Turns a `WorkoutInsight`'s factual summary into a short, friendly note.
///
/// When Apple Intelligence is available on the device, it uses the on-device
/// Foundation model to phrase the note naturally. Otherwise it falls back to
/// the insight's deterministic template message, so the feature always works.
enum InsightPhraser {

    static func phrase(_ insight: WorkoutInsight) async -> String {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return insight.message }

        let instructions = """
        You are a friendly, concise gym coach. Rewrite the given fact as ONE short, \
        encouraging sentence (20 words max) to show in a small speech bubble. Keep any \
        numbers exactly as given. Reply with only the sentence — no quotes, no preamble.
        """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: insight.facts)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? insight.message : text
        } catch {
            Log.debug("Insight phrasing failed, using template: \(error)")
            return insight.message
        }
        #else
        return insight.message
        #endif
    }
}
