//
//  TripModelView.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 9/16/24.
//

import Foundation
import UIKit
import SwiftData
import SwiftUI


class JournalAuthManager: ObservableObject {
    
    let authService: AuthService
    init(authService: AuthService) {
        self.authService = authService
    }
    
    
    func register(username: String, password: String) async {
        do {
            let token = try await authService.register(username: username, password: password)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func logIn(username: String, password: String) async {
        
        do {
            let token = try await authService.logIn(username: username, password: password)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func logOut() async {
        await authService.logOut()
    }
}
