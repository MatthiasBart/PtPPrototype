//
//  ConnectionImpl+TestError.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 22.12.24.
//

import Foundation

extension ConnectionImpl {
    enum TestError: Error {
        case streamWriteError
    }
}
