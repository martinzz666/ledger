import SwiftUI

// MARK: - 記一筆

struct EntryEditor: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State var entry: Entry
    @State private var amountText: String = ""

    private var isNew: Bool { !state.data.entries.contains { $0.id == entry.id } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $entry.kind) {
                    ForEach(Kind.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18).padding(.top, 12)
                .onChange(of: entry.kind) { _, _ in entry.category = "" }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Spacer()
                    Text("NT$").font(.system(size: 15)).foregroundStyle(T.mute)
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 38, weight: .ultraLight).monospacedDigit())
                        .fixedSize()
                }
                .padding(.horizontal, 22).padding(.vertical, 20)
                .overlay(alignment: .bottom) { Rectangle().fill(T.rule).frame(height: 1) }

                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(Categories.list(entry.kind), id: \.self) { c in
                            Button { entry.category = c } label: {
                                Text(c).font(.system(size: 14))
                                    .foregroundStyle(entry.category == c ? T.sheet : T.mute)
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(entry.category == c ? T.ink : Color.clear)
                                    .overlay(Rectangle().stroke(entry.category == c ? T.ink : T.rule, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                }

                VStack(spacing: 0) {
                    DatePicker("日期", selection: $entry.date, displayedComponents: .date)
                        .font(.system(size: 15)).padding(.vertical, 6)
                    TextField("備註", text: $entry.note)
                        .font(.system(size: 16)).padding(.vertical, 10)
                        .overlay(alignment: .bottom) { Rectangle().fill(T.rule).frame(height: 1) }
                }
                .padding(.horizontal, 18).padding(.bottom, 14)

                if !isNew {
                    Button("刪除這筆") { state.remove(entry); dismiss() }
                        .font(.system(size: 14)).foregroundStyle(T.seal).padding(.vertical, 14)
                }
            }
            .background(T.sheet)
            .navigationTitle(isNew ? "記一筆" : "修改")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        guard let v = Double(amountText), v > 0, !entry.category.isEmpty else { return }
                        entry.amount = v
                        state.upsert(entry)
                        dismiss()
                    }
                }
            }
        }
        .onAppear { amountText = entry.amount > 0 ? String(format: "%g", entry.amount) : "" }
    }
}

// MARK: - 房貸設定

struct LoanEditor: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var loan = Loan()
    @State private var amountText = ""
    @State private var rateText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("貸款金額") {
                        TextField("0", text: $amountText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("年利率 %") {
                        TextField("2.185", text: $rateText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Stepper("貸款年限　\(loan.years) 年", value: $loan.years, in: 1...40)
                    Stepper("寬限期　\(loan.graceYears) 年", value: $loan.graceYears, in: 0...10)
                    DatePicker("首期繳款日", selection: $loan.first, displayedComponents: .date)
                    Picker("還款方式", selection: $loan.method) {
                        Text(LoanMethod.annuity.label).tag(LoanMethod.annuity)
                        Text(LoanMethod.even.label).tag(LoanMethod.even)
                    }
                    TextField("記帳分類", text: $loan.category)
                } footer: {
                    Text("寬限期內只繳利息、不還本金。本息平均攤還每期金額固定；本金平均攤還前期負擔較重。")
                }
                if state.data.loan != nil {
                    Section {
                        Button("刪除房貸設定", role: .destructive) {
                            state.data.loan = nil; dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(T.sheet)
            .navigationTitle("房貸設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        guard let a = Double(amountText), a > 0,
                              let r = Double(rateText), r >= 0,
                              loan.graceYears < loan.years else { return }
                        loan.amount = a
                        loan.rate = r
                        if loan.category.isEmpty { loan.category = "房貸" }
                        state.data.loan = loan
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loan = state.data.loan ?? Loan()
            amountText = loan.amount > 0 ? String(format: "%g", loan.amount) : ""
            rateText = loan.rate > 0 ? String(format: "%g", loan.rate) : ""
        }
    }
}

// MARK: - 預算設定

struct BudgetEditor: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var totalText = ""
    @State private var includeLoan = true
    @State private var cats: [String: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("每月總預算") {
                        TextField("0", text: $totalText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("未繳房貸列入預算", isOn: $includeLoan)
                } footer: {
                    Text("每日可花 ＝（總預算 − 已花費 − 未繳房貸）÷ 本月剩餘天數。")
                }
                Section("分類預算（可留白）") {
                    ForEach(Categories.expense, id: \.self) { c in
                        LabeledContent(c) {
                            TextField("—", text: Binding(
                                get: { cats[c] ?? "" },
                                set: { cats[c] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
                if state.data.budget != nil {
                    Section {
                        Button("刪除預算設定", role: .destructive) {
                            state.data.budget = nil; dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(T.sheet)
            .navigationTitle("每月預算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        guard let t = Double(totalText), t > 0 else { return }
                        var map: [String: Double] = [:]
                        for (k, v) in cats { if let d = Double(v), d > 0 { map[k] = d } }
                        state.data.budget = Budget(total: t, cats: map, includeLoan: includeLoan)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            let b = state.data.budget
            totalText = (b?.total).map { String(format: "%g", $0) } ?? ""
            includeLoan = b?.includeLoan ?? true
            cats = (b?.cats ?? [:]).mapValues { String(format: "%g", $0) }
        }
    }
}

// MARK: - 分類標籤的自動換行排版

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
