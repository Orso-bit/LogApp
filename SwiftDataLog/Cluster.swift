//
//  Cluster.swift
//  SwiftDataLog
//
//  Created by Vincenzo Salzano on 22/05/25.
//

import Foundation
import SwiftData

@Model
final class Cluster {
    var name: String
    var createdAt: Date
    
    // Relazione uno-a-molti con gli alberi
    @Relationship(deleteRule: .cascade, inverse: \Tree.cluster)
    var trees: [Tree] = []
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
