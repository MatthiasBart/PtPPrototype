//
//  TestInputs.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 28.04.25.
//

enum Scenario: String, CaseIterable, Identifiable {
    case innerCity = "Inner City"
    case underground = "Underground"
    case forest = "Forest"
    case field = "Field"
    
    var id: String {
        self.rawValue
    }
}

enum Distance: String, CaseIterable, Identifiable {
    case meter1 = "1"
    case meter10 = "10"
    case meter30 = "30"
    
    var id: String {
        self.rawValue
    }
}

enum PackageSize: String, CaseIterable, Identifiable {
    case size128 = "128"
    case size4096 = "4096"
    case size9216 = "9216"
    
    var id: String {
        self.rawValue
    }
}

enum PackageNumber: String, CaseIterable, Identifiable {
    case number100 = "100"
    case number1_000 = "1000"
    case number10_000 = "10000"
    
    var id: String {
        self.rawValue
    }
}
