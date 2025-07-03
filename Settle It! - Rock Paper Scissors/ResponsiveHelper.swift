import SwiftUI

// MARK: - Device Type Detection
enum DeviceType {
    case phone      // iPhone'lar
    case padCompact // iPad Mini, iPad (küçük)
    case padRegular // iPad Pro, iPad Air (büyük)
    
    static var current: DeviceType {
        let screen = UIScreen.main.bounds
        let minDimension = min(screen.width, screen.height)
        
        // iPhone boyutları (en küçük boyut 375 ve altı genellikle telefon)
        if minDimension <= 428 { // iPhone 14 Pro Max bile 428
            return .phone
        }
        // iPad Mini ve küçük iPad'ler (768-834 arası)
        else if minDimension <= 834 {
            return .padCompact
        }
        // iPad Pro ve büyük iPad'ler
        else {
            return .padRegular
        }
    }
}

// MARK: - Screen Size Helper
struct ScreenSize {
    static var width: CGFloat { UIScreen.main.bounds.width }
    static var height: CGFloat { UIScreen.main.bounds.height }
    static var minDimension: CGFloat { min(width, height) }
    static var maxDimension: CGFloat { max(width, height) }
    
    // Safe area insets
    static var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.top ?? 0
    }
    
    static var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Responsive Spacing (Küçültüldü)
struct ResponsiveSpacing {
    static var tiny: CGFloat {
        switch DeviceType.current {
        case .phone: return 2
        case .padCompact: return 3
        case .padRegular: return 4
        }
    }
    
    static var small: CGFloat {
        switch DeviceType.current {
        case .phone: return 6
        case .padCompact: return 8
        case .padRegular: return 10
        }
    }
    
    static var medium: CGFloat {
        switch DeviceType.current {
        case .phone: return 12
        case .padCompact: return 14
        case .padRegular: return 16
        }
    }
    
    static var large: CGFloat {
        switch DeviceType.current {
        case .phone: return 18
        case .padCompact: return 22
        case .padRegular: return 26
        }
    }
    
    static var extraLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 24
        case .padCompact: return 28
        case .padRegular: return 32
        }
    }
    
    static var huge: CGFloat {
        switch DeviceType.current {
        case .phone: return 30
        case .padCompact: return 35
        case .padRegular: return 40
        }
    }
}

// MARK: - Responsive Padding (Küçültüldü)
struct ResponsivePadding {
    static var horizontal: CGFloat {
        switch DeviceType.current {
        case .phone: return 16
        case .padCompact: return 24
        case .padRegular: return 32
        }
    }
    
    static var vertical: CGFloat {
        switch DeviceType.current {
        case .phone: return 12
        case .padCompact: return 16
        case .padRegular: return 20
        }
    }
    
    static var content: CGFloat {
        switch DeviceType.current {
        case .phone: return 16
        case .padCompact: return 18
        case .padRegular: return 20
        }
    }
}

// MARK: - Responsive Sizes (Küçültüldü)
struct ResponsiveSize {
    // Avatar boyutları (küçültüldü)
    static var avatarSmall: CGFloat {
        switch DeviceType.current {
        case .phone: return 32
        case .padCompact: return 36
        case .padRegular: return 40
        }
    }
    
    static var avatarMedium: CGFloat {
        switch DeviceType.current {
        case .phone: return 44
        case .padCompact: return 50
        case .padRegular: return 56
        }
    }
    
