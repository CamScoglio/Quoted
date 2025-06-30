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
        print("📱 [TwilioManager] Initializing TwilioManager...")
        
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            print("📱 ❌ [TwilioManager] Could not find Config.plist file")
            fatalError("Could not load Twilio configuration from Config.plist")
        }
        
        guard let config = NSDictionary(contentsOfFile: path) else {
            print("📱 ❌ [TwilioManager] Could not load Config.plist")
            fatalError("Could not load Twilio configuration from Config.plist")
        }
        
        guard let accountSID = config["TWILIO_ACCOUNT_SID"] as? String,
              let authToken = config["TWILIO_AUTH_TOKEN"] as? String,
              let serviceSID = config["TWILIO_VERIFY_SERVICE_SID"] as? String else {
            print("📱 ❌ [TwilioManager] Could not load Twilio configuration from Config.plist")
            print("📱 [TwilioManager] Available keys in config: \(config.allKeys)")
            fatalError("Could not load Twilio configuration from Config.plist")
        }
        
        self.accountSID = accountSID
        self.authToken = authToken
        self.serviceSID = serviceSID
        
        print("📱 ✅ [TwilioManager] TwilioManager initialized successfully")
        print("📱 [TwilioManager] Account SID: \(accountSID)")
        print("📱 [TwilioManager] Service SID: \(serviceSID)")
        print("📱 [TwilioManager] Auth Token: [REDACTED]")
    }
    
    // MARK: - Public Methods
    
    /// Send verification code to phone number
    func sendVerificationCode(to phoneNumber: String) async -> Bool {
        print("📱 [TwilioManager] sendVerificationCode called for: \(phoneNumber)")
        
        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/Verifications"
        let parameters = [
            "To": phoneNumber,
            "Channel": "sms"
        ]
        
        print("📱 [TwilioManager] Making verification request to: \(url)")
        print("📱 [TwilioManager] Parameters: \(parameters)")
        
        let result = await makeRequest(to: url, with: parameters, expectedStatusCode: 201, parseJsonForApproval: false)
        print("📱 [TwilioManager] sendVerificationCode result: \(result)")
        return result
    }
    
    /// Verify the code entered by user
    func verifyCode(_ code: String, for phoneNumber: String) async -> Bool {
        NSLog("📱 [TwilioManager] verifyCode called")
        NSLog("📱 [TwilioManager] Phone: \(phoneNumber)")
        NSLog("📱 [TwilioManager] Code: \(code)")
        
        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/VerificationCheck"
        let parameters = [
            "To": phoneNumber,
            "Code": code
        ]
        
        NSLog("📱 [TwilioManager] Making verification check request to: \(url)")
        NSLog("📱 [TwilioManager] Parameters: \(parameters)")
        
        // Make the verification request and parse JSON for "approved" status
        let result = await makeRequest(to: url, with: parameters, expectedStatusCode: 200, parseJsonForApproval: true)
        NSLog("📱 [TwilioManager] Final verification result: \(result)")
        return result
    }
    
    // MARK: - Private Methods
    

    private func makeRequest(to urlString: String, with parameters: [String: String], expectedStatusCode: Int, parseJsonForApproval: Bool = false) async -> Bool {
        NSLog("📱 [TwilioManager] makeRequest called")
        NSLog("📱 [TwilioManager] URL: \(urlString)")
        NSLog("📱 [TwilioManager] Expected status code: \(expectedStatusCode)")
        NSLog("📱 [TwilioManager] Parse JSON for approval: \(parseJsonForApproval)")
        
        guard let url = URL(string: urlString) else {
            NSLog("📱 ❌ [TwilioManager] Invalid URL: \(urlString)")
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
        
        // Request body - URL encode the parameters properly (same approach as EnterPhoneView)
        let bodyString = parameters.compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            // Manually encode + as %2B for phone numbers (don't double-encode)
            let encodedValue = value.replacingOccurrences(of: "+", with: "%2B")
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        NSLog("📱 [TwilioManager] Request body: \(bodyString)")
        NSLog("📱 [TwilioManager] Making HTTP request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("📱 [TwilioManager] HTTP Status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    NSLog("📱 [TwilioManager] Response: \(responseString)")
                }
                
                // Check if we got the expected status code
                if httpResponse.statusCode == expectedStatusCode {
                    // If we need to parse JSON for approval status
                    if parseJsonForApproval {
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            NSLog("📱 [TwilioManager] Parsed JSON: \(json)")
                            
                            if let status = json["status"] as? String {
                                NSLog("📱 [TwilioManager] Verification status: \(status)")
                                let approved = status == "approved"
                                NSLog("📱 [TwilioManager] Is approved: \(approved)")
                                return approved
                            } else {
                                NSLog("📱 ❌ [TwilioManager] No status field in response")
                                return false
                            }
                        } else {
                            NSLog("📱 ❌ [TwilioManager] Failed to parse JSON response")
                            return false
                        }
                    } else {
                        // Just return success based on status code
                        NSLog("📱 [TwilioManager] Request successful!")
                        return true
                    }
                } else {
                    NSLog("📱 ❌ [TwilioManager] HTTP error: \(httpResponse.statusCode)")
                    return false
                }
            }
            
            NSLog("📱 ❌ [TwilioManager] No HTTP response received")
            return false
        } catch {
            NSLog("📱 ❌ [TwilioManager] Network Error: \(error)")
            NSLog("📱 ❌ [TwilioManager] Error details: \(error.localizedDescription)")
            return false
        }
    }
    

}
