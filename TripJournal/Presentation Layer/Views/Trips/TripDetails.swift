import MapKit
import SwiftUI

struct TripDetails: View {
    let tripId: Trip.ID
    @Binding var addAction: () -> Void
    private let deletionHandler: () -> Void

    @State private var eventFormMode: EventForm.Mode?
    @State private var isDeleteConfirmationPresented = false
    @State private var isLoading = false
    @State private var error: Error?
    let serviceLocator: ServiceLocator
    @ObservedObject var viewModel: TripViewModel
    
    @StateObject private var mediaViewModel: MediaViewModel
    @StateObject private var eventViewModel: EventViewModel
    
    
    
    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: TripViewModel,
        tripId: Trip.ID,
        serviceLocator: ServiceLocator,
        addAction: Binding<() -> Void>,
        deletionHandler: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.tripId = tripId
        self.serviceLocator = serviceLocator
        self._addAction = addAction
        self.deletionHandler = deletionHandler
        
        _eventViewModel = StateObject(wrappedValue: serviceLocator.getEventViewModel())
        _mediaViewModel = StateObject(wrappedValue: serviceLocator.getMediaViewModel())
    }

    var body: some View {
        contentView
            .onAppear {
                addAction = { eventFormMode = .add }
                Task {
                    await viewModel.getTrip(by: tripId)
                }
            }
            .navigationTitle(viewModel.currentTrip?.name ?? "Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbar)
            .sheet(item: $eventFormMode) { mode in
                EventForm(mode: mode, viewModel: eventViewModel, trip: viewModel.currentTrip!)
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
        if let trip = viewModel.currentTrip {
            
            if trip.events.isEmpty {
                emptyView
            } else {
                eventsView(trip: trip)
            }
        } else {
            Text("Loading Trip...")
        }
    }

    private func eventsView(trip: Trip) -> some View {
        ScrollView(.vertical) {
            ForEach(trip.events) { event in
                EventCell(
                    event: event,
                    edit: { eventFormMode = .edit(event) },
                    mediaUploadHandler: { data in
                        Task {
                            mediaViewModel.event = event
                            await addMedia(withData: data, caption: "")
                        }
                    },
                    mediaDeletionHandler: { media in
                        Task {
                            mediaViewModel.event = event
                            await deleteMedia(media)
                        }
                    }
                )
            }
        }
        .refreshable {
            await viewModel.getTrip(by: tripId)
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

    // MARK: - Actions

    private func deleteTrip() async {
        isLoading = true
         viewModel.deleteTrip(tripId)
        await MainActor.run {
            isLoading = false
            dismiss()
        }
    }
    
    private func addMedia(withData data: Data, caption: String) async {
       
        await mediaViewModel.createMedia(with: data, caption: caption)
    }
    
    private func deleteMedia(_ media: Media) async {
        await mediaViewModel.deleteMedia(media)
    }
}
