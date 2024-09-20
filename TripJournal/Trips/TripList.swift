import SwiftUI
import SwiftData

struct TripList: View {
    @Binding var addAction: () -> Void
    
    @State private var isLoading = false
    @State private var error: Error?
//    @State private var tripFormMode: TripForm.Mode?
    @State private var isLogoutConfirmationDialogPresented = false
    
    @StateObject private var tripController: TripController
    
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var syncController: TJSyncController
    
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var trips: [Trip]
    
    @Query(filter: #Predicate<Trip> { $0.isSynced == false }, sort: \.startDate) var unsyncedTrips: [Trip]
    
    init(addAction: Binding<() -> Void>, tripController: TripController) {
        self._addAction = addAction
        self._tripController = StateObject(wrappedValue: tripController)
    }
    
    
//    private var allPersistedTrips: [Trip] {
//        let descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\Trip.name, order: .forward)])
//        
//        do {
//            let filteredTrips = try context.fetch(descriptor)
//            return filteredTrips
//        } catch {
//            return []
//        }
//    }
//    
//    private var uncyncedTrips: [Trip] {
//        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.isSynced == false },
//                                               sortBy: [SortDescriptor(\Trip.name, order: .forward)])
//        
//        do {
//            let filteredTrips = try context.fetch(descriptor)
//            return filteredTrips
//        } catch {
//            return []
//        }
//    }
//    
//    private var syncedTrips: [Trip] {
//        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> {$0.isSynced == true },
//                                               sortBy: [SortDescriptor(\Trip.name, order: .forward)])
//        
//        do {
//            let filteredTrips = try context.fetch(descriptor)
//            return filteredTrips
//        } catch {
//            return []
//        }
//    }
//    
//    func getTrips() -> [Trip] {
//        return allPersistedTrips
//    }
//    
//    func getUnsyncedTrips() -> [Trip] {
//        return unsyncedTrips
//    }
//    
//    func getSyncedTrips() -> [Trip] {
//        return syncedTrips
//    }
//    
    
    // MARK: - Body
    
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trips")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbar)
                .onAppear {
                    addAction = { tripController.tripFormMode = .add }
                }
                .navigationDestination(for: Trip.self) { trip in
                    TripDetails(trip: trip, addAction: $addAction) {
                        Task {
//                            await fetchTrips()
                        }
                    }
                }
                .sheet(item: $tripController.tripFormMode) { mode in
                    TripForm(mode: mode) {
                        Task {
                            await fetchTrips()
                        }
                    }
                }
                .confirmationDialog(
                    "Log out?",
                    isPresented: $isLogoutConfirmationDialogPresented,
                    titleVisibility: .visible,
                    actions: {
                        Button("Log out", role: .destructive) {
                            Task {
                                await journalManager.logOut()
                            }
                        }
                    },
                    message: {
                        Text("You will need to log in to access your account again.")
                    }
                )
                .loadingOverlay(isLoading)
        }
        .task {
            await fetchTrips()
        }
    }
    
    // MARK: - Views
    
    @ToolbarContentBuilder
    private func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Log out", systemImage: "power", role: .destructive) {
                isLogoutConfirmationDialogPresented = true
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let error {
            errorView(for: error)
        } else if tripController.trips.isEmpty && !isLoading {
            emptyView
        } else {
            listView
        }
    }
    
    private func errorView(for error: Error) -> some View {
        ContentUnavailableView(
            label: {
                Label("Error", systemImage: "exclamationmark.triangle.fill")
            },
            description: {
                Text(error.localizedDescription)
            },
            actions: {
                Button("Try Again") {
                    Task {
                        await fetchTrips()
                    }
                }
            }
        )
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("Nothing here yet!", systemImage: "face.dashed")
                    .labelStyle(.titleOnly)
            },
            description: {
                Text("Add a trip to start your trip journal.")
            }
        )
    }
    
    private var listView: some View {
        List {
            ForEach(tripController.trips) { trip in
                TripCell(
                    trip: trip,
                    edit: {
                        tripController.tripFormMode = .edit(trip)
//                        tripFormMode = .edit(trip)
                    },
                    delete: {
                        Task {
//                            a/*wait tripConjournalManager.deleteTrip(withId: trip.tripId!)*/
                        }
                    }
                )
            }
        }
        .refreshable {
            await fetchTrips()
        }
        
        
        
        
        //        .onReceive(journalManager.$isLoading) { loading in
        //            self.isLoading = loading
        //        }
        //        .onReceive(journalManager.$error) { error in
        //            self.error = error
        //        }
    }
    
    // MARK: - Networking
    
    @MainActor
    private func fetchTrips() async {
        isLoading = true
        error = nil
        
        do {
            tripController.fetchTrips()
            if tripController.trips.isEmpty {
                // If local trips are empty, fetch from server
                 await tripController.journalManager.fetchTripsFromServer()
                
            }
            
            // Sync unsynced trips to server
//            try await syncController.syncTrips()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func deleteTrip(withId id: Int) async {
        isLoading = true
        do {
            try await journalManager.deleteTrip(withId: id)
            await fetchTrips()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
