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
import Foundation

public protocol HealthCardResponseType: ResponseType {
    /// Returns `ResponseStatus` derived from the executed `HealthCardCommand` and *sw* value of `ResponseType`.
    var responseStatus: ResponseStatus { get }
}

extension HealthCardResponseType {
    static func from(response: ResponseType, for command: HealthCardCommandType) -> HealthCardResponseType {
        HealthCardResponse(
            response: response,
            responseStatus: command.responseStatus(from: response.sw)
        )
    }
}
