//
//  OllamaViewModel.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/5/25.
//

import SwiftUI

class OllamaViewModel: ObservableObject {
    @Published var conversation: [Message] = []
    @Published var isLoading: Bool = false
    @Published var availableModels: [String] = []
    @Published var errorMessage: String = ""
    
    private let baseURL = "http://localhost:11434/api"
    private let urlSession: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120.0
        config.timeoutIntervalForResource = 300.0
        self.urlSession = URLSession(configuration: config)
    }
    
    func fetchAvailableModels() async {
        guard let url = URL(string: "\(baseURL)/tags") else { return }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    self.errorMessage = "Invalid server response"
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
                
                await MainActor.run {
                    self.availableModels = response.models.map { $0.name }
                    if self.availableModels.isEmpty {
                        self.availableModels = ["llama3.2:latest"]
                    }
                }
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Server error: \(httpResponse.statusCode), \(errorText)")
                
                await MainActor.run {
                    self.errorMessage = "Server returned error: \(httpResponse.statusCode)"
                }
            }
        } catch {
            print("Error fetching models: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Failed to fetch models: \(error.localizedDescription)"
                
                if self.availableModels.isEmpty {
                    self.availableModels = ["llama3.2", "llama3", "mistral"]
                }
            }
        }
    }
    
    func sendPrompt(prompt: String, model: String) async {
        let userMessage = Message(role: .user, content: prompt)
        
        await MainActor.run {
            conversation.append(userMessage)
            isLoading = true
            errorMessage = ""
        }
        
        guard let url = URL(string: "\(baseURL)/generate") else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid URL"
            }
            return
        }
        
        let requestBody = GenerateRequest(model: model, prompt: prompt)
        
        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to encode request"
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid server response"
                    
                    let errorMsg = Message(role: .assistant, content: "Error: Failed to get a valid response from Ollama. Please check if the model is running correctly.")
                    conversation.append(errorMsg)
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                let responseText = parseStreamingResponse(data: data)
                
                if responseText.isEmpty {
                    await MainActor.run {
                        let errorMsg = Message(role: .assistant, content: "Received empty response from Ollama. The model might be having issues.")
                        conversation.append(errorMsg)
                        isLoading = false
                    }
                    return
                }
                
                let assistantMessage = Message(role: .assistant, content: responseText)
                
                await MainActor.run {
                    conversation.append(assistantMessage)
                    isLoading = false
                }
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
                print("Server error: \(httpResponse.statusCode), \(errorText)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Server error: \(httpResponse.statusCode)"
                    
                    let errorMsg = Message(role: .assistant, content: "Error: \(errorText)")
                    conversation.append(errorMsg)
                }
            }
        } catch {
            print("Error sending prompt: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                errorMessage = "Request failed: \(error.localizedDescription)"
                
                let errorMsg = Message(role: .assistant, content: "Error: Unable to get a response from Ollama. Please make sure Ollama is running and the model '\(model)' is available.\n\nTechnical details: \(error.localizedDescription)")
                conversation.append(errorMsg)
            }
        }
    }
    
    private func parseStreamingResponse(data: Data) -> String {
        let text = String(data: data, encoding: .utf8) ?? ""
        var responseText = ""
        
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        for line in lines {
            if let data = line.data(using: .utf8),
               let response = try? JSONDecoder().decode(StreamResponse.self, from: data) {
                responseText += response.response
            } else {
                print("Failed to parse line: \(line)")
            }
        }
        
        return responseText
    }
}
