//
//  SpingARView.swift
//
//
//  Created by Joseph Heck on 2/9/22.
//

import Foundation
import SwiftUI
import RealityKit
import Combine
import UniformTypeIdentifiers
import CameraControlARView

struct SpinARView : View {
    @StateObject private var arView: CameraControlARView = {
        let arView = CameraControlARView(frame: .zero)
        
//        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadBox()
//
//        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        return arView
    }()
    @State private var debugEnabled = false

    @State private var cancellables: Set<AnyCancellable> = []
    @State private var load_cancellables: Set<AnyCancellable> = []
    @State private var snapshots: [NSImage] = []
    @State private var name_for_file: String = ""
    @State private var frames_per_second: Int = 20
    
    @State private var dragOver = false
    
    func animatedGifFromImages(images: [NSImage], filename: String, frameDelay: Double) -> Bool {
        let directory_url = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0]
            
        let url = directory_url.appendingPathComponent("/\(filename).gif") as CFURL

        let prep = [kCGImagePropertyGIFDictionary as String :
               [kCGImagePropertyGIFDelayTime as String : frameDelay]] as CFDictionary

        let fileProperties = [ kCGImagePropertyGIFDictionary as String :
                               [kCGImagePropertyGIFLoopCount as String : 0] ,
                               kCGImageMetadataShouldExcludeGPS as String: true]
                               as CFDictionary

        guard let destination = CGImageDestinationCreateWithURL(
            url,
            UTType.gif.identifier as CFString, // aka `kUTTypeGIF`
            images.count,
            nil) else {
            return false
        }

        CGImageDestinationSetProperties(destination, fileProperties)

        for image in images {
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(destination, cgImage, prep)
            }
        }

        if CGImageDestinationFinalize(destination) {
            NSWorkspace.shared.open(directory_url)
            return true
        }
        return false
    }

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    @State var rotation: Float = 0
    @State var timer_connected: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    if debugEnabled {
                        debugEnabled = false
                        arView.debugOptions = [.none]
                    } else {
                        debugEnabled = true
                        arView.debugOptions = [.showStatistics]
                    }
                } label: {
                    Label {
                        Text("AR stats")
                    } icon: {
                        Image(systemName: "info.circle")
                    }
                }
                Button {
                    let rotation_publisher = stride(
                        from: arView.rotationAngle,
                        through: (arView.rotationAngle+Float.pi*2),
                        by: 0.05).publisher
                    rotation_publisher
                        .zip(timer)
                        .map { (floatval, timerval) in
                            return floatval
                        }
                        .removeDuplicates()
                        .sink { rot in
                            print("setting rotation to: \(rot)")
                            arView.rotationAngle = rot
                            arView.snapshot(saveToHDR: false) { image in
                                guard let image = image else {
                                    return
                                }
                                // print("image size: \(image.size)")
                                // print("arview size: \(arView.frame.size)")
                                // image size: (809.0, 643.0) <- same size as frame
                                snapshots.append(image)
                            }
                        }
                        .store(in: &cancellables)
                } label: {
                    Image(systemName: "play")
                }
                Button {
                    for thing_to_cancel in cancellables {
                        thing_to_cancel.cancel()
                    }
                    arView.rotationAngle = 0
                } label: {
                    Image(systemName: "stop")
                }
                Button {
                    snapshots = []
                    arView.rotationAngle = 0
                } label: {
                    Image(systemName: "clear")
                }
                Text("Images captured: \(snapshots.count)")
            }

            HStack {
                TextField("animated gif name", text: $name_for_file)
                    .frame(minWidth: 20, maxWidth: 150)
                HStack {
                    Text("at \(frames_per_second) fps")
                    VStack {
                        Button {
                            if frames_per_second < 30 {
                            frames_per_second += 1
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        Button {
                            if frames_per_second > 0 {
                                frames_per_second -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }

                    }
                }
                Button {
                    if name_for_file.count > 0 && snapshots.count > 0 {
                        print("Saving to \(name_for_file)")
                        for thing_to_cancel in cancellables {
                            thing_to_cancel.cancel()
                        }
                        let result = animatedGifFromImages(
                            images: snapshots,
                            filename: name_for_file,
                            frameDelay: 1.0/Double(frames_per_second))
                        print("Save result: \(result)")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            
            ARViewContainer(cameraARView: arView)
                .frame(width: 300, height: 200, alignment: .center)
                .onAppear() {
                    arView.inclinationAngle = -Float.pi/6 // 30°
                    arView.radius = 0.5
                    arView.arcballTarget = simd_float3(0,0,0)
                }
                .onDrop(of: [UTType.fileURL], isTargeted: $dragOver) { providers in
                    print("Dropped info contained \(providers.count) providers.")
                    guard let firstitem = providers.first else {
                        return false
                    }
                    print("Type identifiers for dropped element: \(firstitem.registeredTypeIdentifiers)")

                    firstitem.loadItem(forTypeIdentifier: "public.file-url", options: nil) {
                        (urlData, error) in
                        print("Error provided: \(String(describing: error))")
                        if let data = urlData as? Data,
                            let path = String(data: data, encoding: .utf8),
                            let url = URL(string: path) {
                                print("Data provided: \(data)")
                                print("Path resolved from data: \(path)")
                                print("URL resolved from path: \(url)")
                            
                            DispatchQueue.main.async {
                                Entity.loadAsync(contentsOf: url)
                                        .receive(on: RunLoop.main)
                                        .sink(receiveCompletion: { loadCompletion in
                                                print("completion: \(loadCompletion)")
                                            }, receiveValue: { entity in
                                                print("received entity from load: \(entity)")
                                                let bounds = entity.visualBounds(relativeTo: nil)
                                                let max_distance = max(bounds.max.x, bounds.max.y, bounds.max.z)
                                                arView.radius = max_distance*2 //+1 // smidge of padding
                                                print("Setting radius to \(max_distance*2) from bounds: \(bounds)")
                                                let originAnchor = AnchorEntity(world: .zero)
                                                originAnchor.addChild(entity)
                                                arView.scene.anchors.append(originAnchor)
                                                
                                                // play animations
                                                for anim in entity.availableAnimations {
                                                    entity.playAnimation(anim.repeat(duration: .infinity), transitionDuration: 1.25, startsPaused: false)
                                                }
                                            }).store(in: &load_cancellables)
                            }
                        }
                    }
                    return true
                }

        }
    }
}

struct SpinARView_Previews: PreviewProvider {
    static var previews: some View {
        SpinARView()
    }
}
