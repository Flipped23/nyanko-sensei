import Foundation

let labels: [String:String] = ["idle":"呼吸眨眼","wave":"挥手","jump":"跳跃","right":"向右跑","left":"向左跑","failed":"委屈失落","waiting":"等你回应","working":"认真思考","review":"仔细检查","angry":"生气","horror":"大惊失色","comfy":"舒服 · 被摸头","smug":"贱兮兮坏笑","drunk":"喝醉酒","burp":"打嗝","satisfied":"满足","surprise":"惊喜","sleepy":"困了","coy":"偷笑","tipsy":"醉醺醺满足","eat":"张大嘴吃饭","transform":"脑袋变回斑"]
let actionOrder = ["wave","jump","eat","transform","angry","horror","comfy","smug","drunk","burp","satisfied","surprise","sleepy","coy","tipsy","waiting","working","review","failed"]
let eventOrder = ["click","double","triple","hold","option","shift","middle","wheel","rush"]
let eventLabels = ["click":"单击","double":"双击","triple":"三击","hold":"长按（不拖动）","option":"Option + 单击","shift":"Shift + 单击","middle":"中键点击","wheel":"滚轮 / 双指滚动","rush":"鼠标快速靠近"]

func directionIndex(dx: Double, dy: Double) -> Int {
    let degrees = (atan2(dx, dy) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    return Int((degrees / 22.5).rounded()) % 16
}
