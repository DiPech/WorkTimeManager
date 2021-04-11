import Cocoa

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var workTimeSlider: NSSlider!
    @IBOutlet weak var workTimeSliderLabel: NSTextField!
    @IBOutlet weak var walkTimeSlider: NSSlider!
    @IBOutlet weak var walkTimeSliderLabel: NSTextField!
    @IBOutlet weak var focusTimeSlider: NSSlider!
    @IBOutlet weak var focusTimeSliderLabel: NSTextField!
    @IBOutlet weak var maxAudioVolumeSlider: NSSlider!
    @IBOutlet weak var maxAudioVolumeSliderLabel: NSTextField!
    @IBOutlet weak var startPlayAudioSmoothlyCheckbox: NSButton!
    @IBOutlet weak var sendEndOfWorkNotificationCheckbox: NSButton!
    
    private var timerHelper: TimerHelper!
    private var preferencesHelper: PreferencesHelper!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.workTimeSlider.isContinuous = true
        self.walkTimeSlider.isContinuous = true
        self.focusTimeSlider.isContinuous = true
        self.maxAudioVolumeSlider.isContinuous = true
        self.timerHelper = TimerHelper()
        self.preferencesHelper = PreferencesHelper()
        self.syncControlsValues()
    }
    
    private func syncControlsValues() {
        let workTime = self.preferencesHelper.getWorkTime()
        self.workTimeSlider.integerValue = workTime / 60
        self.workTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: workTime)
        let walkTime = self.preferencesHelper.getWalkTime()
        self.walkTimeSlider.integerValue = walkTime / 60
        self.walkTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: walkTime)
        let focusTime = self.preferencesHelper.getFocusTime()
        self.focusTimeSlider.integerValue = focusTime
        self.focusTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: focusTime)
        let maxAudioVolume = self.preferencesHelper.getMaxAudioVolume()
        self.maxAudioVolumeSlider.integerValue = maxAudioVolume
        self.maxAudioVolumeSliderLabel.stringValue = String(maxAudioVolume) + "%"
        let isStartPlayAudioSmoothly = self.preferencesHelper.isStartPlayAudioSmoothly()
        self.startPlayAudioSmoothlyCheckbox.state = isStartPlayAudioSmoothly ? NSControl.StateValue.on : NSControl.StateValue.off
        let isSendEndOfWorkNotification = self.preferencesHelper.isSendEndOfWorkNotification()
        self.sendEndOfWorkNotificationCheckbox.state = isSendEndOfWorkNotification ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @IBAction func workTimeSliderChangeAction(_ sender: Any) {
        let seconds = self.workTimeSlider.integerValue * 60
        self.workTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: seconds)
        self.preferencesHelper.setWorkTime(seconds: seconds)
    }
    
    @IBAction func walkTimeSliderChangeAction(_ sender: Any) {
        let seconds = self.walkTimeSlider.integerValue * 60
        self.walkTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: seconds)
        self.preferencesHelper.setWalkTime(seconds: seconds)
    }
    
    @IBAction func focusTimeSliderChangeAction(_ sender: Any) {
        let seconds = self.focusTimeSlider.integerValue
        self.focusTimeSliderLabel.stringValue = self.timerHelper.getTimerText(fromSeconds: seconds)
        self.preferencesHelper.setFocusTime(seconds: seconds)
    }
    
    @IBAction func maxAudioVolumeSliderChangeAction(_ sender: Any) {
        let percentage = self.maxAudioVolumeSlider.integerValue
        self.maxAudioVolumeSliderLabel.stringValue = String(percentage) + "%"
        self.preferencesHelper.setMaxAudioVolume(percentage: percentage)
    }
    
    @IBAction func startPlayAudioSmoothlyCheckboxChangeAction(_ sender: Any) {
        let bool = self.startPlayAudioSmoothlyCheckbox.state == NSControl.StateValue.on
        self.preferencesHelper.setStartPlayAudioSmoothly(bool: bool)
    }
    
    @IBAction func sendEndOfWorkNotificationCheckboxChangeAction(_ sender: Any) {
        let bool = self.sendEndOfWorkNotificationCheckbox.state == NSControl.StateValue.on
        self.preferencesHelper.setSendEndOfWorkNotification(bool: bool)
    }
    
    @IBAction func resetToDefaultsAction(_ sender: Any) {
        self.preferencesHelper.reset()
        self.syncControlsValues()
    }
    
}
