//
//  ContentView.swift
//  Diacut
//
//  Created by arcana-mojave on 2023/05/11.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let DEFAULT_FRAME_WIDTH: CGFloat = 512.0
    private let DEFAULT_FRAME_HEIGHT: CGFloat = 288.0
    
    @State private var isDropTargeted = false
    @State private var nsImage = NSImage(named: "512x288")!
    @State private var prevWidth: Int? = nil
    @State private var prevHeight: Int? = nil
    
    @State private var virtualWidth = "512"
    @State private var virtualHeight = "288"
    @State private var virtualX = "0"
    @State private var virtualY = "0"
    @State private var initX = 0
    @State private var initY = 0
    
    @State private var leftTop: CGPoint = CGPoint(x: 0, y: 0)
    @State private var rightTop: CGPoint = CGPoint(x: 512, y: 0)
    @State private var rightBottom: CGPoint = CGPoint(x: 512, y: 288)
    @State private var leftBottom: CGPoint = CGPoint(x: 0, y: 288)
    
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
                .onDrop(of: [.image], isTargeted: $isDropTargeted, perform: processDroppedFile(provideres:))
                .overlay(
                    Path { path in
                        path.move(to: leftTop)
                        path.addLine(to: rightTop)
                        path.addLine(to: rightBottom)
                        path.addLine(to: leftBottom)
                        path.closeSubpath()
                    }.stroke().fill(Color.green)
                )
        }.padding()
        
        HStack {
            Text("Image").font(.largeTitle).fontWeight(.ultraLight)
            Text("width: \(Int(nsImage.size.width))").font(.largeTitle).fontWeight(.ultraLight)
            Text("height: \(Int(nsImage.size.height))").font(.largeTitle).fontWeight(.ultraLight)
        }.padding()
        
        HStack {
            Text("Trim").font(.largeTitle).fontWeight(.ultraLight)
            
            Text("width:").font(.largeTitle).fontWeight(.ultraLight)
            TextField("", text: $actualTrimWidth, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            Text("height:").font(.largeTitle).fontWeight(.ultraLight)
            TextField("", text: $actualTrimHeight, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            Text("X:").font(.largeTitle).fontWeight(.ultraLight)
            TextField("", text: $actualTrimX, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
            
            Text("Y:").font(.largeTitle).fontWeight(.ultraLight)
            TextField("", text: $actualTrimY, onCommit: {
                resetTrimRect(isManual: true)
            }).font(.largeTitle).fontWeight(.ultraLight)
        }.padding()
        
        HStack {
            Button(action: {
                clickSaveButton()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Trim to Save")
                }
            }
        }.padding()
    }
    
    private func resetTrimRect(isManual: Bool = false) {
        if !isManual {
            print("drop to reset")
            
            if prevWidth == nil {
                prevWidth = Int(nsImage.size.width)
                prevHeight = Int(nsImage.size.height)
            } else if prevWidth == Int(nsImage.size.width) && prevHeight == Int(nsImage.size.height) {
                print("same image size")
                return
            } else {
                print("different image size")
                prevWidth = Int(nsImage.size.width)
                prevHeight = Int(nsImage.size.height)
            }
            
            actualTrimWidth = String(Int(nsImage.size.width))
            actualTrimHeight = String(Int(nsImage.size.height))
            actualTrimX = "0"
            actualTrimY = "0"
        }
        
        virtualWidth = String(Int((Float(actualTrimWidth) ?? 0.0) / calcYScale()))
        
        if (Int(virtualWidth) ?? 0) > Int(DEFAULT_FRAME_WIDTH) {
            virtualWidth = String(Int((Float(actualTrimWidth) ?? 0.0) / calcXScale()))
            virtualHeight = String(Int((Float(actualTrimHeight) ?? 0.0) / calcXScale()))
            
            if !isManual {
                virtualX = "0"
                virtualY = String(Int((Int(DEFAULT_FRAME_HEIGHT) - (Int(virtualHeight) ?? 0)) / 2))
                initX = Int(virtualX) ?? 0
                initY = Int(virtualY) ?? 0
            } else {
                virtualX = String(Int(((Float(actualTrimX) ?? 0.0) / calcXScale()) + Float(initX)))
                virtualY = String(Int(((Float(actualTrimY) ?? 0.0) / calcXScale()) + Float(initY)))
            }
        } else {
            virtualHeight = String(Int((Float(actualTrimHeight) ?? 0.0) / calcYScale()))
            
            if !isManual {
                virtualX = String(Int((Int(DEFAULT_FRAME_WIDTH) - (Int(virtualWidth) ?? 0)) / 2))
                virtualY = "0"
                initX = Int(virtualX) ?? 0
                initY = Int(virtualY) ?? 0
            } else {
                virtualX = String(Int(((Float(actualTrimX) ?? 0.0) / calcYScale()) + Float(initX)))
                virtualY = String(Int(((Float(actualTrimY) ?? 0.0) / calcYScale()) + Float(initY)))
            }
        }
        
        leftTop = pathLeftTop()
        rightTop = pathRightTop(pathLeftTop: leftTop)
        rightBottom = pathRightBottom(pathRightTop: rightTop)
        leftBottom = pathLeftBottom(pathLeftTop: leftTop)
        
        print("virtualWidth=\(virtualWidth) virtualHeight=\(virtualHeight) virtualX=\(virtualX) virtualY=\(virtualY)")
    }
    
    private func processDroppedFile(provideres: [NSItemProvider]) -> Bool {
        guard let provider = provideres.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    guard error == nil,
                          let url = urlData as? URL,
                          let loadedImage = NSImage(contentsOf: url)
                    else { return }
                    nsImage = loadedImage
                    resetTrimRect()
                }
            }
        }
        return true
    }
    
    private func position(fromX: CGFloat, fromY: CGFloat, movementX: Int, movementY: Int) -> CGPoint {
        return CGPoint(x: Int(fromX) + movementX, y: Int(fromY) + movementY)
    }
    
    private func pathLeftTop() -> CGPoint {
        let fromX = CGFloat(Int(virtualX) ?? 0)
        let fromY = CGFloat(Int(virtualY) ?? 0)
        return position(fromX: fromX, fromY: fromY, movementX: 0, movementY: 0)
    }
    
    private func pathRightTop(pathLeftTop: CGPoint) -> CGPoint {
        return position(fromX: pathLeftTop.x, fromY: pathLeftTop.y, movementX: Int(virtualWidth) ?? 0, movementY: 0)
    }
    
    private func pathRightBottom(pathRightTop: CGPoint) -> CGPoint {
        return position(fromX: pathRightTop.x, fromY: pathRightTop.y, movementX: 0, movementY: Int(virtualHeight) ?? 0)
    }
    
    private func pathLeftBottom(pathLeftTop: CGPoint) -> CGPoint {
        return position(fromX: pathLeftTop.x, fromY: pathLeftTop.y, movementX: 0, movementY: Int(virtualHeight) ?? 0)
    }
    
    private func calcXScale() -> Float {
        return Float(nsImage.size.width) / Float(DEFAULT_FRAME_WIDTH)
    }
    
    private func calcYScale() -> Float {
        return Float(nsImage.size.height) / Float(DEFAULT_FRAME_HEIGHT)
    }
    
    private func clickSaveButton() {
        let lloY = Int(nsImage.size.height) - ((Int(actualTrimY) ?? 0) + (Int(actualTrimHeight) ?? 0))
        
        let rect = CGRect(x: Int(actualTrimX) ?? 0, y: lloY, width: Int(actualTrimWidth) ?? 0, height: Int(actualTrimHeight) ?? 0)
        
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
