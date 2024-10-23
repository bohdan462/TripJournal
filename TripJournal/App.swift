import SwiftUI
import SwiftData

@main
struct TripJournalApp: App {
     
    private let container: ModelContainer
    private let serviceLocator: ServiceLocator
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        print("-----------------Initializing the app----------------------")
        
        

        self.container = TripJournalContainer.create()
        self.serviceLocator = ServiceLocator(context: container.mainContext)
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(serviceLocator: serviceLocator)
                .environmentObject(serviceLocator.makeJournalAuthManager())
                .environmentObject(serviceLocator.getNetworkMonitor())
                .environmentObject(serviceLocator.getTripViewModel())
                .environmentObject(serviceLocator.getAuthService())
                .modelContainer(container)
        }
    }
}
