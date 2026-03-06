import Foundation

extension TimeStamp {

 internal static let utcCalendar: Calendar = {
    var calendar: Calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()
}
