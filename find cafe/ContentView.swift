import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Foundation
import Combine
import Contacts

// =======================================================
// CafeFinder (Single Paste) - iOS 17+ / SwiftUI / MapKit
// ✅ 하이브리드: MapKit(근처 정확) + Naver(지점명/링크/주소 보강)
// ✅ 브랜드 칩: 로컬 필터만(버퍼링 0)
// ✅ 더 부드럽게: 무거운 작업을 백그라운드로 + 재검색 연타 시 이전 작업 취소
// ✅ UI/UX 프리미엄 브랜드화 v1 (토큰/카드/버튼 통일)
//
// ⚠️ Info.plist 필수
// 1) NSLocationWhenInUseUsageDescription 추가
// 2) LSApplicationQueriesSchemes (Array) 추가 후 "nmap" 추가 (canOpenURL용)
// =======================================================


// MARK: - Brand Tokens (Premium)

enum UIX {

    // Shape
    static let corner: CGFloat = 16
    static let cornerSmall: CGFloat = 12
    static let cornerLarge: CGFloat = 24

    // Spacing
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20

    // Design tokens from the supplied Cafe Finder mockup
    static var pageTop: Color { Color(light: 0xF8FAFC, dark: 0x020617) }
    static var pageMid: Color { Color(light: 0xEFF6FF, dark: 0x0B1220) }
    static var pageBottom: Color { Color(light: 0xF1F5F9, dark: 0x111827) }
    static var card: Color { Color(light: 0xFFFFFF, dark: 0x111827) }
    static var cardElevated: Color { Color(light: 0xFFFFFF, dark: 0x172033) }
    static var mapOverlay: Color { Color(light: 0xFFFFFF, dark: 0x0F172A, lightOpacity: 0.92, darkOpacity: 0.88) }
    static var mapScrim: Color { Color(light: 0xFFFFFF, dark: 0x000000, lightOpacity: 0.22, darkOpacity: 0.30) }
    static var pinCore: Color { Color(light: 0xFFFFFF, dark: 0xE2E8F0) }
    static var slate50: Color { Color(light: 0xF8FAFC, dark: 0x1E293B) }
    static var slate100: Color { Color(light: 0xF1F5F9, dark: 0x243244) }
    static var slate200: Color { Color(light: 0xE2E8F0, dark: 0x334155) }
    static var slate400: Color { Color(light: 0x94A3B8, dark: 0x94A3B8) }
    static var slate500: Color { Color(light: 0x64748B, dark: 0x94A3B8) }
    static var slate600: Color { Color(light: 0x475569, dark: 0xCBD5E1) }
    static var slate700: Color { Color(light: 0x334155, dark: 0xE2E8F0) }
    static var slate900: Color { Color(light: 0x0F172A, dark: 0xF8FAFC) }
    static var blue50: Color { Color(light: 0xF3F7FB, dark: 0x172033) }
    static var blue100: Color { Color(light: 0xE6EEF7, dark: 0x22324A) }
    static var blue500: Color { Color(light: 0x557FA8, dark: 0x7FA6C9) }
    static var blue600: Color { Color(light: 0x315E8A, dark: 0x5F84AA) }
    static var blue700: Color { Color(light: 0x223A5E, dark: 0x425F83) }
    static var amber500: Color { Color(light: 0xB58A2B, dark: 0xD2AA5B) }
    static var orange500: Color { Color(light: 0x9A623C, dark: 0xC08355) }
    static var green500: Color { Color(light: 0x3F7D5A, dark: 0x6FA883) }
    static var violet500: Color { Color(light: 0x6E628A, dark: 0x9A8FB4) }

    // Surface
    static func surface(_ isOnMap: Bool = false) -> some ShapeStyle {
        isOnMap ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.thinMaterial)
    }
    static func stroke() -> Color { slate200 }
    static func shadow(_ strong: Bool = false) -> Color {
        Color(light: 0x000000, dark: 0x000000, lightOpacity: strong ? 0.14 : 0.08, darkOpacity: strong ? 0.40 : 0.28)
    }
    static var pageGradient: LinearGradient {
        LinearGradient(
            colors: [pageTop, pageMid, pageBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [Color(light: 0x111827, dark: 0x0F172A), Color(light: 0x355C7D, dark: 0x263B55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Fonts
    static func title() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func subtitle() -> Font { .system(size: 13, weight: .semibold, design: .rounded) }

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    init(light: UInt32, dark: UInt32, lightOpacity: Double = 1, darkOpacity: Double = 1) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            let opacity = traits.userInterfaceStyle == .dark ? darkOpacity : lightOpacity
            let red = CGFloat((hex >> 16) & 0xFF) / 255
            let green = CGFloat((hex >> 8) & 0xFF) / 255
            let blue = CGFloat(hex & 0xFF) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: opacity)
        })
    }
}


// MARK: - Brand Components

struct BrandCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(UIX.card)
            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous)
                    .stroke(UIX.slate100, lineWidth: 1)
            )
            .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
    }
}
extension View {
    func brandCard() -> some View { modifier(BrandCard()) }
}

struct BrandIconButton: ViewModifier {
    var size: CGFloat = 44
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(UIX.card)
            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                    .stroke(UIX.slate200, lineWidth: 1)
            )
            .shadow(color: UIX.shadow(true), radius: 12, x: 0, y: 8)
    }
}
extension View {
    func brandIconButton(_ size: CGFloat = 44) -> some View {
        modifier(BrandIconButton(size: size))
    }
}


// MARK: - Favorites (AppStorage 기반)

final class FavoritesStore: ObservableObject {
    @AppStorage("CafeFinder.favorites") private var raw: String = ""
    @Published private(set) var ids: Set<String> = []

    init() { ids = Set(raw.split(separator: "|").map(String.init)) }

    func contains(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        raw = ids.joined(separator: "|")
        objectWillChange.send()
    }
}


// MARK: - Open Naver Map (앱 우선, 없으면 웹)

private func openNaverMapSearch(query: String) {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return }

    let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
    let appName = Bundle.main.bundleIdentifier ?? "com.example.app"

    // 1) 네이버지도 앱 딥링크
    if let appURL = URL(string: "nmap://search?query=\(encoded)&appname=\(appName)"),
       UIApplication.shared.canOpenURL(appURL) {
        UIApplication.shared.open(appURL)
        return
    }

    // 2) 폴백: 네이버 지도 웹 (검색 화면)
    if let webURL = URL(string: "https://map.naver.com/v5/search/\(encoded)") {
        UIApplication.shared.open(webURL)
    }
}


// MARK: - CafeBG (Swift 6 경고 회피용 nonisolated 유틸)

enum CafeBG {

    nonisolated static func buildNaverQuery(brand: CafeBrand, anchor: Anchor, regionKeyword: String?) -> String {
        if anchor.name != "내 위치" { return "\(brand.baseQuery) \(anchor.name)" }
        if let regionKeyword, !regionKeyword.isEmpty { return "\(brand.baseQuery) \(regionKeyword)" }
        return brand.baseQuery
    }

    nonisolated static func stripNaverTitle(_ s: String) -> String {
        s.replacingOccurrences(of: "<b>", with: "")
            .replacingOccurrences(of: "</b>", with: "")
    }

    nonisolated static func wgs84Coord(mapx: String, mapy: String) -> CLLocationCoordinate2D? {
        guard let x = Double(mapx), let y = Double(mapy) else { return nil }
        return CLLocationCoordinate2D(latitude: y / 1e7, longitude: x / 1e7)
    }

