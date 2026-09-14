import SwiftUI

struct YearView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    summary
                    keys
                    Text("每月收支").font(.system(size: 13)).kerning(1.2)
                        .foregroundStyle(T.mute).padding(.top, 30).padding(.bottom, 6)
                    months
                    legend
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .background(T.paper)
            .toolbarBackground(T.paper, for: .navigationBar)
        }
    }

    private var items: [Entry] { Stats.entries(state.data, year: state.year) }
    private var expense: Double { items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    private var income:  Double { items.filter { $0.kind == .income  }.reduce(0) { $0 + $1.amount } }

    private var header: some View {
        HStack {
            Button { state.year -= 1 } label: {
                Image(systemName: "chevron.left").foregroundStyle(T.faint)
            }.frame(width: 44, height: 44)
            Spacer()
            Text("\(String(state.year)) 年").font(.system(size: 15, weight: .medium)).kerning(1)
            Spacer()
            Button { state.year += 1 } label: {
                Image(systemName: "chevron.right").foregroundStyle(T.faint)
            }.frame(width: 44, height: 44)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("NT$").font(.system(size: 17)).foregroundStyle(T.mute)
                Text(signed(income - expense))
                    .font(.system(size: 44, weight: .ultraLight).monospacedDigit())
            }
            Text("全年結餘").font(.system(size: 12.5)).kerning(1.2)
                .foregroundStyle(T.mute).padding(.top, 9)
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("支出").font(.system(size: 12.5)).foregroundStyle(T.mute)
                    Text(money(expense)).font(.system(size: 20, weight: .light).monospacedDigit())
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 3) {
                    Text("收入").font(.system(size: 12.5)).foregroundStyle(T.mute)
                    Text(money(income)).font(.system(size: 20, weight: .light).monospacedDigit())
                        .foregroundStyle(T.sage)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 22).padding(.bottom, 8)
        }
        .padding(.top, 18)
    }

    private var monthly: (out: [Double], inc: [Double]) {
        var o = [Double](repeating: 0, count: 12)
        var i = [Double](repeating: 0, count: 12)
        let cal = Calendar.current
        for e in items {
            let m = cal.component(.month, from: e.date) - 1
            if e.kind == .expense { o[m] += e.amount } else { i[m] += e.amount }
        }
        return (o, i)
    }

    private var keys: some View {
        let m = monthly
        let active = max((0..<12).filter { m.out[$0] > 0 || m.inc[$0] > 0 }.count, 1)
        let loanRows = state.data.loan.map { loan -> [Installment] in
            Amortization.schedule(loan).filter { Calendar.current.component(.year, from: $0.date) == state.year }
        } ?? []
        let paid = Stats.paidTerms(state.data)
        return Group {
            KeyLine(k: "月均支出", v: money(expense / Double(active)))
            KeyLine(k: "月均收入", v: money(income / Double(active)))
            KeyLine(k: "儲蓄率", v: income > 0 ? String(format: "%.1f%%", (income - expense) / income * 100) : "—")
            if !loanRows.isEmpty {
                KeyLine(k: "房貸年度應繳", v: money(loanRows.reduce(0) { $0 + $1.payment }))
                KeyLine(k: "房貸繳納期數",
                        v: "\(loanRows.filter { paid.contains($0.term) }.count) / \(loanRows.count) 期")
            }
        }
    }

    private var months: some View {
        let m = monthly
        let maxV = max(m.out.max() ?? 1, m.inc.max() ?? 1, 1)
        return ForEach(0..<12, id: \.self) { k in
            Button {
                if let d = Calendar.current.date(from: DateComponents(year: state.year, month: k + 1)) {
                    state.month = d
                }
            } label: {
                HStack(spacing: 14) {
                    Text("\(k + 1)月").font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(T.mute).frame(width: 34, alignment: .leading)
                    GeometryReader { g in
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle().fill(T.ink)
                                .frame(width: g.size.width * m.out[k] / maxV, height: 3)
                            Rectangle().fill(T.sage)
                                .frame(width: g.size.width * m.inc[k] / maxV, height: 3)
                        }
                        .frame(height: 10, alignment: .center)
                    }
                    .frame(height: 10)
                    Text(m.out[k] + m.inc[k] > 0 ? signed(m.inc[k] - m.out[k]) : "—")
                        .font(.system(size: 14).monospacedDigit())
                        .foregroundStyle(m.inc[k] - m.out[k] < 0 ? T.seal : T.ink)
                        .frame(width: 92, alignment: .trailing)
                }
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) { Rectangle().fill(T.rule).frame(height: 1) }
            }
            .buttonStyle(.plain)
        }
    }

    private var legend: some View {
        HStack(spacing: 18) {
            HStack(spacing: 6) {
                Rectangle().fill(T.ink).frame(width: 14, height: 3); Text("支出")
            }
            HStack(spacing: 6) {
                Rectangle().fill(T.sage).frame(width: 14, height: 3); Text("收入")
            }
        }
        .font(.system(size: 12)).foregroundStyle(T.mute).padding(.top, 14)
    }
}
