import Cocoa

class StatusItemMenu: NSMenu {
    
    @IBOutlet weak var toggleAppStateMenuItem: NSMenuItem!
    @IBOutlet weak var stopAppStateMenuItem: NSMenuItem!
    @IBOutlet weak var restartAppStateMenuItem: NSMenuItem!
    @IBOutlet weak var postponeAppStateMenuItem: NSMenuItem!
    
    public func updateStates(appState: AppState) {
        if (appState == AppState.IDLE) {
            self.stopAppStateMenuItem.isEnabled = false;
            self.restartAppStateMenuItem.isEnabled = false;
            self.postponeAppStateMenuItem.isEnabled = false;
            self.toggleAppStateMenuItem.title = "Start"
        } else {
            self.stopAppStateMenuItem.isEnabled = true;
            self.restartAppStateMenuItem.isEnabled = true;
            self.postponeAppStateMenuItem.isEnabled = appState == AppState.WORK;
            if (appState == AppState.PAUSE) {
                self.toggleAppStateMenuItem.title = "Resume"
            } else {
                self.toggleAppStateMenuItem.title = "Pause"
            }
        }
    }
    
}
