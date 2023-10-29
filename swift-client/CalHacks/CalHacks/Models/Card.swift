//
//  Card.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/28/23.
//

import SwiftUI

// MARK: - Pumpkin

struct Card: Codable, Identifiable {
    var id: String
    let cardName: String
    let modelPath: String
    var imagePath: String?
    let moveset: Moveset
}

extension Card {
    init(from decoder: Decoder) throws {
        self.id = UUID().uuidString
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let cardName = try container.decodeIfPresent(String.self, forKey: .cardName) {
            self.cardName = cardName
        } else {
            self.cardName = ""
        }

        if let modelPath = try container.decodeIfPresent(String.self, forKey: .modelPath) {
            self.modelPath = modelPath
        } else {
            self.modelPath = ""
        }
        
        if let imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath) {
            self.imagePath = modelPath
        } else {
            self.imagePath = ""
        }

        if let moveset = try container.decodeIfPresent(Moveset.self, forKey: .moveset) {
            self.moveset = moveset
        } else {
            self.moveset = Moveset(moveOne: .init(name: "", damage: 0, moveDescription: ""), moveTwo: .init(name: "", damage: 0, moveDescription: ""))
        }
    }
}

// MARK: - Moveset

struct Moveset: Codable {
    let moveOne, moveTwo: Move
}

// MARK: - Move

struct Move: Codable {
    let name: String
    let damage: Int
    let moveDescription: String
}

extension Card {
    func getData() -> Data? {
        let encoder = JSONEncoder()

        do {
            let encoded = try encoder.encode(self)
            return encoded
        } catch {
            print("[Card] couldn't encode: \(error)")
        }
        return nil
    }

    static func create(from data: Data) -> Card? {
        let decoder = JSONDecoder()

        do {
            let alarm = try decoder.decode(Card.self, from: data)
            return alarm
        } catch {
            print("[Card] couldn't create: \(error)")
        }

        return nil
    }
}

// struct Card: Identifiable {
//    var id: String
//    var title: String
//    var description: String
//    var backgroundColor: String
//    var move1: Move
//    var move2: Move
//    var previewImage: UIImage?
//    var usdz: Data?
//
//    static let placeholderCard1 = Card(
//        id: "Card1",
//        title: "Placeholder Card",
//        description: "Very epic card for CalHacks!!!",
//        backgroundColor: "00e600",
//        move1: Move.placeholderMove1,
//        move2: Move.placeholderMove2
//    )
//
//    static let placeholderCard2 = Card(
//        id: "Card2",
//        title: "Blue Card",
//        description: "This card is blue!",
//        backgroundColor: "0089ff",
//        move1: Move.placeholderMove1,
//        move2: Move.placeholderMove2
//    )
// }
//
// struct Move: Identifiable {
//    var id: String
//    var title: String
//    var description: String
//    var damage: Double
//
//    static let placeholderMove1 = Move(
//        id: "1",
//        title: "Placeholder Move",
//        description: "A placeholder move. This move does 5 amount of damage.",
//        damage: 5
//    )
//
//    static let placeholderMove2 = Move(
//        id: "2",
//        title: "Very Cool Move",
//        description: "This move is super cool. This move does 15 damage.",
//        damage: 15
//    )
// }

extension Card {
    static let card1 = Card(
        id: "Pumpkin",
        cardName: "Pumpkin",
        modelPath: "models/3C24B73D-F910-45E6-8CA7-634CC4BE5E3F.usdz",
        moveset: Moveset(
            moveOne: Move(
                name: "Gourd Slam",
                damage: 20,
                moveDescription: "The Pumpkin character slams a giant gourd onto the opponent, causing substantial damage."
            ),
            moveTwo: Move(
                name: "Jack-o'-Smash",
                damage: 25,
                moveDescription: "The Pumpkin character transforms into a giant jack-o'-lantern and smashes into the opponent, dealing massive damage."
            )
        )
    )

    static let card2 = Card(
        id: "Apple",
        cardName: "Apple",
        modelPath: "models/A413388B-8166-4B64-95EE-8698F5ABB57A.usdz",
        moveset: Moveset(
            moveOne: Move(
                name: "Bite",
                damage: 15,
                moveDescription: "Take a crunchy bite out of your opponent."
            ),
            moveTwo: Move(
                name: "Exploding Cider",
                damage: 20,
                moveDescription: "Unleash a fiery explosion of apple goodness."
            )
        )
    )
}
