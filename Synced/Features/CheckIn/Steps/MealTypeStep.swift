import SwiftUI

struct MealTypeStep: View {
    @Binding var value: String

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(text: "Step 3 of 5")
                .foregroundStyle(SYN.textFaint)

            Spacer().frame(height: 24)

            Text("What did you eat?")
                .font(.synDisplay(28, weight: .bold))
                .foregroundStyle(SYN.text)

            Spacer().frame(height: 8)

            Text("Be specific. This builds your personal trends.")
                .font(.synText(15))
                .foregroundStyle(SYN.textDim)

            Spacer().frame(height: 48)

            ZStack(alignment: .topLeading) {
                if value.isEmpty {
                    Text("e.g. chicken rice broccoli")
                        .font(.synText(16))
                        .foregroundStyle(SYN.textFaint)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $value)
                    .focused($isFocused)
                    .font(.synText(16))
                    .foregroundStyle(SYN.text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .submitLabel(.done)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(SYN.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(SYN.cyan, lineWidth: 1.5)
            )

            Spacer().frame(height: 12)

            Text("Logged meals build your performance profile over time.")
                .font(.synText(12))
                .foregroundStyle(SYN.textFaint)

            Spacer()
        }
        .padding(.horizontal, Spacing.pageH)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isFocused = true
            }
        }
    }
}
