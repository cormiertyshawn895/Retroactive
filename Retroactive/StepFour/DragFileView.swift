import Cocoa

protocol DragFileViewDelegate: NSObject {
    func draggingStarted(view: DragFileView, point: NSPoint)
    func draggingSucceeded(view: DragFileView, point: NSPoint)
    func draggingFailed(view: DragFileView, point: NSPoint)
}

class DragFileView: NSView, NSPasteboardItemDataProvider, NSDraggingSource {
    weak var delegate: DragFileViewDelegate?
    var filePath = "/bin/bash"
    weak var subviewForImagePresentation: NSView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerForDraggedTypes([.fileURL])
    }
    
    override func mouseDown(with event: NSEvent) {
        let pbItem = NSPasteboardItem()
        pbItem.setDataProvider(self, forTypes: [.fileURL])
        let dragItem = NSDraggingItem(pasteboardWriter: pbItem)
        let draggingRect = self.bounds
        dragItem.setDraggingFrame(draggingRect, contents: (subviewForImagePresentation ?? self).imagePresentation)
        
        let draggingSession = self.beginDraggingSession(with: [dragItem], event: event, source: self)
        draggingSession.animatesToStartingPositionsOnCancelOrFail = true
        draggingSession.draggingFormation = .none
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        if context == .outsideApplication {
            return .copy
        }
        return []
    }
    
    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        delegate?.draggingStarted(view: self, point: screenPoint)
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation == .copy {
            delegate?.draggingSucceeded(view: self, point: screenPoint)
        } else {
            delegate?.draggingFailed(view: self, point: screenPoint)

        }
        self.subviewForImagePresentation?.isHidden = false
    }

    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        if type == .fileURL {
            pasteboard?.setData(URL(fileURLWithPath: filePath).dataRepresentation, forType: .fileURL)
        }
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
