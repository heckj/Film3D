//
//  Film3DApp.swift
//  Film3D
//
//  Created by Joseph Heck on 2/15/22.
//

import SwiftUI

/// The SwiftUI app context and declaration.
@main
struct Film3DApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, maxWidth: .infinity,
                       minHeight: 400, maxHeight: .infinity,
                       alignment: .center)
        }
    }
}
