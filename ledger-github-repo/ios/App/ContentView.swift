import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var tab = 0
    @State private var newEntry: Entry? = nil

    var body: some View {
        TabView(selection: $tab) {
            MonthView().tabItem { Text("明細") }.tag(0)
            BudgetView().tabItem { Text("預算") }.tag(1)
            YearView().tabItem { Text("年度") }.tag(2)
            LoanView().tabItem { Text("房貸") }.tag(3)
        }
        .background(T.paper)
    }
}

/// 月份切換列
struct MonthHeader: View {
    @EnvironmentObject var state: AppState
    var body: some View {
        HStack {
            Button { state.shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").foregroundStyle(T.faint)
            }
            .frame(width: 44, height: 44)
            Spacer()
            Text(label).font(.system(size: 15, weight: .medium)).kerning(1)
            Spacer()
            Button { state.shiftMonth(1) } label: {
                Image(systemName: "chevron.right").foregroundStyle(T.faint)
            }
            .frame(width: 44, height: 44)
        }
    }
    private var label: String {
        let c = Calendar.current.dateComponents([.year, .month], from: state.month)
        return "\(c.year ?? 0) 年 \(c.month ?? 0) 月"
    }
}
