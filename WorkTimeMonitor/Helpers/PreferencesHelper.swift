import Cocoa

class PreferencesHelper {
    
    init() {
        self.prepare()
    }
    
    public func setWorkTime(seconds: Int!) {
        UserDefaults.standard.set(seconds, forKey: "workTime")
        UserDefaults.standard.synchronize()
    }
    
    public func setWalkTime(seconds: Int!) {
        UserDefaults.standard.set(seconds, forKey: "walkTime")
        UserDefaults.standard.synchronize()
    }
    
    public func setFocusTime(seconds: Int!) {
        UserDefaults.standard.set(seconds, forKey: "focusTime")
        UserDefaults.standard.synchronize()
    }
    
    public func setMaxAudioVolume(percentage: Int!) {
        UserDefaults.standard.set(percentage, forKey: "maxAudioVolume")
        UserDefaults.standard.synchronize()
    }
    
    public func setStartPlayAudioSmoothly(bool: Bool!) {
        UserDefaults.standard.set(bool, forKey: "startPlayAudioSmoothly")
        UserDefaults.standard.synchronize()
    }
    
    public func setSendEndOfWorkNotification(bool: Bool!) {
        UserDefaults.standard.set(bool, forKey: "sendEndOfWorkNotification")
        UserDefaults.standard.synchronize()
    }
    
    public func getWorkTime() -> Int {
//        return 30
        return UserDefaults.standard.integer(forKey: "workTime")
    }
    
    public func getWalkTime() -> Int {
//        return 10
        return UserDefaults.standard.integer(forKey: "walkTime")
    }
    
    public func getFocusTime() -> Int {
//        return 10
        return UserDefaults.standard.integer(forKey: "focusTime")
    }
    
    public func getMaxAudioVolume() -> Int {
        return UserDefaults.standard.integer(forKey: "maxAudioVolume")
    }
    
    public func isStartPlayAudioSmoothly() -> Bool {
        return UserDefaults.standard.bool(forKey: "startPlayAudioSmoothly")
    }
    
    public func isSendEndOfWorkNotification() -> Bool {
        return UserDefaults.standard.bool(forKey: "sendEndOfWorkNotification")
    }
    
    private func prepare() {
        if (UserDefaults.standard.value(forKey: "workTime") == nil) {
            self.setWorkTime(seconds: 25 * 60)
        }
        if (UserDefaults.standard.value(forKey: "walkTime") == nil) {
            self.setWalkTime(seconds: 5 * 60)
        }
        if (UserDefaults.standard.value(forKey: "focusTime") == nil) {
            self.setFocusTime(seconds: 15)
        }
        if (UserDefaults.standard.value(forKey: "maxAudioVolume") == nil) {
            self.setMaxAudioVolume(percentage: 50)
        }
        if (UserDefaults.standard.value(forKey: "startPlayAudioSmoothly") == nil) {
            self.setStartPlayAudioSmoothly(bool: true)
        }
        if (UserDefaults.standard.value(forKey: "sendEndOfWorkNotification") == nil) {
            self.setSendEndOfWorkNotification(bool: true)
        }
        UserDefaults.standard.synchronize()
    }
    
    public func reset() {
        self.setWorkTime(seconds: nil)
        self.setWalkTime(seconds: nil)
        self.setFocusTime(seconds: nil)
        self.setMaxAudioVolume(percentage: nil)
        self.setStartPlayAudioSmoothly(bool: true)
        self.setSendEndOfWorkNotification(bool: nil)
        self.prepare()
    }
    
}
