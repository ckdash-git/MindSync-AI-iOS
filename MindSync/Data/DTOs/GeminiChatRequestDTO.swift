import Foundation

struct GeminiChatRequestDTO: Encodable {
    let contents: [Content]
    let systemInstruction: Content?
    let generationConfig: GenerationConfig?

    init(
        contents: [Content],
        systemInstruction: Content? = nil,
        generationConfig: GenerationConfig? = nil
    ) {
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.generationConfig = generationConfig
    }

    struct Content: Encodable {
        let role: String    // "user" | "model"
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    struct GenerationConfig: Encodable {
        let maxOutputTokens: Int?
    }
}
