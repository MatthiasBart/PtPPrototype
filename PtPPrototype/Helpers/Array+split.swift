//
//  Array+split.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 22.12.24.
//

import Foundation

extension Array {
    func split(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}
