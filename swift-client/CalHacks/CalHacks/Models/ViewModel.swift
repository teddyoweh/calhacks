//
//  ViewModel.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/28/23.
//

import Alamofire
import Combine
import MultipeerConnectivity
import SwiftUI
import SwiftyJSON

enum Tab {
    case cards
    case battle
    case config
}

class ViewModel: NSObject, ObservableObject {
    @Published var entered = false
    @Published var selectedTab = Tab.cards
    @Published var cards = [Card.card1]
    @Published var cardsStore = [Card.card2]
    @Published var selectedCard: Card? = Card.card1

    @Published var finishedScanURL: URL?

    // MARK: - Multipeer

    @Published var finalName = ""
    @Published var selectedPeerID: MCPeerID?

    // MARK: - Game

//    @Published var gameTurn = ""
    @Published var ownHealth = CGFloat(100)
    @Published var otherHealth = CGFloat(100)
    @Published var otherCard: Card?
    @Published var playingGame = false
    @Published var won: Bool? = nil
    var cancellables = Set<AnyCancellable>()

    let serviceType = "my-service"
    var peerID: MCPeerID!
    var session: MCSession!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    @Published var connectedPeers: [MCPeerID] = []
    @Published var availablePeers: [MCPeerID] = []

    override init() {
        super.init()

        $ownHealth.sink { [weak self] newValue in
            guard let self else { return }

            if newValue <= 0 {
                withAnimation {
                    self.won = false
                }
            }
        }
        .store(in: &cancellables)

        $otherHealth.sink { [weak self] newValue in
            guard let self else { return }

            if newValue <= 0 {
                withAnimation {
                    self.won = true
                }
            }
        }
        .store(in: &cancellables)
    }

    /// start multipeer
    func start() {
        /// ask for your name on startup
        peerID = MCPeerID(displayName: finalName)
        session = MCSession(peer: peerID)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)

        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self

        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }

    let apiGetCardsUrl = "http://50.116.36.84:3000/api/get-cards" // Replace with your actual API endpoint

    func fetchAllCards() {
        // Example usage:
        getCardsData { cards, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let cards = cards {
                // Handle the parsed cards data here
//                for card in cards {
//                    print("Card Name: \(card.cardName)")
//                    print("Model Path: \(card.modelPath)")
//                    print("Move One Name: \(card.moveset.moveOne.name)")
//                    print("Move Two Name: \(card.moveset.moveTwo.name)")
//                    print("-----------")
//                }

                DispatchQueue.main.async {
                    self.cardsStore = cards
                }
            }
        }
    }

    func getCardsData(completion: @escaping ([Card]?, Error?) -> Void) {
        // Define the API endpoint URL
        let apiUrl = apiGetCardsUrl

        AF.request(apiUrl).responseJSON { response in
            switch response.result {
            case .success(let value):
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                    let json = JSON(jsonData)

                    var cards = [Card]()
                    for (key, value) in json {
                        let data = try! value.rawData()
                        if var card = Card.create(from: data) {
                            card.id = key
                            cards.append(card)
                        }
                    }

//                    print("cards: \(cards)")
                    completion(cards, nil)
                } catch {
                    print("error: \(error)")
                    completion(nil, error)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func upload(name: String, image: UIImage?, completion: @escaping (Bool) -> Void) {
        guard let finishedScanURL else {
            print("No finished URL!")
            return
        }

        print("finishedScanURL: \(finishedScanURL) -> \(finishedScanURL.lastPathComponent)")

        let apiUrl = "http://50.116.36.84:3000/api/create" // Replace with your API endpoint

        AF.upload(
            multipartFormData: { multipartFormData in

                do {
                    let data = try Data(contentsOf: finishedScanURL)
                    multipartFormData.append(data, withName: "model", fileName: finishedScanURL.lastPathComponent, mimeType: "model/vnd.usdz+zip")
                } catch {
                    print("Error reading USDZ file:", error)
                    return
                }

                multipartFormData.append(name.data(using: .utf8)!, withName: "name")
                
                if let image {
                    if let png = image.pngData() {
                        print("png: \(png)")
                        multipartFormData.append(png, withName: "image", fileName: "\(UUID().uuidString).png", mimeType: "image/png")
                    } else {
                        print("NO png data")
                    }
                } else {
                    print("no image...")
                }
                
            },
            to: apiUrl
        )
        .responseJSON { response in
            switch response.result {
            case .success:
                if let data = response.data {
                    if let json = try? JSON(data: data) {
                        print(json)
                    }
                }
                completion(true)
            case .failure(let error):
                print("Error uploading file:", error)
                print(error)
                completion(false)
            }
        }
    }

    func battle() {
        guard let selectedPeerID else { return }
        won = nil
        serviceBrowser.invitePeer(selectedPeerID, to: session, withContext: nil, timeout: 20)
        print("getting \(selectedPeerID)")
    }

    func endBattle() {
        playingGame = false
        session.disconnect()
        otherCard = nil
        ownHealth = 100
        otherHealth = 100
        won = nil
    }
}

/// from https://www.ralfebert.com/ios-app-development/multipeer-connectivity/

extension ViewModel {
    func sendInitialData() {
        print("Sending initial data!")
        guard let card = selectedCard else {
            print("Had to return first")
            return
        }
        guard let cardData = card.getData() else {
            print("Had to return second")
            return
        }

        do {
            try session.send(cardData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error sending: \(error)")
        }
    }

    func sendDamage(value: Int) {
        do {
            let data = withUnsafeBytes(of: value) { Data($0) }
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)

            withAnimation {
                otherHealth -= CGFloat(value)
            }
        } catch {
            print("Error sending int: \(error)")
        }
    }
}

extension ViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer \(peerID)")

        UIAlertController.presentAlert(title: "'\(peerID.displayName)' wants to play!", message: "Do you want to play them?", addCancel: false, addOk: false) { alert in
            alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                invitationHandler(true, self.session)
                
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                invitationHandler(false, self.session)
            })
        }
    }
}

