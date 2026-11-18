import AppKit

class AppController: NSObject, NSApplicationDelegate {
    var panel: PetPanel!
    var pet: PetView!
    var status: NSStatusItem!
    var prefs = Preferences()
    var animations: [String:[NSImage]] = [:]
    var specs: [String:AnimationSpec] = [:]
    var timer: Timer?
    var current = "idle"
    var started = Date()
    var until = Date.distantPast
    var bubble = ""
    var bubbleUntil = Date.distantPast
    var dragPreview = false
    var moving = false
    var trashBusy = false
    var lastMouse = NSEvent.mouseLocation
    var lastMouseTime = Date()
    var lastRush = Date.distantPast
    var lastWheel = Date.distantPast
    var appNap: NSObjectProtocol?
    var lastTick = Date()
    var saveURL: URL {
        if let i=CommandLine.arguments.firstIndex(of:"--test-data"),CommandLine.arguments.count>i+1 {return URL(fileURLWithPath:CommandLine.arguments[i+1])}
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("NyankoCompanion", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("preferences.json")
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let data = try? Data(contentsOf: saveURL), let saved = try? JSONDecoder().decode(Preferences.self, from: data) { prefs = saved }
        loadAssets()
        guard !animations.isEmpty else { fatalError("Missing animation resources") }
        let size = CGFloat(prefs.size)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x:0,y:0,width:1200,height:800)
        let origin = NSPoint(x:prefs.x ?? screen.maxX-size-50, y:prefs.y ?? screen.minY+45)
        panel = PetPanel(contentRect:NSRect(origin:origin,size:NSSize(width:size,height:size*1.2)), styleMask:[.borderless,.nonactivatingPanel], backing:.buffered, defer:false)
        panel.title = "猫咪老师桌面伴侣"
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces,.fullScreenAuxiliary,.stationary]
        panel.isMovableByWindowBackground = false; panel.isReleasedWhenClosed = false
        pet = PetView(frame:NSRect(origin:.zero,size:panel.frame.size)); pet.controller = self; panel.contentView = pet
        keepOnScreen()
        status = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
        status.button?.title = "猫咪老师"
        status.button?.toolTip = "桌面伴侣 · 点击管理"
        rebuildMenu()
        panel.orderFrontRegardless()
        timer = Timer(timeInterval:1.0/30.0,target:self,selector:#selector(tick),userInfo:nil,repeats:true)
        RunLoop.main.add(timer!,forMode:.common)
        NSWorkspace.shared.notificationCenter.addObserver(self,selector:#selector(woke),name:NSWorkspace.didWakeNotification,object:nil)
        play("wave",message:"你好呀！右键我可以设置动作和提醒。",duration:5)
        if let i=CommandLine.arguments.firstIndex(of:"--demo"),CommandLine.arguments.count>i+1 { play(CommandLine.arguments[i+1],duration:15) }
        if CommandLine.arguments.contains("--smoke-test") { DispatchQueue.main.asyncAfter(deadline:.now()+3) { self.runSmokeTest(); NSApp.terminate(nil) } }
        if CommandLine.arguments.contains("--integration-test") {DispatchQueue.main.asyncAfter(deadline:.now()+0.5){self.integrationTest()}}
        if let i=CommandLine.arguments.firstIndex(of:"--export-previews"),CommandLine.arguments.count>i+1 {DispatchQueue.main.asyncAfter(deadline:.now()+0.3){self.exportPreviews(URL(fileURLWithPath:CommandLine.arguments[i+1]));NSApp.terminate(nil)}}
    }
    func loadAssets() {
        guard let resources = Bundle.main.resourceURL, let data=try? Data(contentsOf:resources.appendingPathComponent("animations.json")), let manifest=try? JSONDecoder().decode([String:AnimationSpec].self,from:data) else {return}
        specs=manifest
        for (state,spec) in manifest {
            let images=(0..<spec.count).compactMap { NSImage(contentsOf:resources.appendingPathComponent(state).appendingPathComponent("\($0).png")) }
            if images.count==spec.count {animations[state]=images}
        }
    }
    func save() { if let data=try? JSONEncoder().encode(prefs) {try? data.write(to:saveURL,options:.atomic)} }
    func play(_ state:String,message:String="",duration:Double=4) {
        guard animations[state] != nil else{return}
        current=state;started=Date();until=Date().addingTimeInterval(duration)
        if !message.isEmpty {say(message,seconds:duration)}
        pet?.needsDisplay=true
    }
    func say(_ text:String,seconds:Double=5) {status?.button?.toolTip=text;bubble=text;bubbleUntil=Date().addingTimeInterval(seconds);pet?.needsDisplay=true}
    func react(_ event:String) {
        let s=prefs.bindings[event] ?? "wave"
        let messages=["comfy":"嗯～就是这里，再摸摸。","smug":"哼哼，本大爷早就知道了。","angry":"喂！本大爷可不是普通的猫！","drunk":"嗝……再来一杯～","burp":"嗝！","satisfied":"吃饱了，真舒服。","surprise":"哦？有好东西？","horror":"吓、吓我一跳！","transform":"看好了，这才是斑大人的模样。","eat":"啊——开饭啦！"]
        play(s,message:messages[s] ?? "",duration:s=="transform" ? 6:4)
        if s=="eat" { DispatchQueue.main.asyncAfter(deadline:.now()+2.6) {if self.current=="eat" {self.play("satisfied",message:"满足～",duration:3)}} }
    }
    func image() -> NSImage? {
        if dragPreview {return animations["eat"]?[2]}
        if moving {let frames=animations[current] ?? [];return frames.isEmpty ? nil:frames[Int(Date().timeIntervalSince(started)/0.11)%frames.count]}
        let active=Date()<until
        if !active && prefs.gaze {
            let p=NSEvent.mouseLocation
            let center=pet.headScreenPoint
            let dx=p.x-center.x,dy=p.y-center.y,dist=hypot(dx,dy)
            if dist>42 && dist<700 {
                let index=directionIndex(dx:dx,dy:dy)
                return animations[index<8 ? "lookA":"lookB"]?[index%8]
            }
        }
        let key=active ? current:"idle"
        guard let frames=animations[key],!frames.isEmpty else{return nil}
        let elapsed=Date().timeIntervalSince(started)
        let interval=(specs[key]?.duration ?? 180)/1000
        let index: Int
        if key == "transform" {
            let t=elapsed.truncatingRemainder(dividingBy:6)
            index=t<0.4 ? 0:t<0.9 ? 1:t<2.7 ? 2:t<4.5 ? 3:t<5.1 ? 4:5
        } else {index=Int(elapsed/interval)%frames.count}
        return frames[index]
    }
    @objc func tick() {
        let now=Date(),mouse=NSEvent.mouseLocation,dt=max(0.01,now.timeIntervalSince(lastMouseTime))
        let speed=hypot(mouse.x-lastMouse.x,mouse.y-lastMouse.y)/dt
        if !moving && !dragPreview && now>until && now.timeIntervalSince(lastRush)>9 && speed>2300 && hypot(mouse.x-pet.headScreenPoint.x,mouse.y-pet.headScreenPoint.y)<180 {
            lastRush=now;react("rush")
        }
        lastMouse=mouse;lastMouseTime=now
        if now.timeIntervalSince(lastTick)>1 {lastTick=now;checkReminders()}
        pet.needsDisplay=true
    }
    func checkReminders() {
        let now=Date();let due=prefs.reminders.filter{$0.due<=now}
        guard !due.isEmpty else{return}
        for reminder in due {
            if reminder.repeatMinutes>0 {
                if let i=prefs.reminders.firstIndex(where:{$0.id==reminder.id}) {prefs.reminders[i].due=now.addingTimeInterval(reminder.repeatMinutes*60)}
            } else {prefs.reminders.removeAll{$0.id==reminder.id}}
        }
        save();rebuildMenu()
        let text=due.map{$0.text}.joined(separator:"\n")
        play("surprise",message:"时间到啦：\(text)",duration:20)
        if prefs.sound {NSSound(named:"Glass")?.play()}
        let alert=NSAlert();alert.messageText="猫咪老师提醒你";alert.informativeText=text;alert.addButton(withTitle:"知道啦");alert.addButton(withTitle:"5 分钟后再提醒")
        NSApp.activate(ignoringOtherApps:true)
        if CommandLine.arguments.contains("--integration-test") {DispatchQueue.main.asyncAfter(deadline:.now()+0.6){NSApp.stopModal(withCode:.alertFirstButtonReturn);alert.window.orderOut(nil)}}
        if alert.runModal() == .alertSecondButtonReturn {prefs.reminders.append(Reminder(id:UUID().uuidString,text:text,due:Date().addingTimeInterval(300),repeatMinutes:0));save();rebuildMenu()}
    }
    @objc func woke() {keepOnScreen();checkReminders()}
    func keepOnScreen() {
        guard panel != nil else{return}
        let screens=NSScreen.screens.map{$0.visibleFrame}
        let target=screens.first(where:{$0.intersects(panel.frame)}) ?? NSScreen.main?.visibleFrame ?? .zero
        guard target.width>0 else{return}
        var f=panel.frame;f.origin.x=min(max(f.minX,target.minX),target.maxX-f.width);f.origin.y=min(max(f.minY,target.minY),target.maxY-f.height);panel.setFrame(f,display:true)
    }
    func moved() {keepOnScreen();prefs.x=panel.frame.minX;prefs.y=panel.frame.minY;save()}
    func isValidDrop(_ urls:[URL]) -> Bool {
        guard prefs.trashEnabled,!trashBusy,!urls.isEmpty else{return false}
        let home=FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let forbidden=["/","/Users","/System","/Library","/Applications",home,Bundle.main.bundleURL.standardizedFileURL.path]
        return urls.allSatisfy { u in
            let p=u.standardizedFileURL.path
            return u.isFileURL && FileManager.default.fileExists(atPath:p) && !forbidden.contains(p) && !p.hasPrefix("/System/") && !p.hasPrefix(home+"/.Trash/") && !Bundle.main.bundleURL.path.hasPrefix(p+"/")
        }
    }
    func eatFiles(_ urls:[URL]) {
        guard isValidDrop(urls) else{say("这些文件现在不能吃。",seconds:4);return}
        trashBusy=true;dragPreview=false;play("eat",message:"啊呜！\(urls.count) 个文件，开饭！",duration:8)
        NSWorkspace.shared.recycle(urls) { mapping,error in
            DispatchQueue.main.asyncAfter(deadline:.now()+1.6) {
                self.trashBusy=false
                if !mapping.isEmpty {
                    self.prefs.trashHistory.append(mapping.map{TrashRecord(original:$0.key.path,trashed:$0.value.path)})
                    self.save();self.rebuildMenu()
                }
                if let error=error { self.play("failed",message:"有文件没吃到：\(error.localizedDescription)",duration:8) }
                else { self.play("satisfied",message:"吃掉了 \(mapping.count) 个文件。右键可撤销。",duration:7) }
            }
        }
    }
    @objc func undoTrash() {
        guard let batch=prefs.trashHistory.last else{say("还没有吃掉过文件。",seconds:4);return}
        var remaining:[TrashRecord]=[];var count=0
        for record in batch {
            if !FileManager.default.fileExists(atPath:record.trashed) {continue}
            if FileManager.default.fileExists(atPath:record.original) {remaining.append(record);continue}
            do {try FileManager.default.moveItem(atPath:record.trashed,toPath:record.original);count+=1} catch {remaining.append(record)}
        }
        prefs.trashHistory.removeLast();if !remaining.isEmpty {prefs.trashHistory.append(remaining)}
        save();rebuildMenu();play("burp",message:"吐回了 \(count) 个文件。\(remaining.isEmpty ? "":"有同名文件或原目录不可写，请从废纸篓手动恢复。")",duration:7)
    }
    func menu() -> NSMenu {
        let m=NSMenu(title:"猫咪老师")
        m.autoenablesItems=false
        add(m,"猫咪老师 · 独立桌面伴侣",nil)
        add(m,panel?.isVisible == true ? "暂时藏起来":"叫猫咪老师出来",#selector(toggleVisible))
        let actions=NSMenu(title:"动作与表情")
        for s in actionOrder {let item=add(actions,labels[s] ?? s,#selector(playMenu(_:)));item.representedObject=s}
        let group=NSMenuItem(title:"动作与表情",action:nil,keyEquivalent:"");group.submenu=actions;m.addItem(group)
        add(m,"喂一口（不处理文件）",#selector(feed))
        add(m,"撤销上次吃掉的文件",#selector(undoTrash)).isEnabled = !prefs.trashHistory.isEmpty
        m.addItem(.separator())
        add(m,"添加提醒…",#selector(addReminder))
        add(m,"管理提醒（\(prefs.reminders.count)）…",#selector(manageReminders))
        add(m,"25 分钟专注计时",#selector(focusTimer))
        m.addItem(.separator())
        add(m,"鼠标行为设置…",#selector(configureBindings))
        add(m,"跟随鼠标视线",#selector(toggleGaze)).state=prefs.gaze ? .on:.off
        add(m,"拖入文件后丢到废纸篓",#selector(toggleTrash)).state=prefs.trashEnabled ? .on:.off
        add(m,"提醒音效",#selector(toggleSound)).state=prefs.sound ? .on:.off
        add(m,"满足时的粉红泡泡",#selector(toggleBubbles)).state=prefs.pinkBubbles ? .on:.off
        let sizes=NSMenu(title:"大小")
        for s in [96,120,144,160,200,260,340,420] {let title = s == 120 ? "120 像素 · 接近原生 Pets":"\(s) 像素";let item=add(sizes,title,#selector(resizePet(_:)));item.representedObject=s;item.state=Int(prefs.size)==s ? .on:.off}
        let sizeItem=NSMenuItem(title:"调整大小",action:nil,keyEquivalent:"");sizeItem.submenu=sizes;m.addItem(sizeItem)
        add(m,"移动到屏幕右下角",#selector(resetPosition))
        add(m,"打开废纸篓",#selector(openTrash))
        add(m,"使用说明",#selector(help))
        m.addItem(.separator());add(m,"退出猫咪老师",#selector(quit),key:"q")
        return m
    }
    @discardableResult func add(_ menu:NSMenu,_ title:String,_ action:Selector?,key:String="") -> NSMenuItem {let item=NSMenuItem(title:title,action:action,keyEquivalent:key);item.target=self;item.isEnabled=action != nil;menu.addItem(item);return item}
    func rebuildMenu() {status?.menu=menu()}
    @objc func toggleVisible() {if panel.isVisible {panel.orderOut(nil)}else{panel.orderFrontRegardless()};rebuildMenu()}
    @objc func playMenu(_ sender:NSMenuItem) {if let s=sender.representedObject as? String{play(s,duration:s=="transform" ? 6:5)}}
    @objc func feed() {play("eat",message:"啊——开饭啦！",duration:3);DispatchQueue.main.asyncAfter(deadline:.now()+2.5){if self.current=="eat"{self.play("satisfied",message:"满足～",duration:4)}}}
    @objc func toggleGaze(){prefs.gaze.toggle();save();rebuildMenu()}
    @objc func toggleTrash(){prefs.trashEnabled.toggle();save();rebuildMenu()}
    @objc func toggleSound(){prefs.sound.toggle();save();rebuildMenu()}
    @objc func toggleBubbles(){prefs.pinkBubbles.toggle();save();rebuildMenu()}
    @objc func resizePet(_ sender:NSMenuItem){guard let size=sender.representedObject as? Int else{return};prefs.size=Double(size);panel.setContentSize(NSSize(width:size,height:Int(Double(size)*1.2)));pet.frame=NSRect(origin:.zero,size:panel.contentView!.bounds.size);keepOnScreen();save();rebuildMenu()}
    @objc func resetPosition(){guard let screen=NSScreen.main?.visibleFrame else{return};panel.setFrameOrigin(NSPoint(x:screen.maxX-panel.frame.width-40,y:screen.minY+35));moved();panel.orderFrontRegardless()}
    @objc func openTrash(){NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash"))}
    @objc func quit(){save();NSApp.terminate(nil)}
    @objc func addReminder(){
        let a=NSAlert();a.messageText="让猫咪老师记住一件事";a.informativeText="到点后会弹出提醒。程序需保持运行，睡眠期间错过的提醒会在唤醒后补上。"
        let v=NSView(frame:NSRect(x:0,y:0,width:340,height:170))
        let text=NSTextField(frame:NSRect(x:0,y:130,width:340,height:26));text.placeholderString="比如：喝水、开会、取快递";v.addSubview(text)
        let date=NSDatePicker(frame:NSRect(x:0,y:82,width:330,height:30));date.datePickerElements=[.yearMonthDay,.hourMinute];date.datePickerStyle = .textFieldAndStepper;date.dateValue=Date().addingTimeInterval(300);v.addSubview(date)
        let repeatBox=NSPopUpButton(frame:NSRect(x:0,y:30,width:330,height:28));repeatBox.addItems(withTitles:["只提醒一次","每 30 分钟","每小时","每天"]);v.addSubview(repeatBox)
        a.accessoryView=v;a.addButton(withTitle:"记住啦");a.addButton(withTitle:"取消");NSApp.activate(ignoringOtherApps:true);a.window.initialFirstResponder=text
        if a.runModal() == .alertFirstButtonReturn {let title=text.stringValue.trimmingCharacters(in:.whitespacesAndNewlines);guard !title.isEmpty else{return};prefs.reminders.append(Reminder(id:UUID().uuidString,text:title,due:date.dateValue,repeatMinutes:[0,30,60,1440][repeatBox.indexOfSelectedItem]));save();rebuildMenu();play("waiting",message:"记住啦：\(title)",duration:4)}
    }
    @objc func manageReminders(){
        let a=NSAlert();a.messageText="我的提醒清单"
        let sorted=prefs.reminders.sorted{$0.due<$1.due}
        let format=DateFormatter();format.dateFormat="MM-dd HH:mm"
        a.informativeText=sorted.isEmpty ? "还没有提醒。":sorted.map{"\(format.string(from:$0.due))  \($0.text)"}.joined(separator:"\n")
        let popup=NSPopUpButton(frame:NSRect(x:0,y:0,width:340,height:28));popup.addItems(withTitles:sorted.map{$0.text});a.accessoryView=popup
        a.addButton(withTitle:"关闭");if !sorted.isEmpty{a.addButton(withTitle:"删除选中提醒")};NSApp.activate(ignoringOtherApps:true)
        if a.runModal() == .alertSecondButtonReturn && popup.indexOfSelectedItem>=0 {let id=sorted[popup.indexOfSelectedItem].id;prefs.reminders.removeAll{$0.id==id};save();rebuildMenu()}
    }
    @objc func focusTimer(){prefs.reminders.append(Reminder(id:UUID().uuidString,text:"专注 25 分钟完成啦，伸个懒腰吧！",due:Date().addingTimeInterval(1500),repeatMinutes:0));save();rebuildMenu();play("working",message:"本大爷陪你专注 25 分钟。",duration:5)}
    @objc func configureBindings(){
        let a=NSAlert();a.messageText="鼠标行为与反应";a.informativeText="拖动始终用于移动；鼠标在周围移动时会看向你。"
        let v=NSView(frame:NSRect(x:0,y:0,width:400,height:CGFloat(eventOrder.count*36)))
        var fields:[String:NSPopUpButton]=[:]
        for (i,event) in eventOrder.enumerated(){let y=CGFloat((eventOrder.count-1-i)*36);let label=NSTextField(labelWithString:eventLabels[event] ?? event);label.frame=NSRect(x:0,y:y+5,width:170,height:24);v.addSubview(label);let popup=NSPopUpButton(frame:NSRect(x:170,y:y,width:220,height:30));popup.addItems(withTitles:actionOrder.map{labels[$0] ?? $0});popup.selectItem(at:actionOrder.firstIndex(of:prefs.bindings[event] ?? "wave") ?? 0);v.addSubview(popup);fields[event]=popup}
        a.accessoryView=v;a.addButton(withTitle:"保存");a.addButton(withTitle:"取消");NSApp.activate(ignoringOtherApps:true)
        if a.runModal() == .alertFirstButtonReturn{for(event,field) in fields{prefs.bindings[event]=actionOrder[field.indexOfSelectedItem]};save();say("新动作记住啦！",seconds:4)}
    }
    @objc func help(){let a=NSAlert();a.messageText="猫咪老师桌面伴侣";a.informativeText="鼠标在身边 700 像素内：16 方向跟随。\n左键拖动：移动；右键：动作和设置。\n单击、双击、三击、长按、组合键、中键和滚轮均可在鼠标行为设置中修改。\n拖文件到身体上松开：丢入废纸篓；右键撤销可恢复上次操作。\n提醒存于本机，程序运行时到点弹窗。\n菜单栏的“猫咪老师”随时可叫它出来或退出。";a.addButton(withTitle:"知道了");NSApp.activate(ignoringOtherApps:true);a.runModal()}
    func applicationWillTerminate(_ notification:Notification){timer?.invalidate();save()}
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool)->Bool{panel.orderFrontRegardless();rebuildMenu();return true}
}
