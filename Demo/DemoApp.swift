import SwiftUI
import SemanticIndexSync
import SemanticIndexSyncUI

/// Host app for the `SemanticIndexSync` workbench.
///
/// The app deliberately owns the configuration rather than letting the library
/// supply a default: which corpus to index, which model identifiers stand in for
/// the on-device model before and after an OS update, and what background budget
/// this product has chosen are all product decisions. A package that hardcoded a
/// battery floor would have made one of them on the app's behalf.
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            IndexWorkbenchView(configuration: .demo)
        }
    }
}
