//
//  Created with ♥ by Serhii Pryimachuk on 29.10.2023.
//  

import SwiftUI
import LocalAuthentication

struct LockView<Content: View>: View {
    
    var lockType: LockType
    var lockPin: String
    var isEnabled: Bool
    var lockWhenDidEnterForeground: Bool = true
    @ViewBuilder var content: Content
    
    @State private var pin: String = ""
    @State private var animateField: Bool = false
    @State private var isUnlocked: Bool = false
    @State private var noBiometricAccess: Bool = false
    
    var forgotPIN: () -> () = { }
    
    let context = LAContext()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            content
                .frame(width: size.width, height: size.height)
            
            if isEnabled && !isUnlocked {
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea()
                    if (lockType == .both && !noBiometricAccess) || lockType == .biometric {
                        Group {
                            if noBiometricAccess {
                                Text("Enable biometric authentification in Settings to unlick the view.")
                                    .font(.callout)
                                    .multilineTextAlignment(.leading)
                                    .padding(50)
                            } else {
                                // Biometric / Pin unlock
                                VStack(spacing: 12) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "lock")
                                            .font(.largeTitle)
                                        
                                        Text("Tap to unlock")
                                            .font(.caption2)
                                            .foregroundStyle(.gray)
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                                    .onTapGesture {
                                        unlockView()
                                    }
                                    
                                    if lockType == .both {
                                        Text("Enter pin")
                                            .frame(width: 100, height: 40)
                                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                                            .containerShape(.rect)
                                            .onTapGesture {
                                                 noBiometricAccess = true
                                            }
                                    }
                                }
                            }
                        }
                    } else {
                        NumberPadPinView()
                    }
                }
                .environment(\.colorScheme, .dark)
                .transition(.offset(y: size.height + 100))
            }
        }
        .onChange(of: isEnabled, initial: true) { oldValue, newValue in
            if newValue {
                unlockView()
            }
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue != .active && lockWhenDidEnterForeground {
                isUnlocked = false
                pin = ""
            }
        }
    }
    
    private func unlockView() {
        Task {
            if isBiometricAvaliable && lockType != .number {
                if let result = try? await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock the app"), result {
                    print("Unlocked")
                    withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                        isUnlocked = true
                    } completion: {
                        pin = ""
                    }
                }
            }
            
            noBiometricAccess = !isBiometricAvaliable
        }
    }
    
    private var isBiometricAvaliable: Bool {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    @ViewBuilder
    private func NumberPadPinView() -> some View {
        VStack(spacing: 15) {
         Text("Enter pin")
                .font(.title.bold())
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    if lockType == .both && isBiometricAvaliable {
                        Button("Back", systemImage: "arrow.left") {
                            pin = ""
                            noBiometricAccess = false
                        }
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .tint(.primary)
                        .padding(.leading)
                    }
                }
            
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 50, height: 50)
                        .overlay {
                            if pin.count > index {
                                let index = pin.index(pin.startIndex, offsetBy: index)
                                let string = String(pin[index])
                                
                                Text(string)
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: animateField) { content, vale in
                content
                    .offset(x: vale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(30, duration: 0.07)
                    CubicKeyframe(-30, duration: 0.07)
                    CubicKeyframe(20, duration: 0.07)
                    CubicKeyframe(-20, duration: 0.07)
                    CubicKeyframe(0, duration: 0.07)
                }
            }
            .padding(.top, 15)
            .overlay(alignment: .bottomTrailing) {
                Button("Forgot PIN?", action: forgotPIN)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .offset(y: 40)
            }
            .frame(maxHeight: .infinity)
            
            GeometryReader { _ in
                LazyVGrid(columns: Array(repeating: GridItem(), count: 3)) {
                    ForEach(1...9, id: \.self) { number in
                        Button(number.formatted()) {
                            if pin.count < 4 {
                                pin.append(number.formatted())
                            }
                        }
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .contentShape(.rect)
                    }
                    
                    
                    Button("Delete", systemImage: "delete.backward") {
                        if !pin.isEmpty {
                            pin.removeLast()
                        }
                    }
                    .font(.title)
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .contentShape(.rect)
                    
                    Button(String(0)) {
                        if pin.count < 4 {
                            pin.append(String(0))
                        }
                    }
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .contentShape(.rect)
                }
                .tint(.primary)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .onChange(of: pin) { oldValue, newValue in
                if newValue.count == 4 {
                    if lockPin == pin {
                        print("UNLOCKED")
                        withAnimation(.snappy, completionCriteria: .logicallyComplete) {
                            isUnlocked = true
                        } completion: {
                            pin = ""
                            noBiometricAccess = !isBiometricAvaliable
                        }

                    } else {
                        print("WRONG PASSWORD")
                        pin = ""
                        animateField.toggle()
                    }
                }
            }
        }
        .padding()
        .environment(\.colorScheme, .dark)
    }
    
    enum LockType: LocalizedStringKey {
        case biometric = "Bionetric auth"
        case number = "Number lock"
        case both = "First preference will be biometric, and if it's not avaliable, it will go for number lock."
    }
}

#Preview {
    LockView(lockType: .biometric, lockPin: "1111", isEnabled: true) {
        Text("Oh hi!")
    }
}
