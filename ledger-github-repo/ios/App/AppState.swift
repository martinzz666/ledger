import SwiftUI
import WidgetKit

/// 唯一的資料來源。每次變更都寫回 App Group，並要求小工具立刻重畫。
final class AppState: ObservableObject {
    @Published var data: LedgerData {
        didSet { persist() }
    }
    @Published var month: Date = Calendar.current.monthStart(Date())
    @Published var year: Int = Calendar.current.component(.year, from: Date())

    init() {
        data = SharedStore.load()
    }

    private func persist() {
        SharedStore.save(data)
        WidgetCenter.shared.reloadAllTimelines()   // ← 小工具自動更新的關鍵
    }

    // MARK: 明細

    func upsert(_ e: Entry) {
        if let i = data.entries.firstIndex(where: { $0.id == e.id }) {
            data.entries[i] = e
        } else {
            data.entries.append(e)
        }
        month = Calendar.current.monthStart(e.date)
    }

    func remove(_ e: Entry) {
        data.entries.removeAll { $0.id == e.id }
    }

    // MARK: 房貸繳款

    func pay(_ row: Installment) {
        let cat = data.loan?.category ?? "房貸"
        let note = "第 \(row.term) 期（本金 \(money(row.principal))・利息 \(money(row.interest))）"
        data.entries.append(Entry(kind: .expense,
                                  amount: (row.payment * 100).rounded() / 100,
                                  category: cat, date: row.date,
                                  note: note, loanTerm: row.term))
    }

    func unpay(term: Int) {
        data.entries.removeAll { $0.loanTerm == term }
    }

    // MARK: 月份 / 年度切換

    func shiftMonth(_ n: Int) {
        month = Calendar.current.date(byAdding: .month, value: n, to: month) ?? month
    }

    var stats: BudgetStats { Stats.compute(data, month: month) }
}
