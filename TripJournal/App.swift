import SwiftUI
import SwiftData

@main
struct TripJournalApp: App {
    
    // Declare @StateObject properties without initializing them here
    @StateObject private var tripController: TripController
    @StateObject private var syncController: TJSyncController
    
    // Declare other dependencies as constants
    private let container: ModelContainer
    private let serviceFactory: ServiceFactory
    private let networkMonitor: NetworkMonitor
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize ModelContainer
        self.container = TripJournalContainer.create()
        
        // Initialize ServiceFactory with the container's main context
        self.serviceFactory = ServiceFactory(context: container.mainContext)
        
        // Create JournalManager before initializing SyncController
        let journalManager = serviceFactory.makeJournalManager()
        
        // Initialize SyncManager
        let syncManager = SyncManager()
        
        // Initialize SyncController as a local instance
        let syncControllerInstance = TJSyncController(
            journalManager: journalManager,
            syncManager: syncManager
        )
        // Assign to the @StateObject wrapper
        self._syncController = StateObject(wrappedValue: syncControllerInstance)
        
        // Initialize NetworkMonitor as a constant (not @StateObject)
        self.networkMonitor = NetworkMonitor.shared
        
        // Initialize TripController with the dependencies
        let tripControllerInstance = TripController(
            context: container.mainContext,
            journalManager: journalManager,
            syncController: syncControllerInstance,
            networkMonitor: networkMonitor
        )
        // Assign to the @StateObject wrapper
        self._tripController = StateObject(wrappedValue: tripControllerInstance)
        
        
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(serviceFactory.makeJournalManager())
                .environmentObject(syncController)
                .environmentObject(networkMonitor)
                .environmentObject(tripController)
                .modelContainer(container)
        }
    }
}
