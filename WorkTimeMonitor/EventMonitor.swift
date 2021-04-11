import Foundation
import Cocoa

public class EventMonitor {

    private var globalMonitor: AnyObject?
    private var localMonitor: AnyObject?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> NSEvent

    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> NSEvent) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    public func start() {
//        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String : true]
//        AXIsProcessTrustedWithOptions(options)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { (event: NSEvent?) in
            let ev = self.handler(event)
            return ev
        }) as AnyObject?
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { (event: NSEvent?) in
            let _ = self.handler(event)
        }) as AnyObject?
    }

    public func stop() {
        if globalMonitor != nil {
            NSEvent.removeMonitor(globalMonitor!)
            globalMonitor = nil
        }
        if localMonitor != nil {
            NSEvent.removeMonitor(localMonitor!)
            localMonitor = nil
        }
    }
}
