//
//  Created with ♥ by Serhii Pryimachuk on 29.10.2023.
//  

import SwiftUI

@main
struct LockViewApp: App {
    var body: some Scene {
        WindowGroup {
            LockView(lockType: .both, lockPin: "1111", isEnabled: true) {
                Text("Oh hi!")
            }
        }
    }
}
