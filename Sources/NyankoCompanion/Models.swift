import Foundation

struct AnimationSpec: Codable { let count: Int; let duration: Double }
struct Reminder: Codable { var id: String; var text: String; var due: Date; var repeatMinutes: Double }
struct TrashRecord: Codable { var original: String; var trashed: String }
struct Preferences: Codable {
    var size: Double = 120
    var gaze = true
    var sound = true
    var trashEnabled = true
    var pinkBubbles = true
    var bindings: [String:String] = ["click":"wave","double":"eat","triple":"transform","hold":"comfy","option":"smug","shift":"angry","middle":"burp","wheel":"drunk","rush":"horror"]
    var reminders: [Reminder] = []
    var trashHistory: [[TrashRecord]] = []
    var x: Double? = nil
    var y: Double? = nil
}
