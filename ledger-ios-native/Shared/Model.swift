import Foundation

// MARK: - 資料模型

enum Kind: String, Codable, CaseIterable, Hashable {
    case expense, income
    var label: String { self == .expense ? "支出" : "收入" }
}

struct Entry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: Kind
    var amount: Double
    var category: String
    var date: Date
    var note: String = ""
    var loanTerm: Int? = nil        // 房貸期數，由繳款動作建立
}

enum LoanMethod: String, Codable, Hashable {
    case annuity, even
    var label: String { self == .annuity ? "本息平均攤還" : "本金平均攤還" }
}

struct Loan: Codable, Equatable {
    var amount: Double = 0
    var rate: Double = 0            // 年利率 %
    var years: Int = 30
    var graceYears: Int = 0         // 寬限期
    var first: Date = Date()        // 首期繳款日
    var category: String = "房貸"
    var method: LoanMethod = .annuity
}

struct Budget: Codable, Equatable {
    var total: Double = 0
    var cats: [String: Double] = [:]
    var includeLoan: Bool = true
}

enum Categories {
    static let expense = ["飲食","日用","交通","居住","房貸","通訊","醫療",
                          "教育","服飾","娛樂","人情","旅遊","其他"]
    static let income  = ["薪資","獎金","投資","兼職","補助","退款","其他"]
    static func list(_ k: Kind) -> [String] { k == .expense ? expense : income }
}

struct LedgerData: Codable {
    var entries: [Entry] = []
    var loan: Loan? = nil
    var budget: Budget? = nil
}

// MARK: - App Group 共用儲存（App 與小工具都讀這裡）

enum SharedStore {
    /// 兩個 target 的 App Group 必須完全一致
    static let appGroup = "group.tw.lin.ledger"
    private static let key = "ledger.data.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func load() -> LedgerData {
        guard let d = defaults.data(forKey: key),
              let v = try? JSONDecoder().decode(LedgerData.self, from: d)
        else { return LedgerData() }
        return v
    }

    static func save(_ v: LedgerData) {
        guard let d = try? JSONEncoder().encode(v) else { return }
        defaults.set(d, forKey: key)
    }
}

// MARK: - 日期小工具

extension Calendar {
    func monthStart(_ d: Date) -> Date {
        date(from: dateComponents([.year, .month], from: d)) ?? d
    }
    func dayStart(_ d: Date) -> Date { startOfDay(for: d) }
    func daysInMonth(_ d: Date) -> Int {
        range(of: .day, in: .month, for: d)?.count ?? 30
    }
    func sameMonth(_ a: Date, _ b: Date) -> Bool {
        isDate(a, equalTo: b, toGranularity: .month)
    }
}
