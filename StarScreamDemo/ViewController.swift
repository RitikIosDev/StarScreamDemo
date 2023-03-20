//
//  ViewController.swift
//  StarScreamDemo
//
//  Created by Ritik on 05/01/23.
//

import UIKit
import Starscream

class ViewController: UIViewController{

    var webSocket : WebSocket?
    var pseudocode: [String : Any]?
    private let USER_TOKEN = "Token"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func requestOtp() {
        
        guard let requestURL = URL(string: "https://api.example.com/api/auth/otp") else {
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(USER_TOKEN)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            else if let data = data {

                do{
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(response)")
                        
                    }
                    if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                        print(dictionary)
                        self.startSession(otp: dictionary["otp"])
                    }
                    
                } catch {
                    print(error)
                    return
                }
            }
        }
        task.resume()
        
    }
    
    private func startSession(otp: Any){
        guard let url = URL(string: "wss://notifications.example.com/subscribe") else { return }
        let request = URLRequest(url: url)
        webSocket = WebSocket(request: request)
        webSocket?.delegate = self
        webSocket?.connect()
        pseudocode = ["otp" : otp]
    }
    
    func sendMessage(){
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: pseudocode, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8), let webSocket = webSocket {
                let dictionaryString = String(describing: pseudocode)
                let message = "\(URLSessionWebSocketTask.Message.string(jsonString))"
                webSocket.write(string: jsonString, completion: nil)
            } else {
                print("Could not convert Dictionary to Data")

            }
            
        } catch {
            print(error)
            return
        }
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        requestOtp()
    }
    
}

extension ViewController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            case .connected(let headers):
//                isConnected = true
                sendMessage()
                print("websocket is connected: \(headers)")
            case .disconnected(let reason, let code):
//                isConnected = false
                print("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                print("Received text: \(string)")
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                print("ping")
                break
            case .pong(_):
                print("pong")
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
        case .cancelled: break
        case .error(let error):
                handleError(error)
        }
    }
    func websocketDidConnect(socket: WebSocketClient) {
        print(#function)
    }
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print(#function)
    }
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print(#function)
    }
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print(#function)
    }
    // custom
    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }
    
    
}

