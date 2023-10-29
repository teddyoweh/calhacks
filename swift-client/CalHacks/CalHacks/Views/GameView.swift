//
//  GameView.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/29/23.
//

import Alamofire
import Files
import SceneKit
import SwiftUI

// let manager = ServerTrustManager(evaluators: ["example.com": DisabledEvaluator()])
// let session = Session(serverTrustManager: manager)

struct GameView: View {
    @ObservedObject var model: ViewModel
    @State var loadedModelURL: URL?
    @State var loadedModelURL2: URL?
    
    var body: some View {
        VStack {
            if let selectedCard = model.selectedCard {
                Text("FIGHT!")
                    .padding(.vertical, 32)
                
                VStack(spacing: 0) {
                    if let loadedModelURL2 {
                        let scene: SCNScene? = {
                            if let scene = try? SCNScene(url: loadedModelURL2) {
                                scene.background.contents = UIColor.systemRed
                                return scene
                            }
                            return nil
                        }()
                        
                        if let scene {
                            SceneView(scene: scene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                                .overlay(alignment: .top) {
                                    HacksProgressView(tintColor: .green, progress: CGFloat(model.otherHealth) / CGFloat(100))
                                        .frame(height: 24)
                                        .overlay {
                                            Text("Opponent's health: \(Int(model.otherHealth))")
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                        } else {
                            ProgressView()
                        }
                    } else {
                        ProgressView()
                    }
                    
                    if let loadedModelURL {
                        let scene: SCNScene? = {
                            if let scene = try? SCNScene(url: loadedModelURL) {
                                scene.background.contents = UIColor.systemBlue
                                return scene
                            }
                            return nil
                        }()
                        
                        if let scene {
                            SceneView(scene: scene, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                                .overlay(alignment: .top) {
                                    HacksProgressView(tintColor: .green, progress: CGFloat(model.ownHealth) / CGFloat(100))
                                        .frame(height: 24)
                                        .overlay {
                                            Text("Own health: \(Int(model.ownHealth))")
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 8)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                        } else {
                            ProgressView()
                        }
                    } else {
                        ProgressView()
                    }
                    
                    
                    
                    HStack(alignment: .top) {
                        Button {
                            model.sendDamage(value: selectedCard.moveset.moveOne.damage)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedCard.moveset.moveOne.name)
                                
                                Text(selectedCard.moveset.moveOne.moveDescription)
                                    .fontWeight(.regular)
                                    .font(.caption)
                                
                                Text("\(selectedCard.moveset.moveOne.damage) Damage!")
                            }
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.1))
                            }
                        }
                        
                        Button {
                            model.sendDamage(value: selectedCard.moveset.moveTwo.damage)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedCard.moveset.moveTwo.name)
                                
                                Text(selectedCard.moveset.moveTwo.moveDescription)
                                    .fontWeight(.regular)
                                    .font(.caption)
                                
                                Text("\(selectedCard.moveset.moveTwo.damage) Damage!")
                            }
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .background {
                        Color.blue
                            .ignoresSafeArea()
                            .padding(.bottom, -200)
                    }
                    .opacity(loadedModelURL == nil ? 0 : 1)
                }
                .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1), value: loadedModelURL2)
                .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1), value: loadedModelURL)
            }
        }
        .onChange(of: model.playingGame) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let selectedCard = model.selectedCard {
                        downloadCard()
                    }
                    
                    if let otherCard = model.otherCard {
                        downloadOtherCard()
                    }
                }
            } else {
                loadedModelURL = nil
                loadedModelURL2 = nil
            }
        }
        .onChange(of: model.selectedCard?.id) { oldValue, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                downloadCard()
            }
        }
        .onChange(of: model.otherCard?.id) { oldValue, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                downloadOtherCard()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if let won = model.won {
                ZStack {
                    VisualEffectView(.systemThickMaterialDark)
                        .ignoresSafeArea()
                    
                    VStack {
                        if won {
                            Text("You Won!!!")
                                .font(.largeTitle)
                                .scaleEffect(1.5)
                                .rotationEffect(.degrees(5))
                        } else {
                            Text("You Lost :(")
                        }
                        
                        Button {
                            model.endBattle()
                        } label: {
                            Text("Exit")
                                .foregroundColor(.white)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 32)
                                .background {
                                    Color.green
                                        .brightness(-0.1)
                                        .mask {
                                            RoundedRectangle(cornerRadius: 24)
                                        }
                                }
                        }
                    }
                    .font(.largeTitle)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                model.endBattle()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(width: 42, height: 42)
                    .background(
                        VisualEffectView(.regular)
                            .mask {
                                Circle()
                            }
                    )
            }
            .padding(20)
        }
        .opacity(model.playingGame ? 1 : 0)
        .background {
            Color.green.brightness(-0.5)
                .mask(SlantShape(brOffset: 40))
                .padding(.bottom, -40)
                .ignoresSafeArea()
                .offset(y: model.playingGame ? 0 : -UIScreen.main.bounds.height * 1.5)
                .animation(.spring(response: 0.8, dampingFraction: 1, blendDuration: 1), value: model.playingGame)
        }
    }
    
    func downloadCard() {
        guard let selectedCard = model.selectedCard else { return }
        let url = URL(string: "http://50.116.36.84:3000/")!.appendingPathComponent(selectedCard.modelPath)
        
        print("Downloading [own]: \(url)")
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = Folder.temporary.url.appendingPathComponent("\(UUID().uuidString).usdz")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, to: destination).response { response in
            if let error = response.error {
                print("Error downloading file from Alamofire: \(error)")
            } else {
                print("File downloaded successfully: \(response.fileURL?.path ?? "")")
                
                if let url = response.fileURL {
                    print("Loaded model! \(url)")
                    self.loadedModelURL = url
                }
            }
        }
    }
    
    func downloadOtherCard() {
        guard let otherCard = model.otherCard else { return }
        let url = URL(string: "http://50.116.36.84:3000/")!.appendingPathComponent(otherCard.modelPath)
        
        print("Downloading [other]: \(url)")
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = Folder.temporary.url.appendingPathComponent("\(UUID().uuidString).usdz")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, to: destination).response { response in
            if let error = response.error {
                print("Error downloading file from Alamofire: \(error)")
            } else {
                print("File downloaded successfully: \(response.fileURL?.path ?? "")")
                
                if let url = response.fileURL {
                    print("Loaded model! \(url)")
                    self.loadedModelURL2 = url
                }
            }
        }
    }
}
