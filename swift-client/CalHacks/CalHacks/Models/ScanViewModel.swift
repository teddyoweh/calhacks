//
//  ScanViewModel.swift
//  CalHacks
//
//  Created by Andrew Zheng on 10/29/23.
//

import Combine
import Files
import RealityKit
import SwiftUI

let snapshotsFolder = try! Folder.documents!.createSubfolderIfNeeded(withName: "Snapshots")
let imagesFolder = try! Folder.documents!.createSubfolderIfNeeded(withName: "Images")
let modelsFolder = try! Folder.documents!.createSubfolderIfNeeded(withName: "Models")
let sampleSnapshotsFolder = try! Folder(path: Bundle.main.resourceURL!.appendingPathComponent("Snapshots/").path)
let sampleImagesFolder = try! Folder(path: Bundle.main.resourceURL!.appendingPathComponent("Images/").path)
let sampleModelsFolder = try! Folder(path: Bundle.main.resourceURL!.appendingPathComponent("Models/").path)

@MainActor class ScanViewModel: ObservableObject {
    @Published var session: ObjectCaptureSession?
    @Published var finished = false
    @Published var finishedScanningProcess = false

    @Published var photogrammetrySession: PhotogrammetrySession?
    @Published var filename = "\(UUID().uuidString).usdz"
    @Published var outputFile: URL!
    var processSession = PassthroughSubject<Void, Never>()

    init() {
        outputFile = modelsFolder.url.appendingPathComponent(filename)
    }

    func resetFolders() {
        print("Resetting!")

        for file in snapshotsFolder.files {
            do {
                try file.delete()
            } catch {
                print("Error deleting snap file: \(error)")
            }
        }

        for folder in snapshotsFolder.subfolders {
            do {
                try folder.delete()
            } catch {
                print("Error deleting snap folder: \(error)")
            }
        }

        for file in imagesFolder.files {
            do {
                try file.delete()
            } catch {
                print("Error deleting image file: \(error)")
            }
        }

        for folder in imagesFolder.subfolders {
            do {
                try folder.delete()
            } catch {
                print("Error deleting image folder: \(error)")
            }
        }
    }

    func finishScan() {
        DispatchQueue.main.async {
            withAnimation {
                self.finishedScanningProcess = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.finished = true
            self.session?.finish()

            var configuration = PhotogrammetrySession.Configuration()
            configuration.checkpointDirectory = snapshotsFolder.url

            do {
                let timer = TimeElapsed()
                print("Starting photogrammetrySession")
                self.photogrammetrySession = try PhotogrammetrySession(
                    input: imagesFolder.url,
                    configuration: configuration
                )
                print("Created photogrammetrySession: \(timer)")

                self.processSession.send()

            } catch {
                print("Error: \(error)")
            }
        }
    }

    func start() {
        resetFolders()

        print("snapshotsFolder: \(snapshotsFolder.files.count())")

        var configuration = ObjectCaptureSession.Configuration()
        configuration.checkpointDirectory = snapshotsFolder.url

        print("Created config")
        let session = ObjectCaptureSession()

        print("Created session")
        session.start(
            imagesDirectory: imagesFolder.url,
            configuration: configuration
        )

        print("Started session")
        self.session = session

        print("Set session!")
    }
}
