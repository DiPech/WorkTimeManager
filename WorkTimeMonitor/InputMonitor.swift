import Foundation
import Cocoa
import Swift
import IOKit.hid

public class InputMonitor {
    
    private let handler: () -> ()
    
    private let manager: IOHIDManager
    private var deviceList = NSArray()

    public init(handler: @escaping () -> ()) {
        self.handler = handler
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        deviceList = deviceList.adding(CreateDeviceMatchingDictionary(inUsagePage: kHIDPage_GenericDesktop, inUsage: kHIDUsage_GD_Keyboard)) as NSArray
        deviceList = deviceList.adding(CreateDeviceMatchingDictionary(inUsagePage: kHIDPage_GenericDesktop, inUsage: kHIDUsage_GD_Keypad)) as NSArray
        IOHIDManagerSetDeviceMatchingMultiple(manager, deviceList as CFArray)
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, sender, device in
            let mySelf = Unmanaged<InputMonitor>.fromOpaque(context!).takeUnretainedValue()
            mySelf.callback()
        }, observer)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, sender, device in
            let mySelf = Unmanaged<InputMonitor>.fromOpaque(context!).takeUnretainedValue()
            mySelf.callback()
        }, observer)
        IOHIDManagerRegisterInputValueCallback(manager, { context, result, sender, device in
            let mySelf = Unmanaged<InputMonitor>.fromOpaque(context!).takeUnretainedValue()
            IOHIDValueGetElement(device );
            IOHIDValueGetIntegerValue(device);
            mySelf.callback()
        }, observer)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone));
    }
    
    func callback() {
        self.handler();
    }

    deinit {
        stop()
    }

    public func start() {
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    public func stop() {
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue);
    }
    
    private func CreateDeviceMatchingDictionary(inUsagePage: Int ,inUsage: Int ) -> CFMutableDictionary {
        let resultAsSwiftDic = [kIOHIDDeviceUsagePageKey: inUsagePage, kIOHIDDeviceUsageKey : inUsage]
        let resultAsCFDic: CFMutableDictionary = resultAsSwiftDic as! CFMutableDictionary
        return resultAsCFDic
    }
    
}
