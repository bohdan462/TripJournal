//
//  MediaViewModel.swift
//  TripJournal
//
//  Created by Bohdan Tkachenko on 10/20/24.
//

import Foundation
import SwiftUI

class MediaViewModel: ObservableObject {
    @Published var media: Media?
    var event: Event?
    
    
    private let createMediaUseCase: CreateMediaUseCase
    private let deleteMediaUseCase: DeleteMediaUseCase
    
    init(media: Media? = nil, event: Event? = nil, createMediaUseCase: CreateMediaUseCase, deleteMediaUseCase: DeleteMediaUseCase) {
        self.media = media
        self.event = event
        self.createMediaUseCase = createMediaUseCase
        self.deleteMediaUseCase = deleteMediaUseCase
    }
    
    
    func createMedia(with data: Data, caption: String) async {
        guard self.event != nil else { return }
        do {
            try await createMediaUseCase.execute(with: data, caption: caption, event: event!)
        } catch {
            
        }
    }
    
    func deleteMedia(_ media: Media) async {
        do {
           try await deleteMediaUseCase.execute(media: media)
        } catch {
            
        }
       
    }
    
}
