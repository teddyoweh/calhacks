//
//  CardsView.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/28/23.
//

import Alamofire
import Files
import SwiftUI

struct CardsView: View {
    @ObservedObject var model: ViewModel
    @State var isPresented = false
    
    var body: some View {
        VStack {
            Text("Cards")
                .font(.largeTitle)
                .textCase(.uppercase)
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(zip(model.cards.indices, model.cards)), id: \.1.id) { index, card in
                        ResponsiveButton(modes: .scale) {
                            model.selectedCard = card
                        } label: {
                            CardView(card: card)
                                .overlay {
//                                    let color = UIColor(hexString: card.backgroundColor) ?? .systemRed
                                    let color = UIColor.systemPink
                                    
                                    if model.selectedCard?.id == card.id {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white, lineWidth: 2)
                                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 0)
                                            .overlay(alignment: .topLeading) {
                                                Text("Selected")
                                                    .textCase(.uppercase)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(color.color)
                                                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 0)
                                                    }
                                            }
                                            .mask {
                                                RoundedRectangle(cornerRadius: 16)
                                            }
                                    }
                                }
                                .scaleEffect(model.entered ? 1 : 0.9)
                                .opacity(model.entered ? 1 : 0)
                                .animation(.spring(response: 0.2, dampingFraction: 1, blendDuration: 1).delay(Double(index) * 0.1 + 0.55), value: model.entered)
                        }
                    }
                }
                .padding(.top, 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    isPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background {
                            VisualEffectView(.regular)
                                .mask {
                                    Circle()
                                }
                                .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 16)
                        }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 32)
        .sheet(isPresented: $isPresented) {
            AddCardView(model: model)
        }
    }
}

struct CardView: View {
    var card: Card
    @State var imagePreview: UIImage?
    
    var body: some View {
//        let color = UIColor(hexString: card.backgroundColor) ?? .systemRed
        let color = UIColor.systemPink
        let color2 = color.offset(by: -0.1)
        let color3 = color.offset(by: 0.05)
        
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 200)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(color.color, lineWidth: 10)
                        .brightness(0.2)
                }
                .padding(.bottom, -24)
                .overlay {
                    if let image = imagePreview {
                        Image(uiImage: image)
                            .aspectRatio(contentMode: .fit)
                            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 8)
                            .offset(y: 40)
                    }
                }
                .zIndex(2)
                
            VStack(alignment: .leading, spacing: 12) {
                Text(card.cardName)
                    .font(.title)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.leading)
                    .onAppear {
                        if let image = card.imagePath {
                            print("image: \(image)")
                            downloadImage(path: image)
                        }
                    }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.moveset.moveOne.name)
                        
                        Text(card.moveset.moveOne.moveDescription)
                            .fontWeight(.regular)
                            .font(.caption)
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.moveset.moveTwo.name)
                        
                        Text(card.moveset.moveTwo.moveDescription)
                            .fontWeight(.regular)
                            .font(.caption)
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
//                Text(card.description)
//                    .font(.title3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .background {
                LinearGradient(
                    colors: [
                        color.color,
                        color3.color
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .brightness(-0.15)
                .mask {
                    RoundedRectangle(cornerRadius: 16)
                }
                .mask {
                    SlantShape(tlOffset: 32)
                }
                .shadow(color: .white.opacity(0.2), radius: 24, x: 0, y: 0)
                .padding(.top, -32)
            }
            .zIndex(4)
        }
        .background {
            LinearGradient(
                colors: [
                    color.color,
                    color2.color
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask {
                RoundedRectangle(cornerRadius: 16)
            }
        }
    }
    
    func downloadImage(path: String) {
        let url = URL(string: "http://50.116.36.84:3000/")!.appendingPathComponent(path)
        
        print("Downloading [image]: \(url)")
        let destination: DownloadRequest.Destination = { _, _ in
            let fileURL = Folder.temporary.url.appendingPathComponent("\(UUID().uuidString).png")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, to: destination).response { response in
            if let error = response.error {
                print("Error downloading file from Alamofire: \(error)")
            } else {
                print("File downloaded successfully: \(response.fileURL?.path ?? "")")
                
                if let url = response.fileURL {
                    print("Loaded png! \(url)")
                    
                    do {
                        let data = try Data(contentsOf: url)
                        if let image = UIImage(data: data) {
                            self.imagePreview = image
                        } else {
                            print("No image from data")
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
        }
    }
}
