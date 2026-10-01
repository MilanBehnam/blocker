import DeviceActivity

class Monitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) { block() }
    override func intervalDidEnd(for activity: DeviceActivityName) { unblock() }
}
