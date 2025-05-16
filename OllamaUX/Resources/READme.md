**OllamaUI for MacOS**
A simple macOS application built with SwiftUI that provides a graphical user interface for interacting with Ollama models installed on your Mac. *NOT IN ANY WAY ASSOCIATED WITH OLLAMA*

**Features**
- Start and stop the Ollama server from within the app
- Select from your installed Ollama models
- Send prompts and view responses in a chat-like interface
- Real-time status monitoring of the Ollama server

**Prerequisites**
macOS 14 or later (Ventura+)
Xcode 14 or later
Ollama installed on your Mac with a Llama model

**Setup Instructions for Ollama**
Install Ollama:
'brew install ollama'

Download and pull a model:
'ollama pull llama3.2'

**Usage**
When you start the app, it will automatically try to start the Ollama server if it's installed. Once Ollama is running, the app will fetch available models. Enter your prompt in the text field at the bottom. Press the send button to submit your prompt to the model. The response will appear in the conversation view.

**Troubleshooting/Notes**
- Make sure Ollama is properly installed and can be run from Terminal
- Check if the model you're trying to use is downloaded (use 'ollama list' in Terminal)
- Restart the Ollama service from Terminal if needed: 'pkill ollama' && 'ollama serve'
- The app communicates with Ollama through its local API, which runs on port 11434 by default
- Check the console in Xcode for error messages
