//
//  TwilioManager.swift
//  Quoted
//
//  Created by Cam Scoglio on 6/25/25.
//

import Foundation

class TwilioManager: ObservableObject {
    static let shared = TwilioManager()
    
    private let accountSID: String
    private let authToken: String
    private let serviceSID: String
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let accountSID = config["TWILIO_ACCOUNT_SID"] as? String,
              let authToken = config["TWILIO_AUTH_TOKEN"] as? String,
              let serviceSID = config["TWILIO_VERIFY_SERVICE_SID"] as? String else {
            fatalError("Could not load Twilio configuration from Config.plist")
        }
        
        self.accountSID = accountSID
        self.authToken = authToken
        self.serviceSID = serviceSID
    }
    
    // MARK: - Public Methods
    
    /// Send verification code to phone number
    func sendVerificationCode(to phoneNumber: String) async -> Bool {
        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/Verifications"
        let parameters = [
            "To": phoneNumber,
            "Channel": "sms"
        ]
        
        return await makeRequest(to: url, with: parameters, expectedStatusCode: 201)
    }
    
    /// Verify the code entered by user
    func verifyCode(_ code: String, for phoneNumber: String) async -> Bool {
        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/VerificationCheck"
        let parameters = [
            "To": phoneNumber,
            "Code": code
        ]
        
        let success = await makeRequest(to: url, with: parameters, expectedStatusCode: 200)
        
        // For verification check, we also need to parse the response for "approved" status
        if success {
            return await checkVerificationStatus(url: url, parameters: parameters)
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func makeRequest(to urlString: String, with parameters: [String: String], expectedStatusCode: Int) async -> Bool {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Basic Authentication
        let credentials = "\(accountSID):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 Twilio HTTP Status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📱 Twilio Response: \(responseString)")
                }
                
                return httpResponse.statusCode == expectedStatusCode
            }
            
            return false
        } catch {
            print("❌ Twilio Network Error: \(error)")
            return false
        }
    }
    
    private func checkVerificationStatus(url: String, parameters: [String: String]) async -> Bool {
        guard let requestUrl = URL(string: url) else { return false }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        
        // Basic Authentication
        let credentials = "\(accountSID):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                
                return status == "approved"
            }
            
            return false
        } catch {
            print("❌ Verification Status Check Error: \(error)")
            return false
        }
    }
}
