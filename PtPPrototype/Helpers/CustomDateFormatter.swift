//
//  CustomDateFormatter.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 18.02.25.
//

import Foundation

enum CustomDateFormatter {
    static let precise = {
        $0.dateFormat = "dd.MM HH:mm:ss.SSS"
        return $0
    }(DateFormatter())
}
