//
//  ContentView.swift
//  Diacut
//
//  Created by arcana-mojave on 2023/05/11.
//

import SwiftUI

struct ContentView: View {
    private let DEFAULT_FRAME_WIDTH: CGFloat = 512.0
    private let DEFAULT_FRAME_HEIGHT: CGFloat = 288.0
    
    @State private var isDropTargeted = false
    @State private var nsImage = NSImage(named: "512x288")!
    @State private var trimWidth = "512"
    @State private var trimHeight = "288"
    @State private var trimX = "0"
    @State private var trimY = "0"
    @State private var leftTop: CGPoint = CGPoint(x: 0, y: 0)
    @State private var rightTop: CGPoint = CGPoint(x: 512, y: 0)
    @State private var rightBottom: CGPoint = CGPoint(x: 512, y: 288)
    @State private var leftBottom: CGPoint = CGPoint(x: 0, y: 288)
    
    // FIXME
    @State private var actualTrimWidth = "0"
    @State private var actualTrimHeight = "0"
    @State private var actualTrimX = "0"
    @State private var actualTrimY = "0"
    
    var body: some View {
        ZStack {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: DEFAULT_FRAME_WIDTH, height: DEFAULT_FRAME_HEIGHT)
                .onDrop(of: [kUTTypeFileURL as String], isTargeted: $isDropTargeted, perform: processDroppedFile(provideres:))
                .overlay(
                    Path { path in
                        path.move(to: leftTop)
                        path.addLine(to: rightTop)
                        path.addLine(to: rightBottom)
                        path.addLine(to: leftBottom)
                        path.closeSubpath()
                    }.stroke().fill(Color.green)
                )
        }
        
        HStack {
            Text("Image width: \(Int(nsImage.size.width))").font(.largeTitle).fontWeight(.ultraLight)
            Text("Image height: \(Int(nsImage.size.height))").font(.largeTitle).fontWeight(.ultraLight)
        }
        
