//
//  TestResultRepresentable.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 27.04.25.
//

protocol TestResultRepresentable: CustomStringConvertible {
    func toCSV(in scenario: String, with distance: String, using transportProtocol: String) -> String
}

struct EmptyTestResultRepresentable: TestResultRepresentable {
    var description: String { "empty" }
    
    func toCSV(in scenario: String, with distance: String, using transportProtocol: String) -> String {
        "empty"
    }
}

extension TestResultRepresentable where Self == EmptyTestResultRepresentable {
    static var empty: Self {
        EmptyTestResultRepresentable()
    }
}