    nonisolated static func normalizeName(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "점", with: "")
    }

    nonisolated static func brandFromName(_ name: String) -> CafeBrand? {
        let n = normalizeName(name)
        for b in CafeBrand.allCases {
            let ks = b.keywords.map { normalizeName($0) }
            if ks.contains(where: { n.contains($0) }) { return b }
        }
        return nil
    }

    // ✅ detached에서 CLLocation 쓰기 싫으면 순수 계산(Haversine)
    nonisolated static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let R = 6_371_000.0
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180

        let sinDLat = sin(dLat/2)
        let sinDLon = sin(dLon/2)

        let aa = sinDLat*sinDLat + cos(lat1)*cos(lat2)*sinDLon*sinDLon
        let c = 2 * atan2(sqrt(aa), sqrt(1-aa))
        return R * c
    }

    nonisolated static func dedupeKey(brand: CafeBrand, name: String, coord: CLLocationCoordinate2D) -> String {
        func r(_ v: Double) -> Double { (v * 1e5).rounded() / 1e5 }
        return "\(brand.rawValue)|\(normalizeName(name))|\(r(coord.latitude))|\(r(coord.longitude))"
    }

    nonisolated static func mergeCafe(exist: Cafe, incoming: Cafe, preferMapCoord: Bool) -> Cafe {
        let existLink = (exist.naverLink ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let newLink = (incoming.naverLink ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let finalName = incoming.name.count > exist.name.count ? incoming.name : exist.name
        let mergedAddr = exist.address.isEmpty ? incoming.address : exist.address
        let mergedRoad = exist.roadAddress.isEmpty ? incoming.roadAddress : exist.roadAddress
        let coord = preferMapCoord ? exist.coordinate : incoming.coordinate
        let dist = min(exist.distanceMeters, incoming.distanceMeters)

        let link: String?
        if !existLink.isEmpty { link = existLink }
        else if !newLink.isEmpty { link = newLink }
        else { link = nil }

        return Cafe(
            id: exist.id,
            name: finalName,
            address: mergedAddr,
            roadAddress: mergedRoad,
            coordinate: coord,
            brand: exist.brand,
            distanceMeters: dist,
            naverLink: link
        )
    }

    nonisolated static func findNearbyDuplicate(in map: [String: Cafe], candidate: Cafe, mergeDistanceMeters: Double) -> String? {
        for (key, exist) in map {
            guard exist.brand == candidate.brand else { continue }
            let d = distanceMeters(from: exist.coordinate, to: candidate.coordinate)
            if d <= mergeDistanceMeters { return key }
        }
        return nil
    }
}


// MARK: - Secrets

enum Secrets {
    static var naverClientId: String { value(for: "NAVER_CLIENT_ID") }
    static var naverClientSecret: String { value(for: "NAVER_CLIENT_SECRET") }

    private static func value(for key: String) -> String {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return "" }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.hasPrefix("YOUR_") ? "" : value
    }
}


// MARK: - Models

enum CafeBrand: String, CaseIterable, Identifiable, Hashable {
    case compose = "컴포즈"
    case mega = "메가"
    case twosome = "투썸"
    case starbucks = "스타벅스"
    case ediya = "이디야"

    var id: String { rawValue }

    nonisolated var baseQuery: String {
        switch self {
        case .compose: return "컴포즈커피"
        case .mega: return "메가커피"
        case .twosome: return "투썸플레이스"
        case .starbucks: return "스타벅스"
        case .ediya: return "이디야커피"
        }
    }

    nonisolated var keywords: [String] {
        switch self {
        case .compose: return ["컴포즈", "compose"]
        case .mega: return ["메가", "mgc", "mega", "megacoffee"]
        case .twosome: return ["투썸", "twosome"]
        case .starbucks: return ["스타벅스", "starbucks"]
        case .ediya: return ["이디야", "ediya"]
        }
    }
}

extension CafeBrand {
    static var displayOrder: [CafeBrand] {
        [.starbucks, .mega, .ediya, .compose, .twosome]
    }

    var chipTitle: String {
        switch self {
        case .compose: return "컴포즈"
        case .mega: return "메가커피"
        case .twosome: return "투썸"
        case .starbucks: return "스타벅스"
        case .ediya: return "이디야"
        }
    }

    var accentColor: Color {
        switch self {
        case .compose: return Color(light: 0x557FA8, dark: 0x7FA6C9)
        case .mega: return Color(light: 0xB58A2B, dark: 0xD2AA5B)
        case .twosome: return Color(light: 0xA8673F, dark: 0xC08355)
        case .starbucks: return Color(light: 0x3F7D5A, dark: 0x6FA883)
        case .ediya: return Color(light: 0xA65A5A, dark: 0xC78282)
        }
    }

    var accentDarkColor: Color {
        switch self {
        case .compose: return Color(light: 0x315E8A, dark: 0x5F84AA)
        case .mega: return Color(light: 0x8A6A2B, dark: 0xA98745)
        case .twosome: return Color(light: 0x7F4A32, dark: 0x9B6342)
        case .starbucks: return Color(light: 0x2F684A, dark: 0x4F8568)
        case .ediya: return Color(light: 0x80464D, dark: 0xA36468)
        }
    }

    var softGradientColors: [Color] {
        switch self {
        case .compose:
            return [Color(light: 0xF4F7FA, dark: 0x172033), Color(light: 0xE8EFF6, dark: 0x1D2B3E)]
        case .mega:
            return [Color(light: 0xF8F3E5, dark: 0x221F18), Color(light: 0xF1E8D0, dark: 0x2B261A)]
        case .twosome:
            return [Color(light: 0xF8EFE7, dark: 0x241B18), Color(light: 0xF1E3D7, dark: 0x2E211C)]
        case .starbucks:
            return [Color(light: 0xEEF5F0, dark: 0x17231D), Color(light: 0xDFEBE3, dark: 0x1D2C24)]
        case .ediya:
            return [Color(light: 0xF7EEEE, dark: 0x24191C), Color(light: 0xEEDCDC, dark: 0x2E2023)]
        }
    }

    var strongGradientColors: [Color] {
        [accentColor, accentDarkColor]
    }
}

struct BrandCount: Identifiable, Hashable {
    let brand: CafeBrand
    let count: Int
    var id: CafeBrand { brand }
}

struct Cafe: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let roadAddress: String
    let coordinate: CLLocationCoordinate2D
    let brand: CafeBrand
    let distanceMeters: Double
    let naverLink: String?

    var distanceText: String {
        if distanceMeters >= 1000 {
            return String(format: "%.1fkm", distanceMeters / 1000.0)
        } else {
            return String(format: "%.0fm", distanceMeters)
        }
    }

    var displayAddress: String {
        let r = roadAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return r.isEmpty ? address : r
    }

    var mapSearchQuery: String {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = displayAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if n.isEmpty { return brand.baseQuery }
        if a.isEmpty { return n }
        return "\(n) \(a)"
    }

    static func == (lhs: Cafe, rhs: Cafe) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum AnchorMode: String, CaseIterable, Identifiable {
    case myLocation = "내 위치"
    case customPlace = "선택 장소"
    var id: String { rawValue }
}

struct Anchor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: Anchor, rhs: Anchor) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}


// MARK: - Location Manager

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var locationError: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermissionAndStart() {
        locationError = nil
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            locationError = "위치 권한이 필요해요. 설정에서 권한을 허용해 주세요."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        if location != nil { manager.stopUpdatingLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "위치 가져오기 실패: \(error.localizedDescription)"
    }
}


// MARK: - Naver Local Search Service

final class NaverLocalSearchService {
    private let clientId: String
    private let clientSecret: String

