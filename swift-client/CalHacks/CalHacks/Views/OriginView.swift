//
//  OriginView.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/28/23.
//

import SwiftUI

struct OriginView: View {
    @ObservedObject var model: ViewModel
    @State var name = ""
    @State var placeholderName = "\(adjectives.randomElement()!)-\(animals.randomElement()!)"

    var body: some View {
        VStack(spacing: 32) {
            Text("P.M!")
                .font(.largeTitle)
                .scaleEffect(model.entered ? 0.5 : 1)
                .opacity(model.entered ? 0 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1).delay(0.4), value: model.entered)

            Spacer()

            VStack(spacing: 12) {
                Text("Your Name")
                    .font(.title3)

                TextField(placeholderName, text: $name, prompt: Text(placeholderName).foregroundColor(.white.opacity(0.5)))
                    .font(.title)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white, lineWidth: 2)
                            .opacity(0.5)
                    }
            }
            .scaleEffect(model.entered ? 0.5 : 1)
            .opacity(model.entered ? 0 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1).delay(0.18), value: model.entered)

            Button {
                let enteredName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                model.finalName = enteredName.isEmpty ? placeholderName : enteredName
                model.start()
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                model.entered = true
            } label: {
                Text("Play")
                    .textCase(.uppercase)
                    .font(.title)
                    .foregroundColor(.green)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background {
                        Capsule()
                            .fill(Color.white)
                    }
            }
            .scaleEffect(model.entered ? 0.5 : 1)
            .opacity(model.entered ? 0 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1).delay(0.1), value: model.entered)
        }
        .fontWeight(.black)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background {
            Color.green
                .mask(SlantShape(brOffset: 40))
                .padding(.bottom, -40)
                .ignoresSafeArea()
                .offset(y: model.entered ? -UIScreen.main.bounds.height * 1.5 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 1, blendDuration: 1), value: model.entered)
        }
    }
}
