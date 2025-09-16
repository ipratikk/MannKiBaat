import Foundation

enum PeriodFilter: String, CaseIterable {
    case all
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
    
    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return true
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .quarter:
            guard
                let month = calendar.dateComponents([.month], from: date).month,
                let nowMonth = calendar.dateComponents([.month], from: now).month
            else { return false }
            
            let quarter = (month - 1) / 3
            let currentQuarter = (nowMonth - 1) / 3
            return quarter == currentQuarter &&
            calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}
