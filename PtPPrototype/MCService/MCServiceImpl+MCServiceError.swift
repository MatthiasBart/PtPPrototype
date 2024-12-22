//
//  MCServiceImpl+MCServiceError.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 22.12.24.
//

import Foundation

extension MCServiceImpl {
    enum MCServiceError: Error {
        case streamWriteError
    }
}
