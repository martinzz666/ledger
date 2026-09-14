import SwiftUI

struct LoanView: View {
    @EnvironmentObject var state: AppState
    @State private var showEditor = false
    @State private var page = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("房屋貸款").font(.system(size: 15, weight: .medium)).kerning(1)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                    if let loan = state.data.loan { content(loan) } else { empty }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
            .background(T.paper)
            .toolbarBackground(T.paper, for: .navigationBar)
        }
        .sheet(isPresented: $showEditor) { LoanEditor().environmentObject(state) }
        .onAppear { page = max(0, (nextIndex - 2) / 12) }
    }

    private var rows: [Installment] {
        state.data.loan.map { Amortization.schedule($0) } ?? []
    }
    private var paid: Set<Int> { Stats.paidTerms(state.data) }
    private var nextIndex: Int { rows.firstIndex { !paid.contains($0.term) } ?? 0 }

    private var empty: some View {
        VStack(spacing: 18) {
            Text("尚未設定房屋貸款\n設定後可看到每期應繳金額與繳納進度")
                .font(.system(size: 14)).foregroundStyle(T.faint)
                .multilineTextAlignment(.center).lineSpacing(8)
            Button("設定房貸") { showEditor = true }
                .font(.system(size: 13.5)).foregroundStyle(T.mute)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func content(_ loan: Loan) -> some View {
        let all = rows
        let paidRows = all.filter { paid.contains($0.term) }
        let paidPrincipal = paidRows.reduce(0) { $0 + $1.principal }
        let paidInterest = paidRows.reduce(0) { $0 + $1.interest }
        let totalInterest = all.reduce(0) { $0 + $1.interest }
        let next = all.first { !paid.contains($0.term) }
        let overdue = all.filter { !paid.contains($0.term) && $0.date < Date() }
        let pct = all.isEmpty ? 0 : Double(paidRows.count) / Double(all.count) * 100
        let graceN = loan.graceYears * 12

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("NT$").font(.system(size: 16)).foregroundStyle(T.mute)
                Text(money(next?.payment ?? 0))
                    .font(.system(size: 40, weight: .ultraLight).monospacedDigit())
            }
            .padding(.top, 4)
            Text(next.map { "第 \($0.term) 期應繳金額" } ?? "已全部繳清")
                .font(.system(size: 12.5)).kerning(1.2).foregroundStyle(T.mute).padding(.top, 9)

            Track(pct: pct).padding(.top, 22)
            HStack {
                Text("已繳 \(paidRows.count) / \(all.count) 期")
                Spacer()
                Text(String(format: "%.1f%%", pct))
            }
            .font(.system(size: 12.5).monospacedDigit()).foregroundStyle(T.mute).padding(.top, 7)

            if let n = next { dueCard(n) }

            Group {
                KeyLine(k: "貸款金額", v: money(loan.amount))
                KeyLine(k: "年利率 / 年限", v: "\(loan.rate)% / \(loan.years) 年")
                if graceN > 0, graceN <= all.count {
                    KeyLine(k: "寬限期", v: "\(graceN) 期（至 \(all[graceN - 1].date.ymd)）")
                }
                KeyLine(k: "還款方式", v: loan.method.label)
                KeyLine(k: "剩餘本金", v: money(loan.amount - paidPrincipal))
                KeyLine(k: "已償本金", v: money(paidPrincipal))
                KeyLine(k: "已付利息", v: money(paidInterest))
                KeyLine(k: "總利息（估）", v: money(totalInterest))
                KeyLine(k: "本息合計", v: money(totalInterest + loan.amount))
                if !overdue.isEmpty {
                    KeyLine(k: "逾期未繳",
                            v: "\(overdue.count) 期・\(money(overdue.reduce(0) { $0 + $1.payment }))",
                            color: T.seal)
                }
            }
            .padding(.top, 4)

            pager(all)
            ForEach(pageRows(all)) { r in termRow(r) }

            Button("修改設定") { showEditor = true }
                .font(.system(size: 13.5)).foregroundStyle(T.mute).padding(.top, 26)
        }
    }

    private func dueCard(_ n: Installment) -> some View {
        let late = n.date < Date()
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(late ? "逾期未繳" : "下期繳款")　\(n.date.ymd)")
                    .font(.system(size: 13)).foregroundStyle(late ? T.seal : T.mute)
                Text("NT$ \(money(n.payment))")
                    .font(.system(size: 19, weight: .light).monospacedDigit())
            }
            Spacer()
            Button("記為已繳") { state.pay(n) }
                .font(.system(size: 14)).foregroundStyle(T.ink)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .overlay(Rectangle().stroke(T.ink, lineWidth: 1))
        }
        .padding(16)
        .overlay(Rectangle().stroke(late ? T.seal : T.rule, lineWidth: 1))
        .padding(.top, 20)
    }

    private func pageRows(_ all: [Installment]) -> [Installment] {
        let start = min(max(page, 0) * 12, max(all.count - 1, 0))
        return Array(all[start..<min(start + 12, all.count)])
    }

    private func pager(_ all: [Installment]) -> some View {
        let start = min(max(page, 0) * 12, max(all.count - 1, 0))
        let end = min(start + 12, all.count)
        return HStack {
            Button { page = max(page - 1, 0) } label: {
                Image(systemName: "chevron.left").foregroundStyle(T.faint)
            }.frame(width: 44, height: 36)
            Spacer()
            Text("第 \(start + 1) – \(end) 期，共 \(all.count) 期")
                .font(.system(size: 12.5)).foregroundStyle(T.mute)
            Spacer()
            Button { page = min(page + 1, (all.count - 1) / 12) } label: {
                Image(systemName: "chevron.right").foregroundStyle(T.faint)
            }.frame(width: 44, height: 36)
        }
        .padding(.top, 26)
    }

    private func termRow(_ r: Installment) -> some View {
        let isPaid = paid.contains(r.term)
        let late = !isPaid && r.date < Date()
        return HStack(spacing: 12) {
            Text("\(r.term)").font(.system(size: 12.5).monospacedDigit())
                .foregroundStyle(late ? T.seal : T.faint).frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(r.date.ymd)　NT$ \(money(r.payment))")
                    .font(.system(size: 15).monospacedDigit())
                    .foregroundStyle(isPaid ? T.mute : T.ink)
                Text("本金 \(money(r.principal))・利息 \(money(r.interest))・餘額 \(money(r.balance))")
                    .font(.system(size: 12).monospacedDigit()).foregroundStyle(T.faint)
            }
            Spacer()
            Button {
                isPaid ? state.unpay(term: r.term) : state.pay(r)
            } label: {
                Text(isPaid ? "已繳" : (late ? "逾期" : "繳款"))
                    .font(.system(size: 12.5))
                    .foregroundStyle(isPaid ? T.paper : (late ? T.seal : T.mute))
                    .frame(width: 64, height: 34)
                    .background(isPaid ? T.ink : Color.clear)
                    .overlay(Rectangle().stroke(isPaid ? T.ink : (late ? T.seal : T.rule), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(T.rule).frame(height: 1) }
    }
}
