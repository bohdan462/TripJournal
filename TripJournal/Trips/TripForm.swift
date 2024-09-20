import SwiftUI
import SwiftData

struct TripForm: View {
    
    @Environment(\.modelContext) private var context
    
    /// Determines if the form is being used to add a new trip or edit an existing one.
    enum Mode: Hashable, Identifiable {
        case add
        case edit(Trip)

        var id: String {
            switch self {
            case .add:
                return "TripForm.add"
            case let .edit(trip):
                return "TripForm.edit: \(trip.id)"
            }
        }
    }

    /// Describes validation errors that might occur locally in the form.
    struct ValidationError: LocalizedError {
        var errorDescription: String?

        static let emptyName = Self(errorDescription: "Please enter a name.")
        static let invalidDates = Self(errorDescription: "Start date should be before end date.")
    }

    init(mode: Mode, updateHandler: @escaping () -> Void) {
        self.mode = mode
        self.updateHandler = updateHandler

        switch mode {
        case .add:
            title = "Add Trip"

        case let .edit(trip):
            title = "Edit \(trip.name)"
            _name = .init(initialValue: trip.name)
            _startDate = .init(initialValue: trip.startDate)
            _endDate = .init(initialValue: trip.endDate)
        }
    }

    private let mode: Mode
    private let updateHandler: () -> Void
    private let title: String

    @State private var name: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = .now
    @State private var isLoading = false
    @State private var error: Error?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journalManager: JournalManager

    // MARK: - Body

    var body: some View {
        NavigationView {
            form
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbar)
                .overlay(alignment: .bottom, content: deleteButton)
                .alert(error: $error)
                .loadingOverlay(isLoading)
        }
    }

    // MARK: - Views

    private var form: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name, prompt: Text("Amsterdam Adventure"))
            }
            Section("Dates") {
                DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                DatePicker("End date", selection: $endDate, displayedComponents: .date)
            }
        }
    }

    @ViewBuilder
    private func deleteButton() -> some View {
        if case let .edit(trip) = mode {
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

                Button("Delete Trip", systemImage: "trash", role: .destructive) {
                    Task {
                        await deleteTrip(withId: trip.tripId!)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Dismiss", systemImage: "xmark") {
                dismiss()
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Button("Save") {
                switch mode {
                case .add:
                    Task {
                        await addTrip()
                    }
                case let .edit(trip):
                    Task {
                        await editTrip(withId: trip.tripId!)
                    }
                }
            }
        }
    }

    // MARK: - Networking

    private func validateForm() throws {
        if name.nonEmpty == nil {
            throw ValidationError.emptyName
        }
        if startDate > endDate {
            throw ValidationError.invalidDates
        }
    }

    private func addTrip() async {
        isLoading = true
        do {
            try validateForm()
            let request = TripCreate(name: name, startDate: startDate, endDate: endDate)
           let trip = await journalManager.createTrip(from: request)
            
            
//            do {
//                context.insert(trip)
//                try context.save()
//            } catch {
//                print("Error creating trip: \(error.localizedDescription)")
//                
//            }
//            
            
            await MainActor.run {
                
                updateHandler()
                dismiss()
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func editTrip(withId id: Int) async {
        isLoading = true
        do {
            // Validate form inputs
            try validateForm()

            // Create the update request object
            let request = TripUpdate(name: name, startDate: startDate, endDate: endDate)
            
            // Fetch the trip from the context
            let fetchDescriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.tripId == id })
            
            if let tripToEdit = try context.fetch(fetchDescriptor).first {
                // Update the trip's properties with new values
                tripToEdit.name = request.name
                tripToEdit.startDate = request.startDate
                tripToEdit.endDate = request.endDate
                tripToEdit.isSynced = false  // Set to false, since it's now modified and unsynced

                // Save the context to persist changes
                try context.save()

                // Notify and dismiss
                await MainActor.run {
                    updateHandler()
                    dismiss()
                }
            } else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }


    private func deleteTrip(withId id: Int) async {
        isLoading = true
        let fetchDescriptor = FetchDescriptor<Trip>(predicate: #Predicate<Trip> { $0.tripId == id })
        if let tripToDelete = (try? context.fetch(fetchDescriptor).first) {
             context.delete(tripToDelete)
             try? context.save()
        }
            await journalManager.deleteTrip(withId: id)
            await MainActor.run {
                updateHandler()
                dismiss()
            }
        isLoading = false
    }
}
