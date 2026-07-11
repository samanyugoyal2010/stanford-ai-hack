import Foundation

/// Turns OCR / screenshot samples into first-person study narratives for EverOS.
enum ObservationMessageBuilder {
    static func makeTextMessage(ocrText: String, frame: CapturedFrame) -> EverOSMessage {
        let trimmed = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        let excerpt: String
        if trimmed.isEmpty {
            excerpt = "(little readable text on screen — I may be watching video, diagrams, or a mostly visual app)"
        } else {
            let limited = String(trimmed.prefix(2500))
            excerpt = limited
        }

        let body = """
        Observation of my study workflow right now:
        I am actively studying on my Mac. On my screen I currently see:
        \(excerpt)

        Please remember how I study: what materials I use, whether I seem stuck or fluent, \
        and any learning preferences implied by this activity.
        """
        return .user(text: body, at: frame.timestamp)
    }

    static func makeMultimodalMessage(
        ocrText: String,
        frame: CapturedFrame,
        imageItem: EverOSContentItem
    ) -> EverOSMessage {
        let textMessage = makeTextMessage(ocrText: ocrText, frame: frame)
        guard case .text(let text) = textMessage.content else {
            return textMessage
        }
        return .user(
            parts: [
                .text(text),
                imageItem
            ],
            at: frame.timestamp
        )
    }
}