    static var avatarLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 56
        case .padCompact: return 64
        case .padRegular: return 72
        }
    }
    
    static var avatarExtraLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 80
        case .padCompact: return 90
        case .padRegular: return 100
        }
    }
    
    // Icon boyutları (küçültüldü)
    static var iconSmall: CGFloat {
        switch DeviceType.current {
        case .phone: return 16
        case .padCompact: return 18
        case .padRegular: return 20
        }
    }
    
    static var iconMedium: CGFloat {
        switch DeviceType.current {
        case .phone: return 20
        case .padCompact: return 22
        case .padRegular: return 24
        }
    }
    
    static var iconLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 24
        case .padCompact: return 28
        case .padRegular: return 32
        }
    }
    
    // Button boyutları
    static var buttonHeight: CGFloat {
        switch DeviceType.current {
        case .phone: return 44
        case .padCompact: return 48
        case .padRegular: return 52
        }
    }
    
    static var buttonHeightLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 50
        case .padCompact: return 56
        case .padRegular: return 62
        }
    }
    
    // Card boyutları
    static var cardCornerRadius: CGFloat {
        switch DeviceType.current {
        case .phone: return 12
        case .padCompact: return 14
        case .padRegular: return 16
        }
    }
    
    static var cardCornerRadiusLarge: CGFloat {
        switch DeviceType.current {
        case .phone: return 16
        case .padCompact: return 18
        case .padRegular: return 20
        }
    }
    
    // Countdown circle size (küçültüldü)
    static var countdownCircle: CGFloat {
        switch DeviceType.current {
        case .phone: return 120
        case .padCompact: return 140
        case .padRegular: return 160
        }
    }
}

// MARK: - Responsive Font Sizes (Küçültüldü ve Daha Dengeli)
struct ResponsiveFont {
    static var largeTitle: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 28, relativeTo: .largeTitle)
        case .padCompact: return .custom("System", size: 32, relativeTo: .largeTitle)
        case .padRegular: return .custom("System", size: 36, relativeTo: .largeTitle)
        }
    }
    
    static var title: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 22, relativeTo: .title)
        case .padCompact: return .custom("System", size: 26, relativeTo: .title)
        case .padRegular: return .custom("System", size: 30, relativeTo: .title)
        }
    }
    
    static var title2: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 20, relativeTo: .title2)
        case .padCompact: return .custom("System", size: 22, relativeTo: .title2)
        case .padRegular: return .custom("System", size: 24, relativeTo: .title2)
        }
    }
    
    static var title3: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 18, relativeTo: .title3)
        case .padCompact: return .custom("System", size: 20, relativeTo: .title3)
        case .padRegular: return .custom("System", size: 22, relativeTo: .title3)
        }
    }
    
    static var headline: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 16, relativeTo: .headline)
        case .padCompact: return .custom("System", size: 18, relativeTo: .headline)
        case .padRegular: return .custom("System", size: 20, relativeTo: .headline)
        }
    }
    
    static var body: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 16, relativeTo: .body)
        case .padCompact: return .custom("System", size: 17, relativeTo: .body)
        case .padRegular: return .custom("System", size: 18, relativeTo: .body)
        }
    }
    
    static var callout: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 15, relativeTo: .callout)
        case .padCompact: return .custom("System", size: 16, relativeTo: .callout)
        case .padRegular: return .custom("System", size: 17, relativeTo: .callout)
        }
    }
    
    static var subheadline: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 14, relativeTo: .subheadline)
        case .padCompact: return .custom("System", size: 15, relativeTo: .subheadline)
        case .padRegular: return .custom("System", size: 16, relativeTo: .subheadline)
        }
    }
    
    static var footnote: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 12, relativeTo: .footnote)
        case .padCompact: return .custom("System", size: 13, relativeTo: .footnote)
        case .padRegular: return .custom("System", size: 14, relativeTo: .footnote)
        }
    }
    
    static var caption: Font {
        switch DeviceType.current {
        case .phone: return .custom("System", size: 11, relativeTo: .caption)
        case .padCompact: return .custom("System", size: 12, relativeTo: .caption)
        case .padRegular: return .custom("System", size: 13, relativeTo: .caption)
        }
    }
    
    // Emoji font sizes (önemli ölçüde küçültüldü)
    static func emoji(size: EmojiSize) -> Font {
        switch (DeviceType.current, size) {
        case (.phone, .small): return .system(size: 24)
        case (.phone, .medium): return .system(size: 36)
        case (.phone, .large): return .system(size: 48)
        case (.padCompact, .small): return .system(size: 28)
        case (.padCompact, .medium): return .system(size: 42)
        case (.padCompact, .large): return .system(size: 56)
        case (.padRegular, .small): return .system(size: 32)
        case (.padRegular, .medium): return .system(size: 48)
        case (.padRegular, .large): return .system(size: 64)
        }
    }
}

