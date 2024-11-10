# TripJournal

TripJournal is a robust, highly structured iOS app designed to manage trips, events, media, and locations. The app emphasizes scalable architecture, effective data synchronization between local and remote sources, and efficient persistence handling using SwiftData. This project demonstrates a structured approach to iOS development, focusing on modularity, dependency injection, and clean design principles.

## Motivation

The goal behind TripJournal is to create an app with strong architectural principles that not only performs well but also scales gracefully. This project serves as a practical example for developers interested in building complex, networked apps that handle data synchronization between offline (local) and online (remote) storage. 

TripJournal can be used as a reference for:
- Implementing clean architecture patterns in iOS development.
- Managing complex relationships (e.g., Trip -> Events -> Media/Location).
- Creating modular, testable codebases that are easy to extend and maintain.
- Handling persistent storage with SwiftData, while syncing with a remote server using RESTful APIs.

## Features

### Core Functionalities

- **Trip and Event Management**: Easily create, update, and delete trips and their associated events, including handling for offline support and synchronization with remote storage.
- **Data Synchronization**: Smart data syncing between local storage (SwiftData) and a remote server ensures that data consistency is maintained across sessions.
- **Location and Media Integration**: Associate events with geographic locations and media files, providing a rich experience that integrates well with real-world use cases.
- **Offline Capability**: Users can create or update trips and events offline, which then sync when the device reconnects to the network.

### Key Architectural Components

#### 1. Clean Architecture
The project is built with clean architecture principles:
- **Use Cases**: Each action (e.g., creating an event) is encapsulated in its own use case, promoting separation of concerns.
- **Repositories**: Data sources (local and remote) are abstracted via repository interfaces, allowing for flexibility in the data source without changing the app’s business logic.
- **Dependency Injection**: Dependencies are injected into classes, which makes the code more modular, testable, and reusable.

#### 2. Data Persistence with SwiftData
SwiftData is used for local persistence, with entities like `Trip`, `Event`, `Media`, and `Location` managed as SwiftData models. This setup supports the offline-first experience by maintaining a local copy of all data, which can later be synced with the server.

#### 3. Remote Data Management with Repositories
Each core entity (Trip, Event, Media, and Location) has both a local and remote repository:
- **EventRepository**: Manages creation, retrieval, updating, and deletion of events, interfacing with `EventRemoteDataSource` and `EventLocalDataSource`.
- **TripRepository**: Handles trip data management, including saving events as children of trips, enforcing the parent-child relationship.
- **Media and Location Management**: Media and Location entities are handled separately to ensure modularity and independent syncing. Each media item or location update syncs with the remote server as needed.

### Handling Parent-Child Relationships

- Events are always managed as children of trips to ensure data consistency. For instance, when an event is created or updated, the app saves the entire trip entity, making sure that the event data is correctly persisted.
- This structure allows easier persistence management, as changes to child entities (events) are automatically reflected when saving the parent (trip).

### Syncing Logic and Offline Handling

- **Network Monitoring**: A `NetworkMonitor` checks connectivity status, and the app only attempts remote sync operations when connected.
- **Conditional Syncing**: The app selectively syncs only unsynced entities to reduce server load and improve app performance.
- **Error Handling and Fallbacks**: When offline, modifications to data (e.g., creating or updating events) are saved locally with a flag indicating they need to be synced, ensuring data integrity across sessions.
