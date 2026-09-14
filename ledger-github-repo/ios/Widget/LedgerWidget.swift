import WidgetKit
import SwiftUI

// MARK: - Timeline

struct BudgetEntry: TimelineEntry {
    let date: Date
    let stats: BudgetStats
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), stats: Stats.compute(SharedStore.load(), month: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// 產生今天到未來七天、每天凌晨的時間軸。
    /// 「剩餘天數」與「每日可花」因此每天自動重算，不需要任何手動同步；
    /// 記帳資料一有變動，App 會呼叫 WidgetCenter.reloadAllTimelines() 立刻刷新。
    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let data = SharedStore.load()
        let cal = Calendar.current
        let now = Date()
        var entries: [BudgetEntry] = [
            BudgetEntry(date: now, stats: Stats.compute(data, month: now, now: now))
        ]
        for i in 1...7 {
            guard let day = cal.date(byAdding: .day, value: i, to: cal.startOfDay(for: now)) else { continue }
            entries.append(BudgetEntry(date: day, stats: Stats.compute(data, month: day, now: day)))
        }
        let refresh = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }
}

// MARK: - 畫面

struct LedgerWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: BudgetEntry

    var body: some View {
        let s = entry.stats
        Group {
            if !s.hasBudget {
                VStack(alignment: .leading, spacing: 6) {
                    Text("尚未設定每月預算").font(.system(size: 14)).foregroundStyle(T.ink)
                    Text("打開記帳 App → 預算 → 設定預算")
                        .font(.system(size: 10, weight: .light)).foregroundStyle(T.mute)
                }
            } else if family == .systemSmall {
                small(s)
            } else {
                medium(s)
            }
        }
        .containerBackground(T.paper, for: .widget)
    }

    private func small(_ s: BudgetStats) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(s.daysLeft > 0 ? "剩 \(s.daysLeft) 天可花" : "本月已結束")
                .font(.system(size: 11, weight: .light)).foregroundStyle(T.mute)
            Text(signed(s.usable))
                .font(.system(size: 26, weight: .ultraLight).monospacedDigit())
                .foregroundStyle(s.usable < 0 ? T.seal : T.ink)
                .minimumScaleFactor(0.6).lineLimit(1)
                .padding(.top, 6)
            Text("每日 \(signed(s.daily))")
                .font(.system(size: 11, weight: .light)).foregroundStyle(T.mute).padding(.top, 2)
            Spacer(minLength: 8)
            Track(pct: s.usePct, marker: s.isCurrentMonth ? s.timePct : nil, over: s.usePct > 100)
            Text("已花 \(money(s.spent)) / \(money(s.total))")
                .font(.system(size: 9.5, weight: .light).monospacedDigit())
                .foregroundStyle(T.faint).padding(.top, 4)
        }
    }

    private func medium(_ s: BudgetStats) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("本月可自由支配")
                        .font(.system(size: 11, weight: .light)).foregroundStyle(T.mute)
                    Text(signed(s.usable))
                        .font(.system(size: 30, weight: .ultraLight).monospacedDigit())
                        .foregroundStyle(s.usable < 0 ? T.seal : T.ink)
                        .minimumScaleFactor(0.6).lineLimit(1).padding(.top, 6)
                    Text(s.daysLeft > 0 ? "每日可花 \(signed(s.daily))" : "本月已結束")
                        .font(.system(size: 11.5, weight: .light)).foregroundStyle(T.ink).padding(.top, 3)
                    Spacer(minLength: 8)
                    Track(pct: s.usePct, marker: s.isCurrentMonth ? s.timePct : nil, over: s.usePct > 100)
                    Text("預算用掉 \(Int(s.usePct))%・時間 \(Int(s.timePct))%")
                        .font(.system(size: 9.5, weight: .light).monospacedDigit())
                        .foregroundStyle(T.faint).padding(.top, 4)
                }
                VStack(spacing: 7) {
                    row("預算", money(s.total))
                    row("已花費", money(s.spent))
                    row("剩餘", signed(s.remain), s.remain < 0 ? T.seal : T.ink)
                    if s.reserve > 0 { row("房貸保留", money(s.reserve)) }
                    if s.daySpent > 0 { row("今日已花", money(s.daySpent)) }
                    row("剩餘天數", "\(s.daysLeft) 天")
                    Spacer(minLength: 0)
                }
                .frame(width: 132)
            }
        }
    }

    private func row(_ k: String, _ v: String, _ c: Color = T.ink) -> some View {
        HStack {
            Text(k).font(.system(size: 11, weight: .light)).foregroundStyle(T.mute)
            Spacer()
            Text(v).font(.system(size: 11, weight: .medium).monospacedDigit()).foregroundStyle(c)
        }
    }
}

// MARK: - 註冊

struct LedgerWidget: Widget {
    let kind = "LedgerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LedgerWidgetView(entry: entry)
        }
        .configurationDisplayName("記帳")
        .description("顯示本月可花費金額與剩餘預算。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LedgerWidgetBundle: WidgetBundle {
    var body: some Widget { LedgerWidget() }
}
