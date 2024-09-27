import SwiftUI
import SwiftData
import Combine

struct RootView: View {
    
    @State private var addAction: () -> Void = {}
    @State private var isAuthenticated = false  // Manually updating state based on publisher
    private let serviceLocator: ServiceLocator
    @EnvironmentObject var tripViewModel: TripViewModel
    @EnvironmentObject private var authenticationService: AuthenticationService
    
    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }
    
    var body: some View {
        content
            .onReceive(authenticationService.isAuthenticated.receive(on: DispatchQueue.main)) { isAuthenticated in
                self.isAuthenticated = isAuthenticated  // Manually updating isAuthenticated
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if isAuthenticated {
            TripList(addAction: $addAction)
                .contentMargins(.bottom, 100)
                .overlay(alignment: .bottom) {
                    AddButton(action: addAction)
                }
                .onAppear {
                    addAction = { tripViewModel.tripFormMode = .add }
//                    tripViewModel.loadTrips()
                }
        } else {
            AuthView()
        }
    }
}
