//
//  ContentView.swift
//  Film3D
//
//  Created by Joseph Heck on 2/15/22.
//

import SwiftUI

/// The primary content view for the app.
///
/// Included to allow for (easier) future modification to allow for different app navigation models.
struct ContentView: View {
    var body: some View {
        SpinARView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
