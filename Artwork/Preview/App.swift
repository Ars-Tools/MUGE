//
//  App.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
import SwiftUI
import Artwork
import CIArtwork
import Procedure
@main
struct App: SwiftUI.App {
    @inlinable
    var body: some Scene {
        WindowGroup {
            Exhibit(artwork: GrayScottWE())
        }
    }
}
