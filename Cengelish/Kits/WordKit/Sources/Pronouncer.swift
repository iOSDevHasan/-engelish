import AVFoundation

/// Kelimeyi sesli okuyan servis.
@MainActor
public protocol Pronouncing: AnyObject {
  /// Metni verilen dilde (en-US / en-GB) okur.
  func speak(_ text: String, language: String)
}

/// AVSpeechSynthesizer ile cihazda telaffuz; ses dosyası indirmez.
@MainActor
public final class Pronouncer: Pronouncing {
  private let synthesizer = AVSpeechSynthesizer()

  /// Telaffuz servisini oluşturur.
  public init() {}

  public func speak(_ text: String, language: String) {
    try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
    synthesizer.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
    synthesizer.speak(utterance)
  }
}
