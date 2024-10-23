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
    let mode: Mode
    let trip: Trip
//    private let updateHandler: () -> Void
    
    
    private let title: String
    
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var location: Location?
    @State private var transitionFromPrevious: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var isLocationPickerPresented = false
    
    @ObservedObject var viewModel: EventViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initializer
    
    init(
        mode: Mode,
        viewModel: EventViewModel,
        trip: Trip
//        updateHandler: @escaping () -> Void
    ) {
        self.mode = mode
        self.viewModel = viewModel
        self.trip = trip
//        self.updateHandler = updateHandler
        
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
           
            print("\nEVENT_FFORM_EVENT EDIT MODE--------------------------\n")
            print("Event: \(event.name), date: \(event.date), note: \(event.note), lat: \(event.location?.latitude), long: \(event.location?.longitude), address: \(event.location?.address), transition: \(event.transitionFromPrevious) tripID: \(event.tripID), tripName: \(event.trip?.name), eventIDremote:\(event.eventId), localID:\(event.id), synced: \(event.isSynced)")
           
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
                        print("\nPASSING_LOCATION_TO_PICKER: \nlong: \(location?.longitude)\n lat: \(location?.latitude)\n")
                        print("\nSELECTED_LOCATION: \nlong: \(selectedLocation.longitude)\n lat: \(selectedLocation.latitude)\n")
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
//             let trip = $viewModel.trip
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
               
                await viewModel.addEvent(newEvent)
                print("\nEVENT_FORM-----UI:--------------NEW EVENT-------\n")
                print("Event: \(newEvent.name), date: \(newEvent.date), note: \(newEvent.note), lat: \(newEvent.location?.latitude), long: \(newEvent.location?.longitude), address: \(newEvent.location?.address), tripID: \(newEvent.tripID), tripName: \(newEvent.trip?.name), eventIDremote:\(newEvent.eventId), localID:\(newEvent.id), synced: \(newEvent.isSynced)")
                
            case let .edit(event):
                var updatedEvent = event
                updatedEvent.name = name
                updatedEvent.note = note.isEmpty ? nil : note
                updatedEvent.date = date
                updatedEvent.location = location
                updatedEvent.transitionFromPrevious = transitionFromPrevious.isEmpty ? nil : transitionFromPrevious
                await viewModel.updateEvent(updatedEvent)
            }
            
            // Use MainActor to ensure the dismissal happens on the main thread
            await MainActor.run {
                dismiss()
            }
            
            print("\n -----VIEW----- EDIT MODE---- Event Saved: \(name), \(date), belongs to trip: \(trip.tripId), trip:\(trip)\n long: \(location?.longitude) lat: \(location?.latitude)\n")
            
        } catch {
            // Update the error on the main thread
            await MainActor.run {
                self.error = error
            }
        }
    }

    
    private func deleteEvent() async {
        do {
            if case let .edit(event) = mode {
                await viewModel.deleteEvent(event)
                dismiss()
            }
        } catch {
            self.error = error
        }
    }
}
