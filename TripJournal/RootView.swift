import SwiftUI
import SwiftData

struct RootView: View {
    
    @State private var addAction: () -> Void = {}
    @State private var isAuthenticated = false
    
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var tripController: TripController
    
    
    var body: some View {
        content
        //            .environment(\.journalManager, service)
            .onReceive(journalManager.journalFacade.authService.isAuthenticated.receive(on: DispatchQueue.main)) { isAuthenticated in
                self.isAuthenticated = isAuthenticated
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if isAuthenticated {
            TripList(addAction: $addAction, tripController: tripController)
                .contentMargins(.bottom, 100)
                .overlay(alignment: .bottom) {
                    AddButton(action: addAction)
                }
                .onAppear {
                    //TODO: - Fetch or prefetch Trips
                }
        } else {
            AuthView()
        }
    }
}
