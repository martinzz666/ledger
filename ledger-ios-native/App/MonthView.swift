import SwiftUI

struct MonthView: View {
    @EnvironmentObject var state: AppState
    @State private var editing: Entry? = nil
    @State private var showBudgetEditor = false

    private var items: [Entry] { Stats.entries(state.data, month: state.month) }
    private var expense: Double { items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    private var income:  Double { items.filter { $0.kind == .income  }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MonthHeader()
                    summary
                    budgetStrip
                    Rectangle().fill(T.rule).frame(height: 1).padding(.top, 22)
                    if items.isEmpty {
                        Text("這個月還沒有紀錄\n按右上角的 ＋ 記第一筆")
                            .font(.system(size: 14)).foregroundStyle(T.faint)
                            .multilineTextAlignment(.center).lineSpacing(8)
                            .frame(maxWidth: .infinity).padding(.top, 64)
                    } else {
                        ForEach(grouped, id: \.0) { day, rows in
                            daySection(day, rows)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .background(T.paper)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = Entry(kind: .expense, amount: 0, category: "", date: defaultDate) } label: {
                        Image(systemName: "plus").font(.system(size: 17, weight: .light))
                    }
                }
            }
            .toolbarBackground(T.paper, for: .navigationBar)
        }
        .sheet(item: $editing) { e in
            EntryEditor(entry: e).environmentObject(state)
        }
        .sheet(isPresented: $showBudgetEditor) {
            BudgetEditor().environmentObject(state)
        }
    }

    private var defaultDate: Date {
        Calendar.current.sameMonth(state.month, Date()) ? Date() : state.month
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("NT$").font(.system(size: 17)).foregroundStyle(T.mute)
                Text(signed(income - expense))
                    .font(.system(size: 44, weight: .ultraLight).monospacedDigit())
            }
            Text("本月結餘").font(.system(size: 12.5)).kerning(1.2)
                .foregroundStyle(T.mute).padding(.top, 9)
            HStack(spacing: 30) {
                col("支出", expense, T.ink)
                col("收入", income, T.sage)
            }
            .padding(.top, 22)
        }
        .padding(.top, 18)
    }

    private func col(_ k: String, _ v: Double, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(k).font(.system(size: 12.5)).kerning(1).foregroundStyle(T.mute)
            Text(money(v)).font(.system(size: 20, weight: .light).monospacedDigit()).foregroundStyle(c)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var budgetStrip: some View {
        let s = state.stats
        if s.hasBudget {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(T.rule).frame(height: 1).padding(.bottom, 18)
                HStack {
                    Text(s.daysLeft > 0 ? "每日可花（剩 \(s.daysLeft) 天）" : "本月已結束")
                        .font(.system(size: 13)).foregroundStyle(T.mute)
                    Spacer()
                    Text("餘 " + signed(s.usable))
                        .font(.system(size: 13).monospacedDigit()).foregroundStyle(T.mute)
                }
                Text(s.daysLeft > 0 ? signed(s.daily) : money(0))
                    .font(.system(size: 26, weight: .light).monospacedDigit())
                    .foregroundStyle(s.usable < 0 ? T.seal : T.ink)
                    .padding(.top, 4)
                Track(pct: s.usePct, marker: s.isCurrentMonth ? s.timePct : nil, over: s.usePct > 100)
                    .padding(.vertical, 10)
                HStack {
                    Text("已花 \(money(s.spent)) / \(money(s.total))")
                    Spacer()
                    Text("\(Int(s.usePct))%")
                }
                .font(.system(size: 12).monospacedDigit()).foregroundStyle(T.faint)
            }
            .padding(.top, 22)
        } else {
            Button("設定每月預算") { showBudgetEditor = true }
                .font(.system(size: 13.5)).foregroundStyle(T.mute)
                .padding(.top, 22)
        }
    }

    private var grouped: [(Date, [Entry])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: items) { cal.dayStart($0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    private func daySection(_ day: Date, _ rows: [Entry]) -> some View {
        let out = rows.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
        return VStack(spacing: 0) {
            HStack {
                Text(day.mdWeek)
                Spacer()
                Text(out > 0 ? "支出 \(money(out))" : "")
            }
            .font(.system(size: 12.5)).foregroundStyle(T.mute)
            .padding(.top, 24).padding(.bottom, 8)

            ForEach(rows) { r in
                Button { editing = r } label: { row(r) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func row(_ r: Entry) -> some View {
        HStack(spacing: 14) {
            Text(String(r.category.prefix(2)))
                .font(.system(size: 12))
                .foregroundStyle(r.kind == .income ? T.sage : T.mute)
                .frame(width: 38, height: 38)
                .overlay(Circle().stroke(r.kind == .income ? T.sage : T.rule, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(r.category).font(.system(size: 15.5)).foregroundStyle(T.ink)
                if !r.note.isEmpty {
                    Text(r.note).font(.system(size: 12.5)).foregroundStyle(T.faint).lineLimit(1)
                }
            }
            Spacer()
            Text((r.kind == .income ? "+" : "−") + money(r.amount))
                .font(.system(size: 16.5).monospacedDigit())
                .foregroundStyle(r.kind == .income ? T.sage : T.ink)
        }
        .padding(.vertical, 13)
        .overlay(alignment: .top) { Rectangle().fill(T.rule).frame(height: 1) }
    }
}