extension ViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("ServiceBrowser found peer: \(peerID)")

        availablePeers.append(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("ServiceBrowser lost peer: \(peerID)")

        DispatchQueue.main.async {
            self.availablePeers = self.availablePeers.filter { $0.displayName != peerID.displayName }

            if peerID == self.selectedPeerID {
                self.endBattle()
            }
        }
    }
}

extension ViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.debugDescription)")
        DispatchQueue.main.async {
            
            if state == .connected {
                self.sendInitialData()
            }
            
            self.connectedPeers = session.connectedPeers

            if self.connectedPeers.isEmpty {
                self.playingGame = false
            } else {
                self.playingGame = true
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        /// got data!

        if let card = Card.create(from: data) {
            print("got card!!")
            DispatchQueue.main.async {
                self.otherCard = card
            }
        } else {
            print("Couldn't read card")
            let value = data.withUnsafeBytes {
                $0.load(as: Int.self)
            }

            if value < 50 {
                print("value: \(value)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.ownHealth -= CGFloat(value)
                    }
                }
            }
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Receiving streams is not supported")
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Receiving resources is not supported")
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Receiving resources is not supported")
    }
}

// extension PKStroke: Hashable {
//    public static func == (lhs: PKStroke, rhs: PKStroke) -> Bool {
//        lhs.path.creationDate == rhs.path.creationDate
//    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(path.creationDate)
//    }
// }

extension MCSessionState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .notConnected:
            return "notConnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        @unknown default:
            return "\(rawValue)"
        }
    }
}

extension UIAlertController {
    static func presentAlertWithOk(
        title: String,
        message: String? = nil
    ) {
        DispatchQueue.main.async {
            presentAlert(title: title, message: message, addCancel: false, addOk: true)
        }
    }

    static func presentAlert(
        title: String,
        message: String? = nil,
        addCancel: Bool = true,
        addOk: Bool = false,
        configuration: ((inout UIAlertController) -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            var alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            configuration?(&alert)

            if addCancel {
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(cancelAction)
            }

            if addOk {
                let okAction = UIAlertAction(title: "Ok", style: .default)
                alert.addAction(okAction)
            }

            let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }

                topController.present(alert, animated: true)
            }
        }
    }
}
