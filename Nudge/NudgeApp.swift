//
//  NudgeApp.swift
//  Nudge
//
//  Created by Ishani Patel on 04/07/26.
//

import SwiftUI
import CoreData

@main
struct NudgeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
