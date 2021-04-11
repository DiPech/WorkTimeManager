import Cocoa

class StatusItemView: NSView {
    
    @IBOutlet weak var timer: NSTextField!
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var postponeAppStateMenuItem: NSMenuItem!
    
    private var appState: AppState!
    private var statusItemMenuState: StatusItemMenuState!
    private var timerColorState: TimerColorState!
    
    private var timerHelper: TimerHelper!
    
    private var idleBlackIcon: NSImage!
    private var idleWhiteIcon: NSImage!
    private var workBlackIcon: NSImage!
    private var workWhiteIcon: NSImage!
    private var walkBlackIcon: NSImage!
    private var walkWhiteIcon: NSImage!
    private var pauseBlackIcon: NSImage!
    private var pauseWhiteIcon: NSImage!
    private var focusBlackIcon: NSImage!
    private var focusWhiteIcon: NSImage!
    
    private var statusItem: NSStatusItem!
    private var statusItemMenu: NSMenu!
    
    public func myInit(statusItem: NSStatusItem, statusItemMenu: NSMenu) {
        self.statusItem = statusItem
        self.statusItemMenu = statusItemMenu
        // Init icons
        self.idleBlackIcon = NSImage(named: "idleBlackIcon")
        self.idleWhiteIcon = NSImage(named: "idleWhiteIcon")
        self.workBlackIcon = NSImage(named: "workBlackIcon")
        self.workWhiteIcon = NSImage(named: "workWhiteIcon")
        self.walkBlackIcon = NSImage(named: "walkBlackIcon")
        self.walkWhiteIcon = NSImage(named: "walkWhiteIcon")
        self.pauseBlackIcon = NSImage(named: "pauseBlackIcon")
        self.pauseWhiteIcon = NSImage(named: "pauseWhiteIcon")
        self.focusBlackIcon = NSImage(named: "focusBlackIcon")
        self.focusWhiteIcon = NSImage(named: "focusWhiteIcon")
        self.timerHelper = TimerHelper()
    }
    
    public func updateStates(
        appState: AppState,
        statusItemMenuState: StatusItemMenuState,
        timerColorState: TimerColorState
        ) {
        self.appState = appState
        self.statusItemMenuState = statusItemMenuState
        self.timerColorState = timerColorState
        redrawStates()
    }
    
    private func redrawStates() {
        var resultTimerColorState = self.timerColorState
        if (self.statusItemMenuState == StatusItemMenuState.SHOWN || isDarkMode) {
            resultTimerColorState = TimerColorState.WHITE
            if (self.appState == AppState.IDLE) {
                self.icon.image = self.idleWhiteIcon
                self.hideTimer()
            } else {
                if (self.appState == AppState.WORK) {
                    self.icon.image = self.workWhiteIcon
                } else if (self.appState == AppState.WALK) {
                    self.icon.image = self.walkWhiteIcon
                } else if (self.appState == AppState.PAUSE) {
                    self.icon.image = self.pauseWhiteIcon
                } else if (self.appState == AppState.FOCUS) {
                    self.icon.image = self.focusWhiteIcon
                }
                self.showTimer()
            }
        } else if (self.statusItemMenuState == StatusItemMenuState.HIDDEN) {
            if (self.appState == AppState.IDLE) {
                self.icon.image = self.idleBlackIcon
                self.hideTimer()
            } else {
                if (self.appState == AppState.WORK) {
                    self.icon.image = self.workBlackIcon
                } else if (self.appState == AppState.WALK) {
                    self.icon.image = self.walkBlackIcon
                } else if (self.appState == AppState.PAUSE) {
                    self.icon.image = self.pauseBlackIcon
                } else if (self.appState == AppState.FOCUS) {
                    self.icon.image = self.focusBlackIcon
                }
                self.showTimer()
            }
        }
        if (resultTimerColorState == TimerColorState.BLACK) {
            self.timer.textColor = NSColor.black
        } else if (resultTimerColorState == TimerColorState.RED) {
            self.timer.textColor = NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        } else if (resultTimerColorState == TimerColorState.GREEN) {
            self.timer.textColor = NSColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
        } else if (resultTimerColorState == TimerColorState.WHITE) {
            self.timer.textColor = NSColor.white
        }
        self.redraw()
    }
    
    public func setTimerSeconds(seconds: Int) {
        self.timer.stringValue = self.timerHelper.getTimerText(fromSeconds: seconds)
    }
    
    private func showTimer() {
        self.setFrameSize(NSSize(width: 65, height: 24))
        self.timer.isHidden = false
    }
    
    private func hideTimer() {
        self.setFrameSize(NSSize(width: 24, height: 24))
        self.timer.isHidden = true
    }
    
    private func redraw() {
        self.setNeedsDisplay(self.bounds)
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        self.statusItem.popUpMenu(self.statusItemMenu)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.statusItem.drawStatusBarBackground(
            in: self.bounds,
            withHighlight: self.statusItemMenuState == StatusItemMenuState.SHOWN
        )
    }
    
    var isDarkMode: Bool {
        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        return mode == "Dark"
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        NSApp.sendAction(postponeAppStateMenuItem.action!, to: postponeAppStateMenuItem.target, from: postponeAppStateMenuItem)
    }
    
}
