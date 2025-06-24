import Foundation

// MARK: - Network Message
/// Cihazlar arasında gönderilecek mesajları tanımlayan ana enum
/// MultipeerConnectivity framework'ü ile Data formatına çevrilerek gönderilir
enum NetworkMessage: Codable {
    case vote(mode: GameMode) // Bir oyuncunun oyun modu için oyunu
    case choice(selection: Choice) // Bir oyuncunun tur içindeki seçimi
}
