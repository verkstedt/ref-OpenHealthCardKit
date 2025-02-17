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

import CardReaderProviderApi
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import Util
import XCTest

final class HealthCardTypeExtEfCardAccessIntTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String { "Configuration/configuration_E021D-A5Tp_432_80276883110000218486.xml" }

    func testReadEfCardAccess() {
        expect {
            try Self.healthCard.currentCardChannel.readKeyAgreementAlgorithm(writeTimeout: 30, readTimeout: 30)
                .test()
        } == KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128
    }

    static let allTests = [
        ("testReadEfCardAccess", testReadEfCardAccess),
    ]
}
