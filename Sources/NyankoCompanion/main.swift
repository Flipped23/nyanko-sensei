import AppKit

let app=NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate=AppController()
app.delegate=delegate
app.run()
