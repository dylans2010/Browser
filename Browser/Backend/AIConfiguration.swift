import SwiftUI

class AIConfiguration: ObservableObject {
    @AppStorage("openrouter_api_key") var apiKey: String = ""
    @AppStorage("selected_ai_model") var selectedModel: String = "openai/gpt-4o-mini"
    @AppStorage("custom_ai_model") var customModel: String = ""

    var currentModel: String {
        customModel.isEmpty ? selectedModel : customModel
    }
}
