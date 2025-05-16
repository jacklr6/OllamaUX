//
//  OllamaManager.swift
//  OllamaUX
//
//  Created by Jack Rogers on 5/5/25.
//

import Foundation
import SwiftUI

class OllamaManager: ObservableObject {
    @Published var isOllamaRunning: Bool = false
    var ollamaTask: Process?
    
    func checkOllamaStatus(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "http://localhost:11434/api/version") else {
            DispatchQueue.main.async {
                self.isOllamaRunning = false
                completion?(false)
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let isRunning = (response as? HTTPURLResponse)?.statusCode == 200
            
            DispatchQueue.main.async {
                self?.isOllamaRunning = isRunning
                completion?(isRunning)
                
                if let data = data, isRunning {
                    print("Ollama server is running: \(String(data: data, encoding: .utf8) ?? "Unknown version")")
                } else if let error = error {
                    print("Ollama server check failed: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    func checkIfModelExists(modelName: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:11434/api/tags") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let modelsResponse = try? JSONDecoder().decode(ModelsResponse.self, from: data) else {
                completion(false)
                return
            }
            
            let modelExists = modelsResponse.models.contains { $0.name == modelName }
            completion(modelExists)
        }.resume()
    }
    
    func pullModel(modelName: String, completion: @escaping (Bool, String) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["ollama", "pull", modelName]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let status = process.terminationStatus
            
            if status == 0 {
                completion(true, "Model pulled successfully")
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                completion(false, "Failed to pull model: \(errorString)")
            }
        } catch {
            completion(false, "Error executing pull command: \(error.localizedDescription)")
        }
    }
}
