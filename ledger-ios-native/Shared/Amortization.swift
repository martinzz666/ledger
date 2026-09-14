import Foundation

struct Installment: Identifiable, Hashable {
    let term: Int
    let date: Date
    let payment: Double
    let principal: Double
    let interest: Double
    let balance: Double
    var id: Int { term }
}

enum Amortization {

    /// 完整攤還表。寬限期內只繳息；最後一期補足餘額，確保餘額歸零。
    static func schedule(_ loan: Loan) -> [Installment] {
        let n = max(loan.years * 12, 1)
        let g = min(max(loan.graceYears, 0) * 12, n - 1)
        let r = loan.rate / 100 / 12
        let m = max(n - g, 1)

        let fixed: Double = r > 0
            ? loan.amount * r / (1 - pow(1 + r, Double(-m)))
            : loan.amount / Double(m)
        let evenPrincipal = loan.amount / Double(m)

        let cal = Calendar.current
        var balance = loan.amount
        var rows: [Installment] = []
        rows.reserveCapacity(n)

        for k in 1...n {
            let interest = balance * r
            var principal: Double
            if k <= g {
                principal = 0
            } else {
                principal = loan.method == .annuity ? fixed - interest : evenPrincipal
            }
            if k == n { principal = balance }
            principal = min(max(principal, 0), balance)

            let date = cal.date(byAdding: .month, value: k - 1, to: loan.first) ?? loan.first
            balance -= principal
            rows.append(Installment(term: k, date: date,
                                    payment: principal + interest,
                                    principal: principal,
                                    interest: interest,
                                    balance: max(balance, 0)))
        }
        return rows
    }

    static func totalInterest(_ loan: Loan) -> Double {
        schedule(loan).reduce(0) { $0 + $1.interest }
    }
}
