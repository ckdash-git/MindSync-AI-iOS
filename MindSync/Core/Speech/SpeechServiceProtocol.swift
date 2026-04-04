import Combine

enum SpeechRecordingError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        "Speech recognition is not available on this device or for the current language."
    }
}

protocol SpeechServiceProtocol: AnyObject {

    /// True while the microphone is active and audio is being transcribed.
    var isRecording: Bool { get }

    /// The most recent partial or final transcription from the current recording session.
    var transcript: String { get }

    /// True while the synthesizer is speaking an AI response.
    var isSpeaking: Bool { get }

    /// True when both microphone and speech recognition permissions have been granted.
    var isAvailable: Bool { get }

    /// Fires whenever any of the above properties change, allowing observers to refresh.
    var statePublisher: AnyPublisher<Void, Never> { get }

    /// Requests NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription permissions.
    /// Returns true only when both are granted.
    func requestPermissions() async -> Bool

    /// Starts live recording and transcription. Throws if the audio engine cannot start.
    func startRecording() throws

    /// Stops the current recording session. Call `transcript` afterwards to read the result.
    func stopRecording()

    /// Speaks `text` aloud via AVSpeechSynthesizer, cancelling any in-progress speech first.
    func speak(_ text: String)

    /// Immediately stops any in-progress speech.
    func stopSpeaking()
}