    init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    func search(query: String, display: Int = 5, start: Int = 1, sort: String = "comment") async throws -> [NaverItem] {
        var comps = URLComponents(string: "https://openapi.naver.com/v1/search/local.json")!
        comps.queryItems = [
            .init(name: "query", value: query),
            .init(name: "display", value: "\(min(display, 5))"),
            .init(name: "start", value: "\(start)"),
            .init(name: "sort", value: sort)
        ]

        let cid = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let csec = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

        var req = URLRequest(url: comps.url!)
        req.setValue(cid, forHTTPHeaderField: "X-Naver-Client-Id")
        req.setValue(csec, forHTTPHeaderField: "X-Naver-Client-Secret")
        req.timeoutInterval = 10

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw NSError(domain: "NaverAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP 응답이 아니에요"])
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw NSError(
                domain: "NaverAPI",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Naver API 오류(\(http.statusCode))\n\(body)"]
            )
        }

        return try JSONDecoder().decode(NaverLocalResponse.self, from: data).items
    }
}

private struct NaverLocalResponse: Decodable {
    let items: [NaverItem]
}

struct NaverItem: Decodable, Hashable {
    let title: String
    let link: String?
    let category: String?
    let description: String?
    let telephone: String?
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String
}


// MARK: - ViewModel

final class CafeFinderViewModel: ObservableObject {

