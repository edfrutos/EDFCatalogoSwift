import SwiftUI

public struct SecureFieldWithToggle: View {
    let placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    
    @State private var isSecure: Bool = true
    
    public init(_ placeholder: String, text: Binding<String>, isDisabled: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isDisabled = isDisabled
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .disabled(isDisabled)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .disabled(isDisabled)
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
