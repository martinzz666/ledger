import SwiftUI

/// 無印風配色：未漂白紙色底、墨色文字、細線分隔
enum T {
    static let paper = Color(red: 239/255, green: 237/255, blue: 232/255)
    static let sheet = Color(red: 250/255, green: 249/255, blue: 246/255)
    static let rule  = Color(red: 218/255, green: 214/255, blue: 204/255)
    static let ink   = Color(red:  46/255, green:  44/255, blue:  41/255)
    static let mute  = Color(red: 142/255, green: 136/255, blue: 128/255)
    static let faint = Color(red: 182/255, green: 176/255, blue: 166/255)
    static let sage  = Color(red: 111/255, green: 127/255, blue: 104/255)
    static let seal  = Color(red: 140/255, green:  59/255, blue:  52/255)
}

func money(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v.rounded())) ?? "0"
}

/// 負數以「−」呈現，維持等寬對齊
func signed(_ v: Double) -> String {
    (v < 0 ? "−" : "") + money(abs(v))
}

extension Date {
    var ymd: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
    var mdWeek: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_Hant_TW")
        f.dateFormat = "M月d日　EEEE"
        return f.string(from: self)
    }
}

/// 細進度條，可標出時間進度刻度
struct Track: View {
    var pct: Double
    var marker: Double? = nil
    var over: Bool = false

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Rectangle().fill(T.rule).frame(height: 1).offset(y: 1)
                Rectangle().fill(over ? T.seal : T.ink)
                    .frame(width: max(g.size.width * min(pct, 100) / 100, 1), height: 3)
                if let m = marker {
                    Rectangle().fill(T.faint)
                        .frame(width: 1, height: 9)
                        .offset(x: min(g.size.width * m / 100, g.size.width - 1), y: -3)
                }
            }
        }
        .frame(height: 9)
    }
}

struct KeyLine: View {
    var k: String
    var v: String
    var color: Color = T.ink
    var body: some View {
        HStack {
            Text(k).font(.system(size: 14.5)).foregroundStyle(T.mute)
            Spacer()
            Text(v).font(.system(size: 14.5).monospacedDigit()).foregroundStyle(color)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Rectangle().fill(T.rule).frame(height: 1) }
    }
}
