import SwiftUI
import UIKit

struct SpecInput: View {
    @Binding var value: String
    var placeholder: String
    var label: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocap: TextInputAutocapitalization = .words
    var maxLength: Int? = nil
    var isValid: Bool? = nil          // nil = neutral, false = error, true = success
    var autoFocus: Bool = false

    @FocusState private var focused: Bool

    private var borderColor: Color {
        if let isValid, !isValid { return SYN.red }
        return focused ? SYN.cyan : SYN.border
    }

    private var glowColor: Color {
        if let isValid, !isValid { return SYN.red.opacity(0.45) }
        return focused ? SYN.cyan.opacity(0.45) : .clear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.synText(11, weight: .semibold))
                    .tracking(0.96)         // ~0.08em on 12px
                    .foregroundStyle(SYN.textFaint)
                    .textCase(.uppercase)
            }

            HStack(spacing: 10) {
                TextField("", text: $value, prompt: Text(placeholder).foregroundColor(SYN.textFaint))
                    .font(.synText(16))
                    .foregroundStyle(SYN.text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocap)
                    .autocorrectionDisabled(true)
                    .focused($focused)
                    .onChange(of: value) { _, newValue in
                        if let maxLength, newValue.count > maxLength {
                            value = String(newValue.prefix(maxLength))
                        }
                    }

                if isValid == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SYN.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .shadow(color: glowColor, radius: 12)
            .animation(.easeOut(duration: 0.2), value: focused)
            .animation(.easeOut(duration: 0.2), value: isValid)
        }
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    focused = true
                }
            }
        }
    }
}