    @Published var selectedBrands: Set<CafeBrand> = []
    @Published private(set) var cafes: [Cafe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var allCafes: [Cafe] = []
    private let naver: NaverLocalSearchService
    private var reloadTask: Task<Void, Never>?

    private let maxDistanceMeters: Double = 10_000
    private let pagesPerBrand = 2
    private let pageSize = 5
    private let sort = "comment"
    private let perRequestDelayNs: UInt64 = 150_000_000
    private let mergeDistanceMeters: Double = 120

    private let enrichMaxCount = 14
    private let enrichMatchMeters: Double = 220
    private let enrichDelayNs: UInt64 = 180_000_000

    init(naver: NaverLocalSearchService) {
        self.naver = naver
    }

    func applyFilter(animated: Bool = true) {
        let filtered: [Cafe]
        if selectedBrands.isEmpty { filtered = allCafes }
        else { filtered = allCafes.filter { selectedBrands.contains($0.brand) } }

        let sorted = filtered.sorted { $0.distanceMeters < $1.distanceMeters }

        if animated {
            withAnimation(.snappy(duration: 0.18)) { self.cafes = sorted }
        } else {
            self.cafes = sorted
        }
    }

    func reload(anchor: Anchor, silent: Bool = false) {
        reloadTask?.cancel()

        errorMessage = nil
        if !silent { isLoading = true }

        let naver = self.naver
        let maxDistanceMeters = self.maxDistanceMeters
        let pagesPerBrand = self.pagesPerBrand
        let pageSize = self.pageSize
        let sort = self.sort
        let perRequestDelayNs = self.perRequestDelayNs
        let mergeDistanceMeters = self.mergeDistanceMeters
        let enrichMaxCount = self.enrichMaxCount
        let enrichMatchMeters = self.enrichMatchMeters
        let enrichDelayNs = self.enrichDelayNs

        reloadTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            do {
                let brandsToSearch = CafeBrand.allCases

                let regionKeyword: String? = (anchor.name == "내 위치")
                ? await makeRegionKeyword_static(from: anchor.coordinate)
                : nil

                // 1) MapKit 근처 검색
                var map: [String: Cafe] = [:]
                map.reserveCapacity(brandsToSearch.count * 25)

                for brand in brandsToSearch {
                    try Task.checkCancellation()
                    let near = await searchNearbyWithMapKit_static(brand: brand, anchor: anchor)
                    for cafe in near where cafe.distanceMeters <= maxDistanceMeters {
                        map[cafe.id] = cafe
                    }
                }

                // 1.5) 브랜드명-only 보강
                try Task.checkCancellation()
                await enrichGenericStoreNamesWithNaver_static(
                    map: &map,
                    anchor: anchor,
                    naver: naver,
                    enrichMaxCount: enrichMaxCount,
                    enrichMatchMeters: enrichMatchMeters,
                    enrichDelayNs: enrichDelayNs
                )

                // 2) 네이버 보강 + dedupe
                for brand in brandsToSearch {
                    try Task.checkCancellation()

                    let q = CafeBG.buildNaverQuery(brand: brand, anchor: anchor, regionKeyword: regionKeyword)

                    for p in 0..<pagesPerBrand {
                        try Task.checkCancellation()

                        let start = 1 + p * pageSize
                        let items = try await naver.search(query: q, display: pageSize, start: start, sort: sort)

                        for item in items {
                            try Task.checkCancellation()

                            let name = CafeBG.stripNaverTitle(item.title)
                            guard let coord = CafeBG.wgs84Coord(mapx: item.mapx, mapy: item.mapy) else { continue }

                            if let detected = CafeBG.brandFromName(name), detected != brand { continue }

                            let dist = CafeBG.distanceMeters(from: anchor.coordinate, to: coord)
                            guard dist <= maxDistanceMeters else { continue }

                            let key = CafeBG.dedupeKey(brand: brand, name: name, coord: coord)

                            let naverCafe = Cafe(
                                id: key,
                                name: name,
                                address: item.address,
                                roadAddress: item.roadAddress,
                                coordinate: coord,
                                brand: brand,
                                distanceMeters: dist,
                                naverLink: item.link
                            )

                            if let exist = map[key] {
                                map[key] = CafeBG.mergeCafe(exist: exist, incoming: naverCafe, preferMapCoord: true)
                            } else if let dupKey = CafeBG.findNearbyDuplicate(in: map, candidate: naverCafe, mergeDistanceMeters: mergeDistanceMeters) {
                                let exist = map[dupKey]!
                                map[dupKey] = CafeBG.mergeCafe(exist: exist, incoming: naverCafe, preferMapCoord: true)
                            } else {
                                map[key] = naverCafe
                            }
                        }

                        try? await Task.sleep(nanoseconds: perRequestDelayNs)
                    }
                }

                try Task.checkCancellation()

                let all = Array(map.values).sorted { $0.distanceMeters < $1.distanceMeters }

                await MainActor.run {
                    if Task.isCancelled { return }
                    self.allCafes = all
                    self.isLoading = false
                    self.errorMessage = all.isEmpty ? "근처 결과가 적어요. 기준 장소를 바꾸거나 반경을 늘려보세요." : nil
                    self.applyFilter(animated: true)
                }

            } catch {
                await MainActor.run {
                    if Task.isCancelled { return }
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}


// MARK: - Static helpers for background work

private func searchNearbyWithMapKit_static(brand: CafeBrand, anchor: Anchor) async -> [Cafe] {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = brand.baseQuery
    request.region = MKCoordinateRegion(
        center: anchor.coordinate,
        span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
    )

    do {
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { item in
            let name = item.name ?? brand.baseQuery
            if let detected = CafeBG.brandFromName(name), detected != brand { return nil }

            let coord = item.location.coordinate
            let dist = CafeBG.distanceMeters(from: anchor.coordinate, to: coord)
            let short = item.address?.shortAddress ?? ""
            let key = CafeBG.dedupeKey(brand: brand, name: name, coord: coord)

            return Cafe(
                id: key,
                name: name,
                address: short,
                roadAddress: short,
                coordinate: coord,
                brand: brand,
                distanceMeters: dist,
                naverLink: nil
            )
        }
    } catch {
        return []
    }
}

private func makeRegionKeyword_static(from coord: CLLocationCoordinate2D) async -> String? {
    let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    do {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try await request.mapItems
        guard let item = items.first else { return nil }

        if let short = item.address?.shortAddress, !short.isEmpty,
           let token = extractKoreanAreaToken_static(from: short) {
            return token
        }

        if let rep = item.addressRepresentations {
            let candidates = [rep.cityWithContext, rep.regionName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            for c in candidates {
                if let token = extractKoreanAreaToken_static(from: c) { return token }
            }
        }

        return nil
    } catch {
        return nil
    }
}

private func extractKoreanAreaToken_static(from s: String) -> String? {
    let tokens = s
        .replacingOccurrences(of: ",", with: " ")
        .replacingOccurrences(of: "·", with: " ")
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)

    if let dong = tokens.last(where: { $0.hasSuffix("동") || $0.hasSuffix("읍") || $0.hasSuffix("면") }) { return dong }
    if let gu = tokens.last(where: { $0.hasSuffix("구") || $0.hasSuffix("군") }) { return gu }
    if let si = tokens.last(where: { $0.hasSuffix("시") }) { return si }
    return nil
}

private func isGenericBrandOnlyName_static(_ name: String, brand: CafeBrand) -> Bool {
    let n = normalizeStoreName_static(name)
    let b1 = normalizeStoreName_static(brand.baseQuery)
    let b2 = normalizeStoreName_static(brand.rawValue)
    if n == b1 || n == b2 { return true }
    if n.count <= b1.count + 1 { return true }
    return false
}

private func bestHintToken_static(for cafe: Cafe, anchor: Anchor) -> String {
    let src = [cafe.roadAddress, cafe.address, (anchor.name == "내 위치" ? "" : anchor.name)]
        .joined(separator: " ")
    if let t = extractBestLocalToken_static(from: src) { return t }
    if anchor.name != "내 위치" { return anchor.name }
    return ""
}

private func extractBestLocalToken_static(from s: String) -> String? {
    let tokens = s
        .replacingOccurrences(of: ",", with: " ")
        .replacingOccurrences(of: "·", with: " ")
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)
        .filter { !$0.isEmpty }

    if let station = tokens.first(where: { $0.hasSuffix("역") }) { return station }
    if let dong = tokens.first(where: { $0.hasSuffix("동") || $0.hasSuffix("읍") || $0.hasSuffix("면") }) { return dong }
    if let road = tokens.first(where: { $0.hasSuffix("대로") || $0.hasSuffix("로") || $0.hasSuffix("길") || $0.hasSuffix("번길") }) { return road }
    if let gu = tokens.first(where: { $0.hasSuffix("구") || $0.hasSuffix("군") }) { return gu }
    return nil
}

private func enrichGenericStoreNamesWithNaver_static(
    map: inout [String: Cafe],
    anchor: Anchor,
    naver: NaverLocalSearchService,
    enrichMaxCount: Int,
    enrichMatchMeters: Double,
    enrichDelayNs: UInt64
) async {
    let targets = map.values
        .sorted { $0.distanceMeters < $1.distanceMeters }
        .filter { isGenericBrandOnlyName_static($0.name, brand: $0.brand) }
        .prefix(enrichMaxCount)

    for cafe in targets {
        if Task.isCancelled { return }

        let hint = bestHintToken_static(for: cafe, anchor: anchor)
        let q = hint.isEmpty ? cafe.brand.baseQuery : "\(cafe.brand.baseQuery) \(hint)"

        do {
            let items = try await naver.search(query: q, display: 5, start: 1, sort: "comment")

            var best: (item: NaverItem, dist: Double)?
            for item in items {
                guard let coord = CafeBG.wgs84Coord(mapx: item.mapx, mapy: item.mapy) else { continue }
                let d = CafeBG.distanceMeters(from: cafe.coordinate, to: coord)
                guard d <= enrichMatchMeters else { continue }
                if best == nil || d < best!.dist { best = (item, d) }
            }

            if let best {
                let newName = CafeBG.stripNaverTitle(best.item.title)
                if !isGenericBrandOnlyName_static(newName, brand: cafe.brand) {
                    let improved = Cafe(
                        id: cafe.id,
                        name: newName,
                        address: cafe.address.isEmpty ? best.item.address : cafe.address,
                        roadAddress: cafe.roadAddress.isEmpty ? best.item.roadAddress : cafe.roadAddress,
                        coordinate: cafe.coordinate,
                        brand: cafe.brand,
                        distanceMeters: cafe.distanceMeters,
                        naverLink: (cafe.naverLink?.isEmpty == false) ? cafe.naverLink : best.item.link
                    )
                    map[cafe.id] = improved
                }
            }

            try? await Task.sleep(nanoseconds: enrichDelayNs)
        } catch {
            continue
        }
    }
}

private func normalizeStoreName_static(_ s: String) -> String {
    s.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: "점", with: "")
        .replacingOccurrences(of: "지점", with: "")
        .replacingOccurrences(of: "매장", with: "")
        .replacingOccurrences(of: "store", with: "")
        .replacingOccurrences(of: "megacoffee", with: "메가커피")
        .replacingOccurrences(of: "starbucks", with: "스타벅스")
        .replacingOccurrences(of: "ediya", with: "이디야")
        .replacingOccurrences(of: "twosome", with: "투썸")
        .replacingOccurrences(of: "mega", with: "메가")
        .replacingOccurrences(of: "compose", with: "컴포즈")
}


// MARK: - UI Pieces

struct BrandChips: View {
    @Binding var selected: Set<CafeBrand>
    let onChange: () -> Void
    private let columns = [
        GridItem(.adaptive(minimum: 82), spacing: 8, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            chip("전체", isOn: selected.isEmpty, colors: [UIX.slate500, UIX.slate600]) {
                selected.removeAll()
                UIX.haptic(.soft)
                onChange()
            }

            ForEach(CafeBrand.displayOrder) { brand in
                chip(brand.chipTitle, isOn: selected.contains(brand), colors: brand.strongGradientColors) {
                    if selected.contains(brand) { selected.remove(brand) }
                    else { selected.insert(brand) }
                    UIX.haptic(.soft)
                    onChange()
                }
            }
        }
    }

    private func chip(_ title: String, isOn: Bool, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isOn ? .white : UIX.slate700)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                        .fill(isOn ? AnyShapeStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(UIX.slate100))
                )
                .shadow(color: colors.last?.opacity(isOn ? 0.16 : 0) ?? .clear, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.18), value: isOn)
    }
}


// MARK: - Detail View

struct CafeDetailView: View {
    let cafe: Cafe
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false
    @State private var showNaverDirectionsSheet = false