enum EmojiSize {
    case small, medium, large
}

// MARK: - Responsive Layout Helper
struct ResponsiveContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    content
                        .padding(.horizontal, ResponsivePadding.horizontal)
                        .padding(.top, ResponsivePadding.vertical)
                        .frame(minHeight: geometry.size.height - ResponsivePadding.vertical)
                }
            }
        }
    }
}

// MARK: - Grid Columns Helper
struct ResponsiveGrid {
    static func columns(minItemWidth: CGFloat, spacing: CGFloat = ResponsiveSpacing.medium) -> [GridItem] {
        let availableWidth = ScreenSize.width - (ResponsivePadding.horizontal * 2)
        let numberOfColumns = max(1, Int(availableWidth / (minItemWidth + spacing)))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfColumns)
    }
    
    static var avatarColumns: [GridItem] {
        switch DeviceType.current {
        case .phone: return Array(repeating: GridItem(.flexible()), count: 6)
        case .padCompact: return Array(repeating: GridItem(.flexible()), count: 8)
        case .padRegular: return Array(repeating: GridItem(.flexible()), count: 10)
        }
    }
    
    static var playerColumns: [GridItem] {
        switch DeviceType.current {
        case .phone: return Array(repeating: GridItem(.flexible()), count: 2)
        case .padCompact: return Array(repeating: GridItem(.flexible()), count: 3)
        case .padRegular: return Array(repeating: GridItem(.flexible()), count: 4)
        }
    }
}

// MARK: - Responsive ViewModifiers
struct ResponsiveCardStyle: ViewModifier {
    let backgroundColor: Color
    let borderColor: Color
    
    init(backgroundColor: Color = Color.white.opacity(0.15), borderColor: Color = Color.white.opacity(0.2)) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }
    
    func body(content: Content) -> some View {
        content
            .padding(ResponsivePadding.content)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
    }
}

struct ResponsiveButtonStyle: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(backgroundColor: Color = .blue, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .font(ResponsiveFont.headline)
            .foregroundColor(foregroundColor)
            .frame(minHeight: ResponsiveSize.buttonHeight)
            .padding(.horizontal, ResponsivePadding.content)
            .background(
                RoundedRectangle(cornerRadius: ResponsiveSize.cardCornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
    }
}

// ViewModifier extension'ları
extension View {
    func responsiveCard(backgroundColor: Color = Color.white.opacity(0.15), borderColor: Color = Color.white.opacity(0.2)) -> some View {
        self.modifier(ResponsiveCardStyle(backgroundColor: backgroundColor, borderColor: borderColor))
    }
    
    func responsiveButton(backgroundColor: Color = .blue, foregroundColor: Color = .white) -> some View {
        self.modifier(ResponsiveButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}

// MARK: - Responsive Animation Helper
struct ResponsiveAnimation {
    static var `default`: Animation {
        switch DeviceType.current {
        case .phone: return .spring(response: 0.6, dampingFraction: 0.8)
        case .padCompact: return .spring(response: 0.7, dampingFraction: 0.8)
        case .padRegular: return .spring(response: 0.8, dampingFraction: 0.8)
        }
    }
    
    static var fast: Animation {
        switch DeviceType.current {
        case .phone: return .spring(response: 0.3, dampingFraction: 0.7)
        case .padCompact: return .spring(response: 0.4, dampingFraction: 0.7)
        case .padRegular: return .spring(response: 0.5, dampingFraction: 0.7)
        }
    }
    
    static var slow: Animation {
        switch DeviceType.current {
        case .phone: return .spring(response: 0.8, dampingFraction: 0.8)
        case .padCompact: return .spring(response: 0.9, dampingFraction: 0.8)
        case .padRegular: return .spring(response: 1.0, dampingFraction: 0.8)
        }
    }
}
