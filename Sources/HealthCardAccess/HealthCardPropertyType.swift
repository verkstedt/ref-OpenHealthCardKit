//
//  Copyright (c) 2023 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Enum for various HealthCard types
public enum HealthCardPropertyType {
    /// eGK card with generation
    case egk(generation: CardGeneration)
    /// HBA card with generation
    case hba(generation: CardGeneration)
    /// SMC-B card with generation
    case smcb(generation: CardGeneration)

    /// The card generation for the card type
    public var generation: CardGeneration {
        switch self {
        case let .egk(generation): return generation
        case let .hba(generation): return generation
        case let .smcb(generation): return generation
        }
    }
}

extension HealthCardPropertyType: Equatable {
    public static func ==(lhs: HealthCardPropertyType, rhs: HealthCardPropertyType) -> Bool {
        // swiftlint:disable:previous operator_whitespace
        switch (lhs, rhs) {
        case let (.egk(lhsGeneration), .egk(rhsGeneration)): return lhsGeneration == rhsGeneration
        case let (.hba(lhsGeneration), .hba(rhsGeneration)): return lhsGeneration == rhsGeneration
        case let (.smcb(lhsGeneration), .smcb(rhsGeneration)): return lhsGeneration == rhsGeneration
        default: return false
        }
    }
}

extension HealthCardPropertyType: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .egk(generation): return "eGK \(generation)"
        case let .hba(generation): return "HBA \(generation)"
        case let .smcb(generation): return "SMC-B \(generation)"
        }
    }
}
