import Foundation

struct BudgetStats {
    var hasBudget = false
    var total = 0.0          // 每月預算
    var spent = 0.0          // 本月已花費
    var remain = 0.0         // 剩餘預算
    var reserve = 0.0        // 保留給未繳房貸
    var usable = 0.0         // 可自由支配
    var daily = 0.0          // 每日可花
    var daysLeft = 0
    var daysInMonth = 30
    var daySpent = 0.0       // 今日已花
    var forecast = 0.0       // 預估月底支出
    var usePct = 0.0
    var timePct = 0.0
    var isCurrentMonth = false
    var loanUnpaidCount = 0
    var month = Date()
}

enum Stats {

    static func entries(_ data: LedgerData, month: Date) -> [Entry] {
        let cal = Calendar.current
        let start = cal.monthStart(month)
        guard let end = cal.date(byAdding: .month, value: 1, to: start) else { return [] }
        return data.entries
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    static func entries(_ data: LedgerData, year: Int) -> [Entry] {
        let cal = Calendar.current
        return data.entries.filter { cal.component(.year, from: $0.date) == year }
    }

    static func paidTerms(_ data: LedgerData) -> Set<Int> {
        Set(data.entries.compactMap { $0.loanTerm })
    }

    /// 該月房貸應繳與未繳
    static func loanDue(_ data: LedgerData, month: Date) -> (total: Double, unpaid: Double, count: Int) {
        guard let loan = data.loan else { return (0, 0, 0) }
        let cal = Calendar.current
        let paid = paidTerms(data)
        let rows = Amortization.schedule(loan).filter { cal.sameMonth($0.date, month) }
        let openRows = rows.filter { !paid.contains($0.term) }
        return (rows.reduce(0) { $0 + $1.payment },
                openRows.reduce(0) { $0 + $1.payment },
                openRows.count)
    }

    static func compute(_ data: LedgerData, month: Date, now: Date = Date()) -> BudgetStats {
        let cal = Calendar.current
        var s = BudgetStats()
        s.month = cal.monthStart(month)
        s.daysInMonth = cal.daysInMonth(month)

        let items = entries(data, month: month)
        s.spent = items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }

        s.isCurrentMonth = cal.sameMonth(month, now)
        let isPast = cal.monthStart(month) < cal.monthStart(now)
        let dayNo = s.isCurrentMonth ? cal.component(.day, from: now) : (isPast ? s.daysInMonth : 0)
        s.daysLeft = s.isCurrentMonth ? s.daysInMonth - dayNo + 1 : (isPast ? 0 : s.daysInMonth)

        let due = loanDue(data, month: month)
        s.loanUnpaidCount = due.count

        if let b = data.budget, b.total > 0 {
            s.hasBudget = true
            s.total = b.total
            s.reserve = b.includeLoan ? due.unpaid : 0
        }
        s.remain = s.total - s.spent
        s.usable = s.remain - s.reserve
        s.daily = s.daysLeft > 0 ? s.usable / Double(s.daysLeft) : 0

        let today = cal.dayStart(now)
        s.daySpent = items
            .filter { $0.kind == .expense && cal.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }

        let elapsed = max(s.isCurrentMonth ? dayNo : (isPast ? s.daysInMonth : 0), 1)
        s.forecast = s.isCurrentMonth ? s.spent / Double(elapsed) * Double(s.daysInMonth) : s.spent
        s.usePct = s.total > 0 ? s.spent / s.total * 100 : 0
        s.timePct = s.isCurrentMonth ? Double(dayNo) / Double(s.daysInMonth) * 100 : (isPast ? 100 : 0)
        return s
    }
}
