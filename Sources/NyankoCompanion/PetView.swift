import AppKit

class PetView: NSView {
    weak var controller:AppController?
    var down=NSPoint.zero
    var initialOrigin=NSPoint.zero
    var began=Date()
    var didDrag=false
    var clickTask:DispatchWorkItem?
    override var acceptsFirstResponder:Bool{true}
    override init(frame:NSRect){super.init(frame:frame);registerForDraggedTypes([.fileURL])}
    required init?(coder:NSCoder){fatalError()}
    var spriteRect:NSRect {NSRect(x:0,y:0,width:bounds.width,height:bounds.width*416/384)}
    var headScreenPoint:NSPoint {guard let window=window else{return .zero};return window.convertPoint(toScreen:NSPoint(x:bounds.width*0.48,y:bounds.width*0.62))}
    override func hitTest(_ point:NSPoint)->NSView?{spriteRect.contains(point) ? self:nil}
    override func draw(_ dirtyRect:NSRect){
        guard let c=controller else{return}
        if c.prefs.pinkBubbles && c.current == "satisfied" && Date()<c.until {
            let t=Date().timeIntervalSince(c.started)
            for i in 0..<11 {
                let phase=(t*0.22+Double(i)*0.089).truncatingRemainder(dividingBy:1)
                let x=bounds.width*(0.06+Double(i%6)*0.17)+sin(t+Double(i))*8
                let y=bounds.width*(0.1+phase*0.85)
                let radius=CGFloat(9+(i%4)*5)
                let rect=NSRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2)
                NSColor.systemPink.withAlphaComponent(0.22*(1-phase)).setFill();NSBezierPath(ovalIn:rect).fill()
                NSColor.systemPink.withAlphaComponent(0.6*(1-phase)).setStroke();let ring=NSBezierPath(ovalIn:rect);ring.lineWidth=1.6;ring.stroke()
                NSColor.white.withAlphaComponent(0.65*(1-phase)).setFill();NSBezierPath(ovalIn:NSRect(x:x-radius*0.45,y:y+radius*0.25,width:radius*0.35,height:radius*0.25)).fill()
            }
        }
        c.image()?.draw(in:spriteRect,from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])
        if bounds.width >= 180 && Date()<c.bubbleUntil && !c.bubble.isEmpty {
            let rect=NSRect(x:5,y:bounds.height-54,width:bounds.width-10,height:50)
            NSColor(calibratedWhite:1,alpha:0.96).setFill();NSBezierPath(roundedRect:rect,xRadius:12,yRadius:12).fill()
            let style=NSMutableParagraphStyle();style.alignment = .center;style.lineBreakMode = .byTruncatingTail
            (c.bubble as NSString).draw(in:rect.insetBy(dx:8,dy:6),withAttributes:[.font:NSFont.systemFont(ofSize:12,weight:.medium),.foregroundColor:NSColor.darkGray,.paragraphStyle:style])
        }
        if c.dragPreview {NSColor.systemOrange.withAlphaComponent(0.6).setStroke();let p=NSBezierPath(roundedRect:spriteRect.insetBy(dx:8,dy:8),xRadius:30,yRadius:30);p.lineWidth=3;p.stroke()}
    }
    override func mouseDown(with event:NSEvent){clickTask?.cancel();down=NSEvent.mouseLocation;initialOrigin=window?.frame.origin ?? .zero;began=Date();didDrag=false}
    override func mouseDragged(with event:NSEvent){guard let c=controller else{return};let p=NSEvent.mouseLocation;let dx=p.x-down.x,dy=p.y-down.y;if hypot(dx,dy)>4{didDrag=true;c.moving=true;c.current=dx>=0 ? "right":"left";window?.setFrameOrigin(NSPoint(x:initialOrigin.x+dx,y:initialOrigin.y+dy));needsDisplay=true}}
    override func mouseUp(with event:NSEvent){
        guard let c=controller else{return};c.moving=false
        if didDrag{c.until = .distantPast;c.moved();return}
        if Date().timeIntervalSince(began)>0.65{c.react("hold");return}
        let key=event.modifierFlags.contains(.option) ? "option":event.modifierFlags.contains(.shift) ? "shift":event.clickCount>=3 ? "triple":event.clickCount==2 ? "double":"click"
        let task=DispatchWorkItem{[weak c] in c?.react(key)};clickTask=task;DispatchQueue.main.asyncAfter(deadline:.now()+NSEvent.doubleClickInterval,execute:task)
    }
    override func rightMouseDown(with event:NSEvent){guard let menu=controller?.menu() else{return};NSMenu.popUpContextMenu(menu,with:event,for:self)}
    override func otherMouseDown(with event:NSEvent){controller?.react("middle")}
    override func scrollWheel(with event:NSEvent){guard let c=controller,Date().timeIntervalSince(c.lastWheel)>1 else{return};c.lastWheel=Date();c.react("wheel")}
    func dropURLs(_ sender:NSDraggingInfo)->[URL]{(sender.draggingPasteboard.readObjects(forClasses:[NSURL.self],options:[.urlReadingFileURLsOnly:true]) as? [URL]) ?? []}
    override func draggingEntered(_ sender:NSDraggingInfo)->NSDragOperation{guard let c=controller,c.isValidDrop(dropURLs(sender)) else{return []};c.dragPreview=true;c.say("松开就吃掉 · 丢到废纸篓",seconds:4);needsDisplay=true;return .move}
    override func draggingUpdated(_ sender:NSDraggingInfo)->NSDragOperation{controller?.isValidDrop(dropURLs(sender)) == true ? .move:[]}
    override func draggingExited(_ sender:NSDraggingInfo?){controller?.dragPreview=false;needsDisplay=true}
    override func prepareForDragOperation(_ sender:NSDraggingInfo)->Bool{controller?.isValidDrop(dropURLs(sender)) == true}
    override func performDragOperation(_ sender:NSDraggingInfo)->Bool{let urls=dropURLs(sender);guard let c=controller,c.isValidDrop(urls) else{return false};c.eatFiles(urls);return true}
    override func concludeDragOperation(_ sender:NSDraggingInfo?){controller?.dragPreview=false;needsDisplay=true}
}
