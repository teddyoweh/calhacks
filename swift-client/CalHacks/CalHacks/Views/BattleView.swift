//
//  BattleView.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/29/23.
//

import SwiftUI

struct BattleView: View {
    @ObservedObject var model: ViewModel
    @State var pressedBattle = false
    
    var body: some View {
        VStack {
            VStack {
                Menu {
                    Button("Game Test") {
                        model.otherCard = Card.card2
                        model.playingGame = true
                    }
                } label: {
                    Text("Battle")
                        .font(.largeTitle)
                        .textCase(.uppercase)
                }
            
                VStack(spacing: 24) {
                    HStack {
                        Text(model.finalName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("You")
                            .textCase(.uppercase)
                            .opacity(0.5)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background {
                        Color.yellow
                            .opacity(0.05)
                    }
                    .mask {
                        RoundedRectangle(cornerRadius: 32)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.black, lineWidth: 2)
                            .brightness(0.3)
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 8) {
                        Text("Nearby People")
                    
                        VStack(spacing: 0) {
                            if model.availablePeers.isEmpty {
                                Text("No one else online rn :(")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(Array(zip(model.availablePeers.indices, model.availablePeers)), id: \.1.displayName) { index, peer in
                                    let selected = model.selectedPeerID?.displayName == peer.displayName
                                
                                    Button {
                                        if model.selectedPeerID?.displayName == peer.displayName {
                                            model.selectedPeerID = nil
                                        } else {
                                            model.selectedPeerID = peer
                                        }
                                    } label: {
                                        HStack {
                                            Text(peer.displayName)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                            Circle()
                                                .fill(Color.yellow)
                                                .opacity(selected ? 1 : 0)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .overlay {
                                                            if selected {
                                                                Image(systemName: "checkmark")
                                                                    .font(.body)
                                                                    .fontWeight(.bold)
                                                            }
                                                        }
                                                }
                                                .frame(width: 30, height: 30)
                                        }
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 20)
                                        .contentShape(Rectangle())
                                    }
                                
                                    if index < model.connectedPeers.count - 1 {
                                        Rectangle()
                                            .foregroundColor(Color.black)
                                            .brightness(0.3)
                                            .frame(height: 2)
                                    }
                                }
                            }
                        }
                        .background {
                            Color.white
                                .opacity(0.05)
                        }
                        .mask {
                            RoundedRectangle(cornerRadius: 32)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.black, lineWidth: 2)
                                .brightness(0.3)
                        }
                        
                        Image("Swords")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 300)
                            .padding(60)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        withAnimation {
                            pressedBattle = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation {
                                pressedBattle = false
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            model.battle()
                        }
                    } label: {
                        Text("Battle")
                            .font(.title)
                            .foregroundColor(.white)
                            .opacity(pressedBattle ? 0 : 1)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if pressedBattle {
                                    Text("Waiting for response...")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 32)
                            .background {
                                LinearGradient(
                                    colors: [
                                        Color.yellow,
                                        Color.orange
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask {
                                    RoundedRectangle(cornerRadius: 32)
                                }
                            }
                    }
                    .opacity(model.selectedPeerID != nil ? 1 : 0.5)
                    .disabled(model.selectedPeerID == nil)
                    .padding(20)
                }
            }
            
            Spacer()
        }
        .padding(.top, 32)
    }
}
