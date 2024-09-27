import SwiftUI
import MapKit

struct EventForm: View {
    enum Mode: Hashable, Identifiable {
        case add
        case edit(Event)
        
        var id: String {
            switch self {
            case .add:
                return "add"
            case let .edit(event):
                return "edit: \(event.id)"
            }
        }
    }
    
    struct FormError: LocalizedError {
        var errorDescription: String?
        
        static let emptyName = Self(errorDescription: "Please enter a name.")
    }
    
    // MARK: - Properties
    
    let tripId: Trip.ID
    let mode: Mode
    @ObservedObject var viewModel: TripViewModel
    private let title: String
    
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var location: Location?
    @State private var transitionFromPrevious: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var isLocationPickerPresented = false
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initializer
    
    init(
        tripId: Trip.ID,
        mode: Mode,
        viewModel: TripViewModel
    ) {
        self.tripId = tripId
        self.mode = mode
        self.viewModel = viewModel
        
        switch mode {
        case .add:
            title = "Add Event"
        case let .edit(event):
            title = "Edit \(event.name)"
            _name = .init(initialValue: event.name)
            _note = .init(initialValue: event.note ?? "")
            _date = .init(initialValue: event.date)
            _location = .init(initialValue: event.location)
            _transitionFromPrevious = .init(initialValue: event.transitionFromPrevious ?? "")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbar)
                .overlay(alignment: .bottom, content: deleteButton)
                .alert(isPresented: Binding<Bool>(
                    get: { self.error != nil },
                    set: { _ in self.error = nil }
                )) {
                    Alert(
                        title: Text("Error"),
                        message: Text(error?.localizedDescription ?? "Unknown error"),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .loadingOverlay(isLoading)
                .sheet(isPresented: $isLocationPickerPresented) {
                    LocationPicker(location: location) { selectedLocation in
                        location = selectedLocation
                    }
                }
                .interactiveDismissDisabled()
        }
    }
    
    // MARK: - Views
    
    private var form: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name, prompt: Text("Visit to the Van Gogh Museum"))
            }
            Section("Note") {
                TextField(
                    "Note",
                    text: $note,
                    prompt: Text("A vivid, unforgettable art experience..."),
                    axis: .vertical
                )
                .lineLimit(3 ... 5)
            }
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            Section("Travel Method") {
                TextField("Travel Method", text: $transitionFromPrevious, prompt: Text("Tram ride from hotel"))
            }
            locationSection
        }
    }
    
    @ToolbarContentBuilder
    func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Dismiss", systemImage: "xmark") {
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Save") {
                Task {
                    await saveEvent()
                }
            }
        }
    }
    
    private var locationSection: some View {
        Section {
            if let location {
                Button(
                    action: { isLocationPickerPresented = true },
                    label: {
                        map(location: location)
                    }
                )
                .buttonStyle(.plain)
                .containerRelativeFrame(.horizontal)
                .clipped()
                .listRowInsets(EdgeInsets())
                .frame(height: 150)
                
                removeLocation
            } else {
                addLocation
            }
        }
    }
    
    @ViewBuilder
    private func map(location: Location) -> some View {
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        Map(coordinateRegion: .constant(region), annotationItems: [location]) { location in
            MapMarker(coordinate: location.coordinate)
        }
    }
    
    private var addLocation: some View {
        Button(
            action: {
                isLocationPickerPresented = true
            },
            label: {
                Text("Add Location")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }
    
    private var removeLocation: some View {
        Button(
            role: .destructive,
            action: {
                location = nil
            },
            label: {
                Text("Remove Location")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        )
    }
    
    @ViewBuilder
    private func deleteButton() -> some View {
        if case .edit(_) = mode {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        Color(uiColor: .systemBackground),
                        Color.clear,
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea()
                .frame(height: 100)
                
                Button("Delete Event", systemImage: "trash", role: .destructive) {
                    Task {
                        await deleteEvent()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func validateForm() throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FormError.emptyName
        }
    }
    
    private func saveEvent() async {
        do {
            try validateForm()
            guard let trip = viewModel.trip(withId: tripId) else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Trip not found."])
            }

            switch mode {
            case .add:
                let newEvent = Event(
                    name: name,
                    note: note.isEmpty ? nil : note,
                    date: date,
                    location: location,
                    trip: trip,
                    tripID: trip.tripId,
                    medias: [],
                    transitionFromPrevious: transitionFromPrevious.isEmpty ? nil : transitionFromPrevious,
                    isSynced: false
                )
               
                await viewModel.addEvent(newEvent, fromTrip: trip)
                
            case let .edit(event):
                var updatedEvent = event
                updatedEvent.name = name
                updatedEvent.note = note.isEmpty ? nil : note
                updatedEvent.date = date
                updatedEvent.location = location
                updatedEvent.transitionFromPrevious = transitionFromPrevious.isEmpty ? nil : transitionFromPrevious
                await viewModel.updateEvent(updatedEvent, inTrip: trip)
            }
            
            // Use MainActor to ensure the dismissal happens on the main thread
            await MainActor.run {
                dismiss()
            }
            
        } catch {
            // Update the error on the main thread
            await MainActor.run {
                self.error = error
            }
        }
    }

    
    private func deleteEvent() async {
        do {
            guard let trip = viewModel.trip(withId: tripId) else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Trip not found."])
            }
            if case let .edit(event) = mode {
                await viewModel.deleteEvent(withId: event.id, fromTrip: trip)
                dismiss()
            }
        } catch {
            self.error = error
        }
    }
}
