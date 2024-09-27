import SwiftUI
import SwiftData

struct TripList: View {
    
    @Binding var addAction: () -> Void
    @State private var isLoading = false
    @State private var error: Error?
    @State private var isLogoutConfirmationDialogPresented = false
    
    @EnvironmentObject var journalAuthManager: JournalAuthManager
    
    @Environment(\.scenePhase) private var scenePhase
    
    @EnvironmentObject var viewModel: TripViewModel
    
    init(addAction: Binding<() -> Void>) {
        self._addAction = addAction
    }
    
    // MARK: - Body
    
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trips")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbar)
                .onAppear {
                    addAction = { viewModel.tripFormMode = .add }
                }
                .navigationDestination(for: Trip.self) { trip in
                    TripDetails(
                        viewModel: viewModel,
                        tripId: trip.id,
                        addAction: $addAction
                    ) {
                        Task {
                            viewModel.loadTrips
                        }
                    }
                }
                .sheet(item: $viewModel.tripFormMode) { mode in
                    TripForm(mode: mode) {
                        Task {
                            print("Called to Show tripformmode")
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
                                await journalAuthManager.logOut()
                            }
                        }
                    },
                    message: {
                        Text("You will need to log in to access your account again.")
                    }
                )
                .loadingOverlay(viewModel.isLoading)
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
        } else if viewModel.trips.isEmpty && !viewModel.isLoading {
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
            ForEach(viewModel.trips) { trip in
                TripCell(
                    trip: trip,
                    edit: {
                        viewModel.tripFormMode = .edit(trip)
                    },
                    delete: {
                        Task {
                            await deleteTrip(trip.id)
                        }
                    }
                )
            }
        }
        .refreshable {
            viewModel.deleteAll()
        }
    }
    
    // MARK: - Networking
    
  
    private func fetchTrips() async {
        error = nil
        print("------UI-----Fetching Trips that was requested by UI")
        await viewModel.loadTrips()
    }
    
    private func deleteTrip(_ tripId: Trip.ID) async {
        viewModel.deleteTrip(tripId)
    }
}
