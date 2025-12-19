//
//  knobbyApp.swift
//  knobby
//
//  Created by Grigory Moroz on 19.12.25.
//

import SwiftUI

@main
struct knobbyApp: App {
    init() {
        // Configure RevenueCat at app launch
        PurchaseManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
