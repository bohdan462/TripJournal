import MapKit
import SwiftUI

struct TripDetails: View {
    init(
        trip: Trip,
        addAction: Binding<() -> Void>,
        deletionHandler: @escaping () -> Void
    ) {
        _trip = .init(initialValue: trip)
        _addAction = addAction
        self.deletionHandler = deletionHandler
    }
    
    private let deletionHandler: () -> Void
    
    @Binding private var addAction: () -> Void
    
    @State private var trip: Trip
    @State private var eventFormMode: EventForm.Mode?
    @State private var isDeleteConfirmationPresented = false
    @State private var isLoading = false
    @State private var error: Error?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journalManager: JournalManager 
    
    var body: some View {
        contentView
            .onAppear {
                addAction = { eventFormMode = .add }
                Task {
                    await reloadTrip()
                }
            }
            .navigationTitle(trip.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbar)
            .sheet(item: $eventFormMode) { mode in
                EventForm(tripId: trip.tripId!, mode: mode) {
                    Task {
                        await reloadTrip()
                    }
                }
            }
            .confirmationDialog("Delete Trip?", isPresented: $isDeleteConfirmationPresented) {
                Button("Delete Trip", role: .destructive) {
                    Task {
                        await deleteTrip()
                    }
                }
            }
            .loadingOverlay(isLoading)
    }
    
    @ToolbarContentBuilder
    private func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Delete Trip", systemImage: "trash", role: .destructive) {
                isDeleteConfirmationPresented = true
            }
            .tint(.red)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if trip.events.isEmpty {
            emptyView
        } else {
            eventsView
        }
    }
    
    private var eventsView: some View {
        ScrollView(.vertical) {
            ForEach(journalManager.events) { event in
                EventCell(
                    event: event,
                    edit: { eventFormMode = .edit(event) },
                    mediaUploadHandler: { data in
                        Task {
//                            await uploadMedia(eventId: event.id, data: data)
                        }
                    },
                    mediaDeletionHandler: { mediaId in
                        Task {
                            await deleteMedia(withId: mediaId)
                        }
                    }
                )
            }
        }
        .refreshable {
            await reloadTrip()
        }
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("Nothing here yet!", systemImage: "face.dashed")
                    .labelStyle(.titleOnly)
            },
            description: {
                Text("Add an event to start your trip journal.")
            }
        )
    }
    
    // MARK: - Networking
    
    private func uploadMedia(eventId: Int, data: Data) async {
        
        isLoading = true
    
        //create Media
        await journalManager.createMedia(with: data, eventId: eventId)
        
        isLoading = false
    }
    
    private func deleteMedia(withId mediaId: Int) async {
        isLoading = true
        
        await journalManager.deleteMedia(withId: mediaId)
        await reloadTrip()
        
        isLoading = false
    }
    
    private func reloadTrip() async {
        let id = trip.tripId!
        let updatedTrip =  await journalManager.getTrip(withId: id)
        trip = updatedTrip
    }
    
    private func deleteTrip() async {
        isLoading = true
        
        await journalManager.deleteTrip(withId: trip.tripId!)
        await MainActor.run {
            deletionHandler()
            dismiss()
        }
        isLoading = false
    }
}
