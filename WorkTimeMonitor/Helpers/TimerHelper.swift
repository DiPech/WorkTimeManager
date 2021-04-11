class TimerHelper {
    
    public func getTimerText(fromSeconds: Int) -> String {
        var (hours, minutes, seconds) = secondsToHoursMinutesSeconds(seconds: fromSeconds)
        minutes = minutes + 60 * hours
        let minutesText = (minutes < 10 ? "0" : "") + String(minutes)
        let secondsText = (seconds < 10 ? "0" : "") + String(seconds)
        return minutesText + ":" + secondsText
    }

    public func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
}
