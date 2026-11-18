import AppKit

// Explicit CLI-only diagnostics. Normal launches never touch test files.
extension AppController {
    func exportPreviews(_ directory:URL){
        try? FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        bubble="";bubbleUntil = .distantPast
        for state in ["satisfied","angry","horror","drunk","smug","eat","transform"] {
            for frame in 0..<16 {
                current=state;started=Date().addingTimeInterval(-Double(frame)*0.3);until=Date().addingTimeInterval(10)
                pet.needsDisplay=true;pet.displayIfNeeded()
                if let bitmap=pet.bitmapImageRepForCachingDisplay(in:pet.bounds){pet.cacheDisplay(in:pet.bounds,to:bitmap);if let data=bitmap.representation(using:.png,properties:[:]){try? data.write(to:directory.appendingPathComponent("\(state)-\(String(format:"%02d",frame)).png"))}}
            }
        }
    }
    func integrationTest(){
        let path=saveURL.deletingLastPathComponent().appendingPathComponent("nyanko-trash-test-\(UUID().uuidString).txt")
        let content="Nyanko disposable integration test."
        do {try content.write(to:path,atomically:true,encoding:.utf8)}catch{print(error);NSApp.terminate(nil);return}
        eatFiles([path])
        DispatchQueue.main.asyncAfter(deadline:.now()+3.5){
            let moved = !FileManager.default.fileExists(atPath:path.path) && !(self.prefs.trashHistory.last ?? []).isEmpty
            let inTrash=self.prefs.trashHistory.last?.allSatisfy{FileManager.default.fileExists(atPath:$0.trashed)} ?? false
            self.undoTrash()
            let restored=(try? String(contentsOf:path,encoding:.utf8))==content
            self.prefs.reminders.append(Reminder(id:UUID().uuidString,text:"这是提醒弹窗的自动测试",due:Date().addingTimeInterval(-1),repeatMinutes:0))
            self.checkReminders()
            let reminderFired=self.prefs.reminders.isEmpty && self.current=="surprise"
            self.prefs.bindings["click"]="smug";self.save()
            let persisted=(try? Data(contentsOf:self.saveURL)).flatMap{try? JSONDecoder().decode(Preferences.self,from:$0)}?.bindings["click"]=="smug"
            let result:[String:Any]=["ok":moved && inTrash && restored && reminderFired && persisted,"trash_move":moved,"trash_destination_exists":inTrash,"undo_restores_exact_content":restored,"reminder_alert_fired":reminderFired,"settings_persisted":persisted,"only_disposable_test_file_used":true]
            if let data=try? JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]),let i=CommandLine.arguments.firstIndex(of:"--report"),CommandLine.arguments.count>i+1 {try? data.write(to:URL(fileURLWithPath:CommandLine.arguments[i+1]));print(String(data:data,encoding:.utf8)!)}
            try? FileManager.default.removeItem(at:path)
            NSApp.terminate(nil)
        }
    }
    func runSmokeTest(){
        let tests:[String:Bool]=["24_states_loaded":animations.count==24,"108_frames_loaded":animations.values.reduce(0){$0+$1.count}==108,"16_gaze_directions":Set((0..<16).map{let a=Double($0)*22.5*Double.pi/180;return directionIndex(dx:sin(a)*100,dy:cos(a)*100)}).count==16,"panel_transparent":!panel.isOpaque,"file_drop_registered":pet.registeredDraggedTypes.contains(.fileURL),"bindings_valid":prefs.bindings.values.allSatisfy{animations[$0] != nil},"protected_root_rejected":!isValidDrop([URL(fileURLWithPath:"/")])]
        if let data=try? JSONSerialization.data(withJSONObject:["checks":tests,"ok":tests.values.allSatisfy{$0}],options:[.prettyPrinted,.sortedKeys]) {print(String(data:data,encoding:.utf8)!);if let i=CommandLine.arguments.firstIndex(of:"--report"),CommandLine.arguments.count>i+1{try? data.write(to:URL(fileURLWithPath:CommandLine.arguments[i+1]))}}
    }
}
