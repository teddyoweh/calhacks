//
//  AddCardView.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/28/23.
//

import SceneKit
import SwiftUI

struct AddCardView: View {
    @ObservedObject var model: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var shown = false

    @State var loading = false
    @State var isPresented = false
    @State var name = ""
    @State var resultImage: UIImage?
    @State var errorUploading = false

    var body: some View {
        VStack {
            if let finishedScanURL = model.finishedScanURL {
                finishedScan(finishedScanURL: finishedScanURL)
            } else {
                main
            }
        }
        .background {
            Color.black
                .brightness(0.1)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isPresented) {
            ScanView(model: model)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                shown = true
            }

            model.fetchAllCards() 
        }
    }

    func finishedScan(finishedScanURL: URL) -> some View {
        VStack {
            HStack {
                Text("Almost Done...")
                    .font(.largeTitle)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    dismiss()

                    withAnimation {
                        model.finishedScanURL = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .opacity(0.15)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 16) {
                    if let scene = try? SCNScene(url: finishedScanURL) {
                        SceneView(scene: scene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                            .frame(height: 300)
                            .mask {
                                RoundedRectangle(cornerRadius: 16)
                            }
                            .onAppear {
                                let sunNode = SCNNode()
                                sunNode.light = SCNLight()
                                sunNode.light?.type = .directional
                                scene.rootNode.addChildNode(sunNode)

                                let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
                                renderer.scene = scene
                                let renderTime = TimeInterval(0)

                                // Output size
                                let size = CGSize(width: 300, height: 300)

                                // Render the image
                                let image = renderer.snapshot(
                                    atTime: renderTime, with: size,
                                    antialiasingMode: SCNAntialiasingMode.multisampling4X
                                )

                                withAnimation {
                                    resultImage = image
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                if let resultImage {
                                    Image(uiImage: resultImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 72, height: 72)
                                        .background {
                                            Color.black
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16)
                                                .strokeBorder(Color.green, lineWidth: 2)
                                        }
                                        .mask {
                                            RoundedRectangle(cornerRadius: 16)
                                        }
                                        .offset(x: 8, y: 8)
                                }
                            }
                    }

                    Text(finishedScanURL.absoluteString)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    TextField("Enter a name", text: $name)
                        .environment(\.colorScheme, .dark)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 0.5)
                                .opacity(0.5)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .opacity(0.1)
                                }
                        }
                        .padding(.vertical, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    model.upload(name: name, image: resultImage) { success in
                        print("Upload finished! success? \(success)")
                        if success {
                            withAnimation {
                                model.finishedScanURL = nil
                            }
                            
                            dismiss()
                        } else {
                            errorUploading = true
                        }
                    }
                } label: {
                    Text(errorUploading ? "Upload Error" : "Upload")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 32)
                        .background {
                            if errorUploading {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.red)
                            } else {
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.green)
                            }
                        }
                }
                .padding(20)
            }
        }
    }

    var main: some View {
        VStack(spacing: 36) {
            VStack {
                HStack {
                    Menu {
                        Button("Add Sample USDZ") {
                            if let first = sampleModelsFolder.files.first {
                                withAnimation {
                                    model.finishedScanURL = first.url
                                }
                            }
                        }
                        
                        Button("Fetch cards") {
                            model.fetchAllCards() 
                        }
                    } label: {
                        Text("Add Card")
                            .font(.largeTitle)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .opacity(0.15)
                            )
                    }
                }

                Button {
                    withAnimation {
                        loading = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPresented = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            loading = false
                        }
                    }
                } label: {
                    VStack(spacing: 24) {
                        Image(systemName: "camera.fill")
                            .opacity(loading ? 0 : 1)
                            .overlay {
                                ProgressView()
                                    .controlSize(.large)
                                    .opacity(loading ? 1 : 0)
                                    .environment(\.colorScheme, .dark)
                            }

                        Text("Scan with Camera")
                            .textCase(.uppercase)
                    }
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        UIColor.systemTeal.color,
                                        UIColor.systemTeal.offset(by: 0.1).color
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .brightness(-0.1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("Card Store")
                        .font(.largeTitle)
                        .textCase(.uppercase)

                    ForEach(Array(zip(model.cardsStore.indices, model.cardsStore)), id: \.1.id) { index, card in
                        Button {
                            if !model.cards.contains(where: { $0.id == card.id }) {
                                model.cards.append(card)
                            }
                            dismiss()
                        } label: {
                            CardView(card: card)
                                .scaleEffect(shown ? 1 : 0.9)
                                .opacity(shown ? 1 : 0)
                                .animation(.spring(response: 0.2, dampingFraction: 1, blendDuration: 1).delay(Double(index) * 0.1), value: shown)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .opacity(0.1)
                    .padding(.bottom, -100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
