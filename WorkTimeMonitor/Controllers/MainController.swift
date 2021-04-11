import Cocoa
import ServiceManagement

class MainController: NSObject, NSMenuDelegate, NSUserNotificationCenterDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var statusItemMenu: StatusItemMenu!
    @IBOutlet weak var statusItemView: StatusItemView!
    
    private var previousAppState: AppState!
    private var appState: AppState!
    private var statusItemMenuState: StatusItemMenuState!
    private var timerColorState: TimerColorState!
    
    private var preferencesController: NSWindowController!
    private var preferencesHelper: PreferencesHelper!
    
    private var lastActivityTimestamp: Int64 = -1

    private var workAudioPlayer: AudioPlayer!
    private var walkAudioPlayer: AudioPlayer!
    
    private var previousTime: Int = -1
    private var currentTime: Int = -1
    
    private var isDetected: Bool = false
    private var monitoringTimeDeltaCapacitor: Int64 = 0
    private var detectorTimeDeltaCapacitor: Int64 = 0
    private var audioVolumeTimeDeltaCapacitor: Int64 = 0
    private var previousMonitoringTimestamp: Int64 = -1
    private var previousDetectorTimestamp: Int64 = -1
    private var previousAudioVolumeTimestamp: Int64 = -1
    private var currentAudioVolume: Int = 100
    
    private var stopMonitoringTimestamp: Int64 = -1
    private var restartMonitoringAfter: Int64 = -1
    
    private var anyEventHandler: EventMonitor!
    private var inputMonitor: InputMonitor!
    
    private var appIcon: NSImage!
    
    override func awakeFromNib() {
        SMLoginItemSetEnabled("ru.dipech.AutoLaunchHelper" as CFString, true)
        self.appIcon = NSImage(named: "AppIcon")
        self.preferencesHelper = PreferencesHelper()
        self.currentAudioVolume = self.preferencesHelper.getMaxAudioVolume()
        let focusTime = self.preferencesHelper.getFocusTime()
        if (focusTime > 0) {
            self.currentTime = focusTime
        } else {
            self.currentTime = self.preferencesHelper.getWorkTime()
        }
        self.appState = AppState.IDLE
        self.previousAppState = AppState.IDLE
        self.statusItemMenuState = StatusItemMenuState.HIDDEN
        self.timerColorState = TimerColorState.BLACK
        statusItemView.myInit(statusItem: self.statusItem, statusItemMenu: self.statusItemMenu)
        self.workAudioPlayer = AudioPlayer(audioName: "needToWorkSound")
        self.walkAudioPlayer = AudioPlayer(audioName: "needToWalkSound")
        // Change statusItem view to custom (top menu view)
        self.statusItem.view = self.statusItemView;
        // Change menu
        self.statusItem.menu = self.statusItemMenu
        self.statusItem.highlightMode = true
        self.statusItemView.setTimerSeconds(seconds: self.currentTime)
        self.updateStatusItemViewStates()
        // Start timers
        let timerInterval = Double(0.05)
        let timerForMonitoring = Timer(timeInterval: timerInterval, target: self, selector: #selector(self.handleMonitoring), userInfo: nil, repeats: true)
        RunLoop.main.add(timerForMonitoring, forMode: RunLoop.Mode.common)
        let timerForAudioVolume = Timer(timeInterval: timerInterval, target: self, selector: #selector(self.handleAudioVolume), userInfo: nil, repeats: true)
        RunLoop.main.add(timerForAudioVolume, forMode: RunLoop.Mode.common)
        let timerForRestartMonitoring = Timer(timeInterval: timerInterval, target: self, selector: #selector(self.handleRestartMonitoring), userInfo: nil, repeats: true)
        RunLoop.main.add(timerForRestartMonitoring, forMode: RunLoop.Mode.common)
        anyEventHandler = EventMonitor(mask: .any, handler: { (event: NSEvent?) in
//            self.lastActivityTimestamp = self.getTimestampInMilliseconds()
            
            // ---- Dirty hack ----
            if (self.appState == AppState.WORK && self.currentTime > 0) {
                // do nothing
            } else if (self.appState == AppState.WALK && self.currentTime < self.preferencesHelper.getWorkTime()) {
                // do nothing
            } else {
                self.lastActivityTimestamp = self.getTimestampInMilliseconds()
            }
            // ---- ./ Dirty hack ----
            
            return event!
        })
        anyEventHandler.start()
        inputMonitor = InputMonitor(handler: {
//            self.lastActivityTimestamp = self.getTimestampInMilliseconds()
            
            // ---- Dirty hack ----
            if (self.appState == AppState.WORK && self.currentTime > 0) {
                // do nothing
            } else if (self.appState == AppState.WALK && self.currentTime < self.preferencesHelper.getWorkTime()) {
                // do nothing
            } else {
                self.lastActivityTimestamp = self.getTimestampInMilliseconds()
            }
            // ---- ./ Dirty hack ----
        })
        inputMonitor.start()
        toggleMonitoringAction(self)
    }
    
    private func currentTimeIsUpdatedEvent() {
        let workTime = self.preferencesHelper.getWorkTime()
        if (self.appState == AppState.WORK || self.appState == AppState.WALK) {
            // Определяем нужно ли проигрывать звук "иди пройдись"
            if (self.previousTime == 0 && self.currentTime > 0) {
                self.walkAudioPlayer.stop()
                self.timerColorState = TimerColorState.BLACK
            }
            if (self.previousTime > 0 && self.currentTime == 0) {
                if (self.preferencesHelper.isStartPlayAudioSmoothly()) {
                    self.currentAudioVolume = 1
                } else {
                    self.currentAudioVolume = self.preferencesHelper.getMaxAudioVolume()
                }
                self.updateWalkAudioVolume()
                self.walkAudioPlayer.play(needToRepeat: true)
                self.timerColorState = TimerColorState.RED
                if (self.preferencesHelper.isSendEndOfWorkNotification()) {
                    let notification = NSUserNotification()
                    notification.contentImage = self.appIcon
                    notification.title = "It's time to rest!"
                    notification.informativeText = "Stand up and do something..."
                    notification.soundName = NSUserNotificationDefaultSoundName
                    notification.hasActionButton = true
                    notification.actionButtonTitle = "Postpone"
                    NSUserNotificationCenter.default.delegate = self
                    NSUserNotificationCenter.default.deliver(notification)
                }
            }
            // Определяем нужно ли проигрывать звук "давай работать"
            if (self.previousTime == workTime && self.currentTime < workTime) {
                self.workAudioPlayer.stop()
                self.timerColorState = TimerColorState.BLACK
            }
            if (self.previousTime < workTime && self.currentTime == workTime) {
                self.workAudioPlayer.play(needToRepeat: false)
                self.timerColorState = TimerColorState.GREEN
            }
        } else if (self.appState == AppState.FOCUS) {
            if (self.previousTime > 0 && self.currentTime == 0) {
                self.appState = AppState.WORK
            }
        }
        self.previousTime = self.currentTime
        self.statusItemView.setTimerSeconds(seconds: self.currentTime)
        self.updateStatusItemViewStates()
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if (notification.activationType != .actionButtonClicked) {
            return
        }
        postponeAction(self)
    }
    
    @objc func handleRestartMonitoring() {
        if (self.appState != AppState.IDLE || self.stopMonitoringTimestamp < 0) {
            return;
        }
        let currentTimestamp = getTimestampInMilliseconds()
        if (currentTimestamp - self.stopMonitoringTimestamp >= self.restartMonitoringAfter * 1000) {
            restartMonitoring()
        }
    }
    
    @objc func handleMonitoring() {
        if (self.appState == AppState.IDLE || self.appState == AppState.PAUSE) {
            return;
        }
        
        // ---- Dirty hack ----
        if (self.appState == AppState.WORK && self.currentTime > 0) {
            self.lastActivityTimestamp = self.getTimestampInMilliseconds()
        } else if (self.appState == AppState.WALK && self.currentTime < self.preferencesHelper.getWorkTime()) {
            self.lastActivityTimestamp = 0
        }
        // ---- ./ Dirty hack ----
        
        let walkTime = self.preferencesHelper.getWalkTime()
        let workTime = self.preferencesHelper.getWorkTime()
        let focusTime = self.preferencesHelper.getFocusTime()
        var inacDetectTime = 5
        
        
        // ---- Dirty bug fix ----
        if (self.appState == AppState.FOCUS && self.currentTime <= inacDetectTime) {
            self.lastActivityTimestamp = self.getTimestampInMilliseconds()
        }
        // ---- ./ Dirty bug fix ----
        
        
        let undetectedPeriodDuration = getTimestampInMilliseconds() - self.lastActivityTimestamp
        
        // ---- Dirty hack ----
        if (self.appState == AppState.WORK) {
            if (self.currentTime > 0) {
//                inacDetectTime = self.preferencesHelper.getWorkTime()
            } else {
                inacDetectTime = 3
            }
        } else if (self.appState == AppState.WALK) {
//            inacDetectTime = self.preferencesHelper.getWalkTime()
        }
        let detected = undetectedPeriodDuration < inacDetectTime * 1000
        // ---- ./ Dirty hack ----
        
        if (detected) {
            if (self.appState == AppState.WALK) {
                if (self.currentTime == workTime) {
                    if (focusTime > 0) {
                        self.appState = AppState.FOCUS
                        self.currentTime = self.preferencesHelper.getFocusTime()
                    } else {
                        self.appState = AppState.WORK
                        self.currentTime = self.preferencesHelper.getWorkTime()
                    }
                } else {
                    self.appState = AppState.WORK
                }
            }
        } else {
            if (self.appState == AppState.WORK) {
                self.appState = AppState.WALK
            } else if (self.appState == AppState.WALK) {
                self.appState = AppState.WALK
            } else {
                self.appState = AppState.FOCUS
            }
        }
        self.updateStatusItemViewStates()
        self.updateStatusItemMenuStates()
        let isAppStateChanged = self.appState != self.previousAppState
        let isCurrentStateIsFocusButUserIsInactive = self.appState == AppState.FOCUS && !detected
        if (isAppStateChanged || isCurrentStateIsFocusButUserIsInactive) {
            self.timerColorState = TimerColorState.BLACK
            self.monitoringTimeDeltaCapacitor = 0
            self.previousMonitoringTimestamp = -1
            self.previousTime = -1
            if (isCurrentStateIsFocusButUserIsInactive) {
                if (self.appState == AppState.FOCUS) {
                    self.currentTime = focusTime
                }
            }
            if (self.appState == AppState.WORK && self.previousAppState == AppState.FOCUS) {
                self.currentTime = workTime
            }
            self.statusItemView.setTimerSeconds(seconds: self.currentTime)
            self.updateStatusItemViewStates()
        }
        self.previousAppState = self.appState
        if (self.previousMonitoringTimestamp < 0) {
            self.previousMonitoringTimestamp = getTimestampInMilliseconds()
        }
        let currentTimestamp = getTimestampInMilliseconds()
        self.monitoringTimeDeltaCapacitor += (currentTimestamp - self.previousMonitoringTimestamp)
        self.previousMonitoringTimestamp = currentTimestamp
        var timeDelta = Int64(0)
        if (self.appState == AppState.WORK || self.appState == AppState.FOCUS) {
            timeDelta = Int64(1000)
        } else if (self.appState == AppState.WALK) {
            timeDelta = Int64((Double(walkTime) / Double(workTime)) * 1000)
        }
        if (self.monitoringTimeDeltaCapacitor > timeDelta) {
            self.monitoringTimeDeltaCapacitor -= timeDelta
            if (self.previousTime < 0) {
                self.previousTime = self.currentTime
            }
            if (self.appState == AppState.WORK || self.appState == AppState.FOCUS) {
                self.currentTime = self.currentTime - 1
            } else {
                self.currentTime = self.currentTime + 1
            }
            if (self.currentTime < 0) {
                self.currentTime = 0
            }
            if (self.currentTime > workTime) {
                self.currentTime = workTime
            }
            self.currentTimeIsUpdatedEvent()
        }
    }
    
    @objc func handleAudioVolume() {
        if (self.previousAudioVolumeTimestamp < 0) {
            self.previousAudioVolumeTimestamp = getTimestampInMilliseconds()
        }
        let currentTimestamp = getTimestampInMilliseconds()
        self.audioVolumeTimeDeltaCapacitor += (currentTimestamp - self.previousAudioVolumeTimestamp)
        self.previousAudioVolumeTimestamp = currentTimestamp
        let timeDelta = Int64(2000)
        if (self.audioVolumeTimeDeltaCapacitor > timeDelta) {
            self.audioVolumeTimeDeltaCapacitor -= timeDelta
            self.runAudioVolume()
        }
    }
    
    private func runAudioVolume() {
        self.currentAudioVolume = self.currentAudioVolume + 1
        if (self.currentAudioVolume > self.preferencesHelper.getMaxAudioVolume()) {
            self.currentAudioVolume = self.preferencesHelper.getMaxAudioVolume()
        }
        self.updateWalkAudioVolume()
    }
    
    private func updateWalkAudioVolume() {
        self.walkAudioPlayer.setVolume(volume: self.currentAudioVolume)
    }
    
    private func getTimestampInMilliseconds() -> Int64
    {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    private func updateStatusItemViewStates() {
        self.statusItemView.updateStates(
            appState: self.appState,
            statusItemMenuState: self.statusItemMenuState,
            timerColorState: self.timerColorState
        )
    }
    
    private func updateStatusItemMenuStates() {
        self.statusItemMenu.updateStates(appState: self.appState)
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        self.statusItemMenuState = StatusItemMenuState.SHOWN
        self.updateStatusItemViewStates()
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.statusItemMenuState = StatusItemMenuState.HIDDEN
        self.updateStatusItemViewStates()
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    @IBAction func stopMonitoringActionFor30Min(_ sender: Any) {
        self.restartMonitoringAfter = 30 * 60
        stopMonitoring()
    }
    
    @IBAction func stopMonitoringActionFor1Hour(_ sender: Any) {
        self.restartMonitoringAfter = 60 * 60
        stopMonitoring()
    }
    
    @IBAction func stopMonitoringActionFor2Hours(_ sender: Any) {
        self.restartMonitoringAfter = 2 * 60 * 60
        stopMonitoring()
    }
    
    @IBAction func stopMonitoringActionFor3Hours(_ sender: Any) {
        self.restartMonitoringAfter = 3 * 60 * 60
        stopMonitoring()
    }
    
    @IBAction func stopMonitoringActionFor6Hours(_ sender: Any) {
        self.restartMonitoringAfter = 6 * 60 * 60
        stopMonitoring()
    }
    
    @IBAction func stopMonitoringActionFor12Hours(_ sender: Any) {
        self.restartMonitoringAfter = 12 * 60 * 60
        stopMonitoring()
    }
    
    func stopMonitoring() {
        self.workAudioPlayer.stop()
        self.walkAudioPlayer.stop()
        self.previousMonitoringTimestamp = -1
        self.previousDetectorTimestamp = -1
        self.previousTime = -1
        self.monitoringTimeDeltaCapacitor = 0
        self.detectorTimeDeltaCapacitor = 0
        self.currentTime = self.preferencesHelper.getWorkTime()
        self.appState = AppState.IDLE
        self.previousAppState = self.appState
        self.updateStatusItemViewStates()
        self.updateStatusItemMenuStates()
        self.stopMonitoringTimestamp = getTimestampInMilliseconds()
    }
    
    @IBAction func restartMonitoringAction(_ sender: Any) {
        restartMonitoring()
    }
    
    func restartMonitoring() {
       stopMonitoring()
       toggleMonitoring()
    }
    
    @IBAction func postponeAction(_ sender: Any) {
        self.workAudioPlayer.stop()
        self.walkAudioPlayer.stop()
        self.previousMonitoringTimestamp = -1
        self.previousDetectorTimestamp = -1
        self.previousTime = -1
        self.monitoringTimeDeltaCapacitor = 0
        self.detectorTimeDeltaCapacitor = 0
        if (self.appState == AppState.WORK) {
            self.currentTime += 60
        } else {
            self.currentTime = 60
        }
        self.appState = AppState.WORK
        self.previousAppState = self.appState
        self.updateStatusItemViewStates()
        self.updateStatusItemMenuStates()
    }
    
    @IBAction func toggleMonitoringAction(_ sender: Any) {
        toggleMonitoring()
    }
    
    func toggleMonitoring() {
        self.workAudioPlayer.stop()
        self.walkAudioPlayer.stop()
        if (self.appState == AppState.IDLE) {
            self.previousAppState = self.appState
            let focusTime = self.preferencesHelper.getFocusTime()
            if (focusTime > 0) {
                self.appState = AppState.FOCUS
                self.currentTime = self.preferencesHelper.getFocusTime()
            } else {
                self.appState = AppState.WORK
                self.currentTime = self.preferencesHelper.getWorkTime()
            }
            self.stopMonitoringTimestamp = -1
        } else if (self.appState == AppState.PAUSE) {
            if (self.previousAppState == AppState.IDLE || self.previousAppState == AppState.PAUSE) {
                self.previousAppState = AppState.WORK
            }
            self.previousDetectorTimestamp = -1
            self.previousMonitoringTimestamp = -1
            self.previousTime = -1
            self.appState = self.previousAppState
            self.stopMonitoringTimestamp = -1
        } else {
            self.previousAppState = self.appState
            self.appState = AppState.PAUSE
        }
        self.updateStatusItemViewStates()
        self.updateStatusItemMenuStates()
    }
    
    @IBAction func openPreferencesAction(_ sender: Any) {
        if (self.preferencesController == nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: nil)
            self.preferencesController = storyboard.instantiateInitialController() as? NSWindowController
        }
        if (self.preferencesController != nil) {
            self.preferencesController!.showWindow(sender)
        }
    }
    
    @IBAction func quitAction(_ sender: Any) {
        NSApplication.shared.terminate(self);
    }
    
}