    private func openInNaverMap() {
        openNaverMapSearch(query: cafe.mapSearchQuery)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(cafe.brand.rawValue)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.18))
                                    .clipShape(Capsule())

                                Text(cafe.name)
                                    .font(.system(size: 25, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Text(cafe.distanceText)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                        }

                        Text(cafe.displayAddress.isEmpty ? "주소 정보 없음" : cafe.displayAddress)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: cafe.brand.strongGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
                    .shadow(color: cafe.brand.accentColor.opacity(0.24), radius: 18, x: 0, y: 12)

                    VStack(spacing: 10) {
                        detailInfoRow("영업정보", "네이버지도에서 영업중/영업시간을 확인할 수 있어요.", "clock.badge.checkmark")
                        detailInfoRow("거리", cafe.distanceText, "figure.walk")
                        detailInfoRow("좌표", String(format: "%.5f, %.5f", cafe.coordinate.latitude, cafe.coordinate.longitude), "location")
                    }
                    .padding(18)
                    .background(UIX.card)
                    .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIX.corner, style: .continuous)
                            .stroke(UIX.slate100, lineWidth: 1)
                    )

                    Button { openInNaverMap() } label: {
                        Label("네이버지도에서 매장 확인", systemImage: "map")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .foregroundStyle(.white)
                            .background(LinearGradient(colors: [UIX.blue600, UIX.blue700], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                            .shadow(color: UIX.blue600.opacity(0.16), radius: 12, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 10) {
                    Button {
                        showNaverDirectionsSheet = true
                    } label: {
                        Label("길찾기", systemImage: "location.north.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(UIX.slate900)
                            .background(UIX.slate100)
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "이동 수단을 선택하세요",
                        isPresented: $showNaverDirectionsSheet,
                        titleVisibility: .visible
                    ) {
                        Button("차") { openDirectionsInNaverMap(mode: .driving) }
                        Button("도보") { openDirectionsInNaverMap(mode: .walking) }
                        Button("대중교통") { openDirectionsInNaverMap(mode: .transit) }
                        Button("취소", role: .cancel) { }
                    }

                    Menu {
                        Button("애플 지도 (차)") { openDirectionsInAppleMaps(mode: .driving) }
                        Button("애플 지도 (도보)") { openDirectionsInAppleMaps(mode: .walking) }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(UIX.slate700)
                            .frame(width: 44, height: 44)
                            .background(UIX.slate100)
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                    Menu {
                        Button { copyText(cafe.name) } label: {
                            Label("매장명 복사", systemImage: "textformat")
                        }
                        Button {
                            copyText(cafe.displayAddress.isEmpty ? cafe.address : cafe.displayAddress)
                        } label: {
                            Label("상세주소 복사", systemImage: "mappin.and.ellipse")
                        }
                    } label: {
                        Label(copied ? "복사됨!" : "복사", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(copied ? .white : UIX.slate700)
                            .background(copied ? UIX.green500 : UIX.slate100)
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(UIX.pageGradient.ignoresSafeArea())
            .navigationTitle("카페 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
        }
    }

    private func detailInfoRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(UIX.blue600)
                .frame(width: 30, height: 30)
                .background(UIX.blue50)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(UIX.slate900)
                Text(value)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(UIX.slate500)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Directions

    private enum DirectionsMode {
        case driving, walking, transit
        var appleDirFlag: String { self == .driving ? "d" : (self == .walking ? "w" : "r") }
        var naverRouteType: String { self == .driving ? "car" : (self == .walking ? "walk" : "public") }
    }

    private func openDirectionsInAppleMaps(mode: DirectionsMode) {
        let lat = cafe.coordinate.latitude
        let lon = cafe.coordinate.longitude
        let urlString = "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=\(mode.appleDirFlag)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func openDirectionsInNaverMap(mode: DirectionsMode) {
        let lat = cafe.coordinate.latitude
        let lon = cafe.coordinate.longitude

        let dnameRaw = cafe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let dname = dnameRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dnameRaw

        let appNameRaw = (Bundle.main.bundleIdentifier ?? "com.example.findcafe")
        let appName = appNameRaw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appNameRaw

        let scheme = "nmap://route/\(mode.naverRouteType)?dlat=\(lat)&dlng=\(lon)&dname=\(dname)&appname=\(appName)"

        if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        if let appStoreURL = URL(string: "https://apps.apple.com/app/id311867728") {
            UIApplication.shared.open(appStoreURL)
        }
    }

    private func copyText(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        UIPasteboard.general.string = t
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { copied = false }
    }
}


// MARK: - Anchor Picker

struct AnchorPickerView: View {
    let initialRegionCenter: CLLocationCoordinate2D?
    let onPick: (Anchor) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [MKMapItem] = []

    @State private var mapCamera: MapCameraPosition = .automatic
    @State private var pickedCoord: CLLocationCoordinate2D?
    @State private var pickedName: String = "선택한 위치"

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                List {
                    Section("검색 결과") {
                        if results.isEmpty {
                            Text("장소 이름을 검색해보세요 (예: 강남역, 코엑스, 연남동)")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results, id: \.self) { item in
                                Button {
                                    let name = item.name ?? "선택한 장소"
                                    let coord = item.location.coordinate
                                    onPick(Anchor(name: name, coordinate: coord))
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name ?? "이름 없음").font(.headline)
                                        if let short = item.address?.shortAddress, !short.isEmpty {
                                            Text(short).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section("지도에서 찍기") {
                        MapReader { proxy in
                            Map(position: $mapCamera) {
                                if let c = pickedCoord {
                                    Annotation(pickedName, coordinate: c) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .padding(6)
                                            .background(.thinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(Rectangle())
                            .onTapGesture { point in
                                if let coord = proxy.convert(point, from: .local) {
                                    pickedCoord = coord
                                    pickedName = "선택한 위치"
                                }
                            }
                        }

                        if let c = pickedCoord {
                            Button {
                                onPick(Anchor(name: pickedName, coordinate: c))
                                dismiss()
                            } label: {
                                Label("이 위치를 기준으로 선택", systemImage: "checkmark.circle")
                            }
                        } else {
                            Text("지도를 탭해서 기준 위치를 찍어보세요.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("기준 장소 선택")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "장소 검색")
            .onSubmit(of: .search) { Task { await runSearch() } }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
            .onAppear {
                if let center = initialRegionCenter {
                    mapCamera = .region(MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                    ))
                }
            }
        }
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q

        if let center = initialRegionCenter {
            request.region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems

            if let first = response.mapItems.first {
                let coord = first.location.coordinate
                mapCamera = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                ))
            }
        } catch {
            results = []
        }
    }
}


// MARK: - Favorites List

struct FavoritesListView: View {
    let cafes: [Cafe]
    @ObservedObject var favorites: FavoritesStore
    let onSelect: (Cafe) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if cafes.isEmpty {
                    ContentUnavailableView(
                        "즐겨찾기 없음",
                        systemImage: "star",
                        description: Text("카페 목록에서 즐겨찾기를 추가해보세요.")
                    )
                } else {
                    ForEach(cafes) { cafe in
                        Button {
                            onSelect(cafe)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(cafe.name).font(.headline)
                                    Spacer()
                                    Text(cafe.distanceText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text(cafe.displayAddress.isEmpty ? "주소 정보 없음" : cafe.displayAddress)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                favorites.toggle(cafe.id)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("즐겨찾기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
        }
    }
}


// MARK: - ContentView

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var vm: CafeFinderViewModel

    @State private var camera: MapCameraPosition = .automatic
    @State private var showingDetail: Cafe?

    @State private var anchorMode: AnchorMode = .myLocation
    @State private var customAnchor: Anchor? = nil
    @State private var isPickingAnchor = false

    @State private var isProgrammaticCameraMove = false
    @StateObject private var favorites = FavoritesStore()

    @State private var searchText: String = ""
    @State private var sortMode: SortMode = .distance

    // ✅ 반경: 1 ~ 10km / 기본 1km
    @State private var radiusKm: Double = 1.0
    @State private var showRadiusToast = false
    @State private var radiusDebounceTask: Task<Void, Never>?

    // ✅ 지도 움직였을 때만 리센터 버튼 표시
    @State private var hasUserMovedMap = false

    @FocusState private var isSearchFocused: Bool

    // ✅ 즐겨찾기 UI 상태
    @State private var showFavoritesSheet = false
    @State private var showEmptyFavoritesAlert = false
    @State private var showFavoritesOnly = false
    @State private var copiedCafeID: String?

    private enum SortMode: String, CaseIterable, Identifiable {
        case distance = "거리순"
        case name = "이름순"
        var id: String { rawValue }
    }

    private func setCameraProgrammatically(_ position: MapCameraPosition) {
        isProgrammaticCameraMove = true
        camera = position

        // 카메라 애니메이션/반영 시간 조금 주고 플래그 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isProgrammaticCameraMove = false
        }
    }
    private var activeAnchor: Anchor? {
        switch anchorMode {
        case .myLocation:
            if let c = locationManager.location?.coordinate {
                return Anchor(name: "내 위치", coordinate: c)
            }
            return nil
        case .customPlace:
            return customAnchor
        }
    }

    private var favoriteCafes: [Cafe] {
        vm.cafes
            .filter { favorites.contains($0.id) }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    private var nearestCafe: Cafe? {
        presentedCafes.min { $0.distanceMeters < $1.distanceMeters }
    }

    private var brandSummary: [BrandCount] {
        CafeBrand.displayOrder
            .map { brand in BrandCount(brand: brand, count: presentedCafes.filter { $0.brand == brand }.count) }
            .filter { $0.count > 0 }
    }

    private var filterSummaryText: String {
        var parts: [String] = [radiusDisplayText]
        if showFavoritesOnly { parts.append("즐겨찾기만") }
        if !vm.selectedBrands.isEmpty {
            let names = CafeBrand.displayOrder
                .filter { vm.selectedBrands.contains($0) }
                .map(\.chipTitle)
            parts.append(names.joined(separator: ", "))
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty { parts.append("\"\(query)\"") }
        return parts.joined(separator: " · ")
    }

    private var filterMetricText: String {
        var count = 0
        if showFavoritesOnly { count += 1 }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        count += vm.selectedBrands.count
        return count == 0 ? "기본" : "\(count)개 적용"
    }

    private var anchorDisplayText: String {
        activeAnchor.map { $0.name == "내 위치" ? "내 위치 기준" : $0.name } ?? "기준 위치 확인 중"
    }

    private var presentedCafes: [Cafe] {
        var list = vm.cafes

        list = list.filter { $0.distanceMeters <= radiusKm * 1000 }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            list = list.filter { cafe in
                cafe.name.lowercased().contains(q) ||
                cafe.displayAddress.lowercased().contains(q)
            }
        }

        switch sortMode {
        case .distance:
            list.sort { $0.distanceMeters < $1.distanceMeters }
        case .name:
            list.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }

        // 즐겨찾기 우선
        list.sort { a, b in
            let fa = favorites.contains(a.id)
            let fb = favorites.contains(b.id)
            if fa != fb { return fa && !fb }
            return false
        }

        if showFavoritesOnly {
            list = list.filter { favorites.contains($0.id) }
        }

        return list
    }

    init() {
        let service = NaverLocalSearchService(
            clientId: Secrets.naverClientId,
            clientSecret: Secrets.naverClientSecret
        )
        _vm = StateObject(wrappedValue: CafeFinderViewModel(naver: service))
    }

    var body: some View {
        ZStack {
            UIX.pageGradient
                .ignoresSafeArea()

            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        searchSection
                        filterSection
                        conciergeSection
                        mapSection
                        statusSection
                        resultsHeaderSection
                        resultsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
                .background(Color.clear)
                .overlay(alignment: .top) { radiusToast }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture { isSearchFocused = false }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .refreshable {
                    guard let anchor = activeAnchor else { return }
                    vm.reload(anchor: anchor, silent: false)
                }
            }
        }
        .sheet(item: $showingDetail) { cafe in
            CafeDetailView(cafe: cafe)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $isPickingAnchor) {
            AnchorPickerView(
                initialRegionCenter: locationManager.location?.coordinate ?? customAnchor?.coordinate,
                onPick: { picked in
                    customAnchor = picked
                    anchorMode = .customPlace
                    camera = .region(MKCoordinateRegion(
                        center: picked.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                    ))
                    vm.reload(anchor: picked, silent: false)
                }
            )
        }
        .sheet(isPresented: $showFavoritesSheet) {
            FavoritesListView(
                cafes: favoriteCafes,
                favorites: favorites,
                onSelect: { cafe in focus(on: cafe) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
        .alert("즐겨찾기 없음", isPresented: $showEmptyFavoritesAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("저장된 카페가 없어요.\n카페 목록에서 즐겨찾기를 추가해보세요.")
        }
        .onAppear { locationManager.requestPermissionAndStart() }
        .onChange(of: locationManager.location) { _, _ in
            guard anchorMode == .myLocation else { return }
            guard let anchor = activeAnchor else { return }

            setCameraProgrammatically(.region(MKCoordinateRegion(
                center: anchor.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )))
            vm.reload(anchor: anchor, silent: false)
            hasUserMovedMap = false
        }
        .onChange(of: anchorMode) { _, _ in
            if let a = activeAnchor {
                camera = .region(MKCoordinateRegion(
                    center: a.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                ))
                vm.reload(anchor: a, silent: false)
                hasUserMovedMap = false
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(UIX.blue600)

                        Text("Cafe Finder")
                            .font(UIX.title())
                            .foregroundStyle(UIX.slate900)
                    }

                    Text("가까운 카페를 더 빠르게 고르는 방법")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(UIX.slate500)
                }

                Spacer()

                Menu {
                    Picker("정렬", selection: $sortMode) {
                        ForEach(SortMode.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }

                    Divider()

                    Button {
                        anchorMode = .myLocation
                    } label: {
                        Label("내 위치 기준", systemImage: "location")
                    }

                    Button {
                        isPickingAnchor = true
                    } label: {
                        Label("장소 선택", systemImage: "mappin.and.ellipse")
                    }

                    Button {
                        if let a = activeAnchor {
                            vm.reload(anchor: a, silent: false)
                            hasUserMovedMap = false
                        }
                    } label: {
                        Label("재검색", systemImage: "arrow.clockwise")
                    }
                    .disabled(activeAnchor == nil || vm.isLoading)

                    Button {
                        if favorites.ids.isEmpty {
                            showEmptyFavoritesAlert = true
                        } else {
                            showFavoritesSheet = true
                        }
                    } label: {
                        Label("즐겨찾기 목록", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(UIX.slate600)
                        .frame(width: 40, height: 40)
                        .background(UIX.slate50)
                        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(anchorDisplayText)
                    .lineLimit(1)
            }
                .font(.caption.weight(.semibold))
                .foregroundStyle(UIX.slate500)

            HStack(spacing: 8) {
                Button {
                    UIX.haptic(.soft)
                    showFavoritesOnly.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .font(.system(size: 15, weight: .semibold))
                        Text(favorites.ids.isEmpty ? "즐겨찾기" : "즐겨찾기 (\(favorites.ids.count))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(showFavoritesOnly ? .white : UIX.slate700)
                    .background(
                        RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                            .fill(
                                showFavoritesOnly
                                ? AnyShapeStyle(LinearGradient(colors: [UIX.amber500, UIX.orange500], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(UIX.slate100)
                            )
                    )
                    .shadow(color: UIX.orange500.opacity(showFavoritesOnly ? 0.16 : 0), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(presentedCafes.count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("곳")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(UIX.blue700)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(UIX.blue50)
                .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
            }
        }
        .padding(24)
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
        .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(UIX.slate400)

            TextField("카페 이름 또는 주소로 검색", text: $searchText)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .foregroundStyle(UIX.slate900)
                .onSubmit { isSearchFocused = false }

            if !searchText.isEmpty {
                Button {
                    UIX.haptic(.light)
                    searchText = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(UIX.slate400)
                        .frame(width: 26, height: 26)
                        .background(UIX.slate100)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIX.corner, style: .continuous)
                .stroke(isSearchFocused ? UIX.blue500 : UIX.slate200, lineWidth: 2)
        )
        .shadow(color: UIX.blue500.opacity(isSearchFocused ? 0.10 : 0), radius: 14, x: 0, y: 8)
        .animation(.snappy(duration: 0.18), value: searchText.isEmpty)
        .animation(.snappy(duration: 0.18), value: isSearchFocused)
    }

    // MARK: - Filters

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("검색 반경", systemImage: "ruler")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(UIX.slate700)

                    Spacer()

                    Text(radiusDisplayText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(UIX.blue700)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(UIX.blue100)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }

                Slider(value: $radiusKm, in: 1...10, step: 1)
                    .tint(UIX.blue600)
                    .onChange(of: radiusKm) { _, _ in
                        UIX.haptic(.soft)

                        showRadiusToast = true
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            showRadiusToast = false
                        }

                        radiusDebounceTask?.cancel()
                        radiusDebounceTask = Task {
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            if Task.isCancelled { return }
                            await MainActor.run {
                                guard let a = activeAnchor else { return }
                                vm.reload(anchor: a, silent: false)
                            }
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("브랜드")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(UIX.slate700)

                BrandChips(selected: $vm.selectedBrands) { vm.applyFilter(animated: true) }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("정렬")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(UIX.slate700)

                HStack(spacing: 8) {
                    ForEach(SortMode.allCases) { mode in
                        Button {
                            UIX.haptic(.soft)
                            sortMode = mode
                        } label: {
                            Label(mode.rawValue, systemImage: mode == .distance ? "point.topleft.down.curvedto.point.bottomright.up" : "textformat")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .foregroundStyle(sortMode == mode ? .white : UIX.slate700)
                                .background(
                                    RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                                        .fill(sortMode == mode ? AnyShapeStyle(LinearGradient(colors: [UIX.violet500, UIX.blue600], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(UIX.slate100))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("기준 위치")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(UIX.slate700)

                HStack(spacing: 8) {
                    Button {
                        UIX.haptic(.soft)
                        anchorMode = .myLocation
                    } label: {
                        Label("내 위치", systemImage: "location.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(anchorMode == .myLocation ? .white : UIX.slate700)
                            .background(
                                RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                                    .fill(anchorMode == .myLocation ? AnyShapeStyle(LinearGradient(colors: [UIX.blue600, UIX.blue700], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(UIX.slate100))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        UIX.haptic(.soft)
                        isPickingAnchor = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(customAnchor?.name ?? "장소 선택")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(anchorMode == .customPlace ? .white : UIX.slate700)
                        .background(
                            RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous)
                                .fill(anchorMode == .customPlace ? AnyShapeStyle(LinearGradient(colors: [UIX.blue600, UIX.blue700], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(UIX.slate100))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
        .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
    }

    private var radiusToast: some View {
        Group {
            if showRadiusToast {
                HStack(spacing: 8) {
                    Image(systemName: "scope")
                    Text("검색 반경: \(radiusDisplayText)")
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.18), value: showRadiusToast)
    }

    // MARK: - Concierge

    private var conciergeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Cafe Concierge")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(UIX.blue600)
                        .textCase(.uppercase)

                    Text(nearestCafe == nil ? "조건에 맞는 카페를 찾고 있어요" : "지금 가장 가기 좋은 선택")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(UIX.slate900)
                }

                Spacer()

                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(UIX.blue600)
                    .frame(width: 44, height: 44)
                    .background(UIX.blue50)
                    .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
            }

            if let cafe = nearestCafe {
                Button {
                    UIX.haptic(.soft)
                    focus(on: cafe)
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text(cafe.name)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                Text(recommendationText(for: cafe))
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.80))
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text(cafe.brand.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.18))
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 10) {
                            Label(cafe.distanceText, systemImage: "figure.walk")
                            Label(anchorDisplayText, systemImage: "location")
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(UIX.premiumGradient)
                    .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
                    .shadow(color: UIX.blue600.opacity(0.14), radius: 18, x: 0, y: 12)
                }
                .buttonStyle(.plain)
            } else if vm.isLoading {
                loadingConciergeCard
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("추천할 카페가 아직 없어요")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(UIX.slate900)
                    Text("브랜드 선택을 줄이거나 검색 반경을 넓혀보세요.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(UIX.slate500)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(UIX.slate50)
                .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
            }

            HStack(spacing: 8) {
                metricPill(title: "결과", value: "\(presentedCafes.count)곳", systemImage: "list.bullet.rectangle", tint: UIX.blue600)
                metricPill(title: "저장", value: "\(favorites.ids.count)", systemImage: "star.fill", tint: UIX.amber500)
                metricPill(title: "필터", value: filterMetricText, systemImage: "slider.horizontal.3", tint: UIX.violet500)
            }

            if !brandSummary.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("브랜드 분포")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(UIX.slate700)

                    VStack(spacing: 8) {
                        ForEach(brandSummary) { item in
                            brandDistributionRow(item.brand, count: item.count)
                        }
                    }
                }
            }
        }
        .padding(22)
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous)
                .stroke(UIX.slate100, lineWidth: 1)
        )
        .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
        .animation(.snappy(duration: 0.2), value: presentedCafes.count)
    }

    private var loadingConciergeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(UIX.slate100)
                .frame(width: 170, height: 18)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(UIX.slate100)
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(UIX.slate100)
                .frame(width: 210, height: 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UIX.slate50)
        .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
        .redacted(reason: .placeholder)
    }

    private func metricPill(title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(UIX.slate500)

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(UIX.slate900)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(UIX.slate50)
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
    }

    private func brandDistributionRow(_ brand: CafeBrand, count: Int) -> some View {
        let maxCount = max(brandSummary.map(\.count).max() ?? 1, 1)
        return HStack(spacing: 10) {
            Text(brand.chipTitle)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(UIX.slate700)
                .frame(width: 58, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(UIX.slate100)
                    Capsule()
                        .fill(LinearGradient(colors: brand.strongGradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * CGFloat(count) / CGFloat(maxCount))
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(UIX.slate500)
                .frame(width: 24, alignment: .trailing)
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $camera) {
                if let anchor = activeAnchor {
                    Annotation("기준", coordinate: anchor.coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(UIX.blue600)
                                .background(Circle().fill(UIX.pinCore).frame(width: 18, height: 18))
                                .shadow(color: UIX.blue600.opacity(0.16), radius: 10, x: 0, y: 4)
                        }
                    }
                }

                ForEach(Array(presentedCafes.prefix(60))) { cafe in
                    Annotation(cafe.name, coordinate: cafe.coordinate) {
                        Button { focus(on: cafe) } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(cafe.brand.accentColor)
                                .background(Circle().fill(UIX.pinCore).frame(width: 17, height: 17))
                                .shadow(color: cafe.brand.accentColor.opacity(0.16), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 320)
            .onMapCameraChange(frequency: .continuous) {
                if !isProgrammaticCameraMove {
                    hasUserMovedMap = true
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "map")
                Text("주변 지도")
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(UIX.slate600)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(UIX.mapOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(color: UIX.shadow(), radius: 6, x: 0, y: 3)
            .padding(16)

            if vm.isLoading {
                ZStack {
                    UIX.mapScrim
                    ProgressView()
                        .padding(12)
                        .background(UIX.mapOverlay)
                        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                        .shadow(color: UIX.shadow(), radius: 8, x: 0, y: 4)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        recenterToActiveAnchor()
                        hasUserMovedMap = false
                    } label: {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(UIX.blue600)
                            .brandIconButton(48)
                    }
                    .buttonStyle(.plain)
                    .disabled(activeAnchor == nil)
                    .opacity(activeAnchor == nil ? 0.45 : 1.0)
                    .padding(16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous)
                .stroke(UIX.slate100, lineWidth: 1)
        )
        .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
    }

    // MARK: - Status Section (Premium cards)

    private var statusSection: some View {
        VStack(spacing: 10) {

            if let locErr = locationManager.locationError {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "location.slash")
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("위치 접근이 필요해요")
                                .font(.headline)
                            Text(locErr)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button { openAppSettings() } label: {
                            Label("설정 열기", systemImage: "gearshape")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button { locationManager.requestPermissionAndStart() } label: {
                            Label("다시 시도", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
                .brandCard()
            }

            if let apiErr = vm.errorMessage, locationManager.locationError == nil {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(apiErr)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .brandCard()
            }

            if vm.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("주변 카페를 찾는 중…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .brandCard()
            }
        }
    }

    // MARK: - Results

    private var resultsHeaderSection: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("카페 리스트")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(UIX.slate900)

                Text(filterSummaryText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(UIX.slate500)
                    .lineLimit(1)
            }

            Spacer()

            Text(sortMode.rawValue)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(UIX.blue700)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(UIX.blue50)
                .clipShape(Capsule())
        }
        .padding(.top, 2)
    }

    private var resultsSection: some View {
        Group {
            if vm.isLoading && presentedCafes.isEmpty {
                loadingResultsStack
            } else if presentedCafes.isEmpty {
                emptyResultsCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(presentedCafes) { cafe in
                        cafeCard(cafe)
                    }
                }
            }
        }
    }

    private var loadingResultsStack: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 14) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(UIX.slate100)
                        .frame(width: 190, height: 18)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(UIX.slate100)
                        .frame(height: 13)
                    HStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(UIX.slate100)
                            .frame(width: 72, height: 30)
                        Spacer()
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(UIX.slate100)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(20)
                .background(UIX.card)
                .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: UIX.corner, style: .continuous)
                        .stroke(UIX.slate100, lineWidth: 1)
                )
                .redacted(reason: .placeholder)
            }
        }
    }

    private var emptyResultsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(UIX.slate200)

            Text("검색 결과가 없습니다")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(UIX.slate700)

            Text("다른 조건으로 검색해보세요")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(UIX.slate500)

            HStack(spacing: 8) {
                Button {
                    UIX.haptic(.soft)
                    radiusKm = 10
                    vm.selectedBrands.removeAll()
                    showFavoritesOnly = false
                    searchText = ""
                    if let anchor = activeAnchor {
                        vm.reload(anchor: anchor, silent: false)
                    }
                } label: {
                    Label("조건 초기화", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(LinearGradient(colors: [UIX.blue600, UIX.blue700], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    UIX.haptic(.soft)
                    isPickingAnchor = true
                } label: {
                    Label("장소 변경", systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(UIX.slate700)
                        .background(UIX.slate100)
                        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 18)
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.cornerLarge, style: .continuous))
        .shadow(color: UIX.shadow(), radius: 18, x: 0, y: 10)
    }

    private func cafeCard(_ cafe: Cafe) -> some View {
        let isFavorite = favorites.contains(cafe.id)
        let isCopied = copiedCafeID == cafe.id
        let address = cafe.displayAddress.isEmpty ? "주소 정보 없음" : cafe.displayAddress

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(cafe.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(UIX.slate900)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12, weight: .semibold))
                        Text(address)
                            .lineLimit(1)
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(UIX.slate600)
                }

                Spacer(minLength: 8)

                Text(cafe.brand.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(cafe.brand.accentColor)
                    .clipShape(Capsule())
                    .shadow(color: cafe.brand.accentColor.opacity(0.14), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: cafe.brand.softGradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onTapGesture { focus(on: cafe) }

            VStack(spacing: 16) {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(distanceNumberText(cafe))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(UIX.blue600)
                        Text(distanceUnitText(cafe))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(UIX.slate500)
                    }

                    Spacer()

                    Button {
                        UIX.haptic(.soft)
                        favorites.toggle(cafe.id)
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(isFavorite ? .white : UIX.slate400)
                            .frame(width: 44, height: 44)
                            .background(isFavorite ? UIX.amber500 : UIX.slate100)
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                            .shadow(color: UIX.amber500.opacity(isFavorite ? 0.16 : 0), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Button {
                        UIX.haptic(.light)
                        openNaverMapSearch(query: cafe.mapSearchQuery)
                    } label: {
                        Label("길찾기", systemImage: "location.north.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(colors: [UIX.blue600, UIX.blue700], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                            .shadow(color: UIX.blue600.opacity(0.16), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        UIX.haptic(.light)
                        copyAddress(for: cafe)
                    } label: {
                        Label(isCopied ? "복사됨!" : "복사", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .foregroundStyle(isCopied ? .white : UIX.slate700)
                            .background(isCopied ? UIX.green500 : UIX.slate100)
                            .clipShape(RoundedRectangle(cornerRadius: UIX.cornerSmall, style: .continuous))
                            .shadow(color: UIX.green500.opacity(isCopied ? 0.16 : 0), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(UIX.card)
        .clipShape(RoundedRectangle(cornerRadius: UIX.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIX.corner, style: .continuous)
                .stroke(UIX.slate100, lineWidth: 2)
        )
        .shadow(color: UIX.shadow(), radius: 14, x: 0, y: 8)
    }

    // MARK: - Helpers

    private var radiusDisplayText: String {
        if radiusKm < 1.0 {
            return "\(Int(radiusKm * 1000))m"
        } else if radiusKm.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(radiusKm))km"
        } else {
            return String(format: "%.1fkm", radiusKm)
        }
    }

    private func distanceNumberText(_ cafe: Cafe) -> String {
        if cafe.distanceMeters >= 1000 {
            return String(format: "%.1f", cafe.distanceMeters / 1000.0)
        }
        return String(format: "%.0f", cafe.distanceMeters)
    }

    private func distanceUnitText(_ cafe: Cafe) -> String {
        cafe.distanceMeters >= 1000 ? "km" : "m"
    }

    private func recommendationText(for cafe: Cafe) -> String {
        if favorites.contains(cafe.id) {
            return "저장해둔 곳 중 가장 가까운 매장이에요."
        }

        switch cafe.distanceMeters {
        case ..<250:
            return "걸어서 바로 들르기 좋은 초근접 매장이에요."
        case ..<600:
            return "가볍게 이동하기 좋은 거리라 첫 선택으로 추천해요."
        case ..<1200:
            return "반경 안에서 접근성과 브랜드 선호의 균형이 좋아요."
        default:
            return "조건에 맞는 후보 중 가장 가까운 매장이에요."
        }
    }

    private func copyAddress(for cafe: Cafe) {
        let text = cafe.displayAddress.isEmpty ? cafe.address : cafe.displayAddress
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        UIPasteboard.general.string = trimmed
        copiedCafeID = cafe.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedCafeID == cafe.id {
                copiedCafeID = nil
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func focus(on cafe: Cafe) {
        setCameraProgrammatically(.region(MKCoordinateRegion(
            center: cafe.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )))
        showingDetail = cafe
    }

    private func recenterToActiveAnchor() {
        guard let anchor = activeAnchor else { return }
        UIX.haptic(.soft)

        setCameraProgrammatically(.region(MKCoordinateRegion(
            center: anchor.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }
}