        HStack {
            Text("Prev").font(.largeTitle).fontWeight(.ultraLight)
            
            TextField("Trim width", text: $trimWidth, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            TextField("Trim height", text: $trimHeight, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            TextField("X", text: $trimX, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            TextField("Y", text: $trimY, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
        }
        
        HStack {
            Text("Actual").font(.largeTitle).fontWeight(.ultraLight)
            Text("Trim width: \(actualTrimWidth)").font(.largeTitle).fontWeight(.ultraLight)
            Text("Trim height: \(actualTrimHeight)").font(.largeTitle).fontWeight(.ultraLight)
            Text("X: \(actualTrimX)").font(.largeTitle).fontWeight(.ultraLight)
            Text("Y: \(actualTrimY)").font(.largeTitle).fontWeight(.ultraLight)
        }
        
        HStack {
            Spacer()
            Button(action: {
                clickSaveButton()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Trim to Save")
                }
            }
            Spacer()
        }
        .padding()
    }
    
    private func resetTrimRect(isManual: Bool = false) {
        if !isManual {
            trimWidth = String(Int(Float(nsImage.size.width) / calcYScale()))
            
            if Int(trimWidth) ?? 0 > Int(DEFAULT_FRAME_WIDTH) {
                trimWidth = String(Int(Float(nsImage.size.width) / calcXScale()))
                trimHeight = String(Int(Float(nsImage.size.height) / calcXScale()))
                trimX = "0"
                trimY = String(Int((Int(DEFAULT_FRAME_HEIGHT) - (Int(trimHeight) ?? 0)) / 2))
            } else {
                trimHeight = String(Int(Float(nsImage.size.height) / calcYScale()))
                trimX = String(Int((Int(DEFAULT_FRAME_WIDTH) - (Int(trimWidth) ?? 0)) / 2))
                trimY = "0"
            }
        }
        
        leftTop = pathLeftTop()
        rightTop = pathRightTop(pathLeftTop: leftTop)
        rightBottom = pathRightBottom(pathRightTop: rightTop)
        leftBottom = pathLeftBottom(pathLeftTop: leftTop)
        
        calcActualTrimWidth()
        calcActualTrimHeight()
        calcActualTrimX()
        calcActualTrimY()
    }
    
    private func processDroppedFile(provideres: [NSItemProvider]) -> Bool {
        guard let provider = provideres.first else { return false }
        provider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) { (urlData, error) in
            DispatchQueue.main.async {
                if let urlData = urlData as? Data {
                    let imageURL = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                    if let localImage = NSImage(contentsOf: imageURL) {
                        nsImage = localImage
                        resetTrimRect()
                    }
                }
            }
        }
        
        return true
    }
    
    private func position(fromX: CGFloat, fromY: CGFloat, movementX: Int, movementY: Int) -> CGPoint {
        return CGPoint(x: Int(fromX) + movementX, y: Int(fromY) + movementY)
    }
    
    private func pathLeftTop() -> CGPoint {
        let fromX = CGFloat(Int(trimX) ?? 0)
        let fromY = CGFloat(Int(trimY) ?? 0)
        return position(fromX: fromX, fromY: fromY, movementX: 0, movementY: 0)
    }
    
    private func pathRightTop(pathLeftTop: CGPoint) -> CGPoint {
        return position(fromX: pathLeftTop.x, fromY: pathLeftTop.y, movementX: Int(trimWidth) ?? 0, movementY: 0)
    }
    
    private func pathRightBottom(pathRightTop: CGPoint) -> CGPoint {
        return position(fromX: pathRightTop.x, fromY: pathRightTop.y, movementX: 0, movementY: Int(trimHeight) ?? 0)
    }
    
    private func pathLeftBottom(pathLeftTop: CGPoint) -> CGPoint {
        return position(fromX: pathLeftTop.x, fromY: pathLeftTop.y, movementX: 0, movementY: Int(trimHeight) ?? 0)
    }
    
    private func calcXScale() -> Float {
        let scale: Float
        if DEFAULT_FRAME_WIDTH < nsImage.size.width {
            scale = Float(nsImage.size.width / DEFAULT_FRAME_WIDTH)
        } else {
            scale = Float(DEFAULT_FRAME_WIDTH / nsImage.size.width)
        }
        return scale
    }
    
    private func calcYScale() -> Float {
        let scale: Float
        if DEFAULT_FRAME_HEIGHT < nsImage.size.height {
            scale = Float(nsImage.size.height / DEFAULT_FRAME_HEIGHT)
        } else {
            scale = Float(DEFAULT_FRAME_HEIGHT / nsImage.size.height)
        }
        return scale
    }
    
    private func calcActualTrimWidth() {
        let width = (Float(trimWidth) ?? 0.0) * calcXScale()
        
        if Int(width) > Int(nsImage.size.width) {
            actualTrimWidth = String(Int(nsImage.size.width))
        } else {
            actualTrimWidth = String(Int(width))
        }
    }
    
    private func calcActualTrimHeight() {
        let height = (Float(trimHeight) ?? 0.0) * calcYScale()
        
        if Int(height) > Int(nsImage.size.height) {
            actualTrimHeight = String(Int(nsImage.size.height))
        } else {
            actualTrimHeight = String(Int(height))
        }
    }
    
    private func calcActualTrimX() {
        let x = (Float(trimX) ?? 0.0) * calcXScale()
        actualTrimX =  String(Int(x))
    }
    
    private func calcActualTrimY() {
        let y = (Float(trimY) ?? 0.0) * calcYScale()
        actualTrimY =  String(Int(y))
    }
    
    private func clickSaveButton() {
        calcActualTrimWidth()
        calcActualTrimHeight()
        calcActualTrimX()
        calcActualTrimY()
        
        let rect = CGRect(x: Int(actualTrimX) ?? 0, y: Int(actualTrimY) ?? 0, width: Int(actualTrimWidth) ?? 0, height: Int(actualTrimHeight) ?? 0)
        
        let trimmedImage = trim(image: nsImage, rect: rect)
        
        saveAsPng(image: trimmedImage, path: NSHomeDirectory() + "/Downloads/\(genFileName()).png")
    }
    
    private func trim(image: NSImage, rect: CGRect) -> NSImage {
        let result = NSImage(size: rect.size)
        result.lockFocus()
        
        let destRect = CGRect(origin: .zero, size: result.size)
        image.draw(in: destRect, from: rect, operation: .copy, fraction: 1.0)
        
        result.unlockFocus()
        return result
    }
    
    private func genFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        return formatter.string(from: Date())
    }
    
    private func saveAsPng(image: NSImage, path: String) {
        let pngData = image.pngData(size: CGSize(width: image.size.width, height: image.size.height))
        
        do {
            try pngData!.write(to: URL(fileURLWithPath: path))
        } catch {
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
