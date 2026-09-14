import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var state: AppState
    @State private var showEditor = false
    @State private var kind: Kind = .expense

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MonthHeader()
                    if state.stats.hasBudget { panel(state.stats) } else { empty }
                    Text("分類").font(.system(size: 13)).kerning(1.2)
                        .foregroundStyle(T.mute).padding(.top, 30)
                    picker
                    categoryBars
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .background(T.paper)
            .toolbarBackground(T.paper, for: .navigationBar)
        }
        .sheet(isPresented: $showEditor) { BudgetEditor().environmentObject(state) }
    }

    private var empty: some View {
        VStack(spacing: 18) {
            Text("尚未設定每月預算\n設定後可看到每日可花與剩餘額度")
                .font(.system(size: 14)).foregroundStyle(T.faint)
                .multilineTextAlignment(.center).lineSpacing(8)
            Button("設定預算") { showEditor = true }
                .font(.system(size: 13.5)).foregroundStyle(T.mute)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func panel(_ s: BudgetStats) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("NT$").font(.system(size: 17)).foregroundStyle(T.mute)
                Text(signed(s.usable))
                    .font(.system(size: 42, weight: .ultraLight).monospacedDigit())
                    .foregroundStyle(s.usable < 0 ? T.seal : T.ink)
            }
            .padding(.top, 18)
            Text("本月可自由支配餘額").font(.system(size: 12.5)).kerning(1.2)
                .foregroundStyle(T.mute).padding(.top, 9)

            Track(pct: s.usePct, marker: s.isCurrentMonth ? s.timePct : nil, over: s.usePct > 100)
                .padding(.top, 20)
            HStack {
                Text("預算用掉 \(Int(s.usePct))%")
                Spacer()
                if s.isCurrentMonth { Text("時間過了 \(Int(s.timePct))%") }
            }
            .font(.system(size: 12)).foregroundStyle(T.faint).padding(.top, 7)

            Group {
                KeyLine(k: "每月預算", v: money(s.total))
                KeyLine(k: "本月已花費", v: money(s.spent))
                KeyLine(k: "剩餘預算", v: signed(s.remain), color: s.remain < 0 ? T.seal : T.ink)
                if s.reserve > 0 {
                    KeyLine(k: "保留給房貸（\(s.loanUnpaidCount) 期未繳）", v: money(s.reserve))
                }
                KeyLine(k: "剩餘天數", v: "\(s.daysLeft) 天")
                KeyLine(k: "每日可花", v: signed(s.daily), color: s.usable < 0 ? T.seal : T.ink)
                KeyLine(k: "今日已花", v: money(s.daySpent))
                KeyLine(k: "預估月底支出", v: money(s.forecast))
                KeyLine(k: "目前進度", v: paceText(s), color: s.usePct > s.timePct ? T.seal : T.ink)
            }
            .padding(.top, 6)

            Button("調整預算") { showEditor = true }
                .font(.system(size: 13.5)).foregroundStyle(T.mute).padding(.top, 26)
        }
    }

    private func paceText(_ s: BudgetStats) -> String {
        guard s.isCurrentMonth else { return "—" }
        let d = s.usePct - s.timePct
        return d > 0 ? "超前 \(Int(d))%" : "落後 \(Int(abs(d)))%"
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Kind.allCases, id: \.self) { k in
                Button { kind = k } label: {
                    Text(k.label)
                        .font(.system(size: 14)).kerning(1)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(kind == k ? T.ink : Color.clear)
                        .foregroundStyle(kind == k ? T.paper : T.mute)
                }
            }
        }
        .overlay(Rectangle().stroke(T.rule, lineWidth: 1))
        .padding(.top, 12)
    }

    private var categoryBars: some View {
        let rows = Stats.entries(state.data, month: state.month).filter { $0.kind == kind }
        let total = rows.reduce(0) { $0 + $1.amount }
        let byCat = Dictionary(grouping: rows, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
        let limits = state.data.budget?.cats ?? [:]

        return Group {
            if total == 0 {
                Text("這個月沒有\(kind.label)紀錄")
                    .font(.system(size: 14)).foregroundStyle(T.faint)
                    .frame(maxWidth: .infinity).padding(.vertical, 50)
            } else {
                ForEach(byCat, id: \.key) { cat, v in
                    bar(cat, v, total, kind == .expense ? (limits[cat] ?? 0) : 0)
                }
            }
        }
    }

    private func bar(_ cat: String, _ v: Double, _ total: Double, _ limit: Double) -> some View {
        let sharePct = v / total * 100
        let usePct = limit > 0 ? v / limit * 100 : sharePct
        let left = limit - v
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(cat).font(.system(size: 15))
                Text(limit > 0 ? "\(Int(usePct))%" : String(format: "%.1f%%", sharePct))
                    .font(.system(size: 12.5).monospacedDigit()).foregroundStyle(T.faint)
                Spacer()
                Text(limit > 0 ? "\(money(v)) / \(money(limit))" : money(v))
                    .font(.system(size: 15).monospacedDigit())
                    .foregroundStyle(kind == .income ? T.sage : T.ink)
            }
            Track(pct: usePct, over: limit > 0 && usePct > 100).padding(.top, 10)
            if limit > 0 {
                HStack {
                    Text(left < 0 ? "超支 \(money(-left))" : "還可花 \(money(left))")
                        .foregroundStyle(left < 0 ? T.seal : T.faint)
                    Spacer()
                    Text(String(format: "占總支出 %.1f%%", sharePct)).foregroundStyle(T.faint)
                }
                .font(.system(size: 12).monospacedDigit()).padding(.top, 5)
            }
        }
        .padding(.vertical, 17)
        .overlay(alignment: .bottom) { Rectangle().fill(T.rule).frame(height: 1) }
    }
}
