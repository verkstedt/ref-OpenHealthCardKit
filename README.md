# OpenHealthCardKit

Controlling/Use-case framework for accessing smart cards of the telematic infrastructure.

## Introduction

The OpenHealthCardKit module is intended for reference purposes
when implementing a system that performs the communication between an iOS based mobile device
and a German Health Card (elektronische Gesundheitskarte) using an NFC, Blue Tooth oder USB interface.

This document describes the functionalitiy and structure of OpenHealthCardKit.

## API Documentation

Generated API docs are available at <https://gematik.github.io/ref-OpenHealthCardKit>.

## License

Licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Getting Started

OpenHealthCardKit requires Swift 5.1.

### Setup for integration

-   **Swift Package Manager:** Put this in your `Package.swift`:

        `.package(url: "https://github.com/gematik/ref-OpenHealthCardKit", from: "5.3.0"),`

-   **Carthage:** Put this in your `Cartfile`:

        github "gematik/ref-openHealthCardKit" ~> 5.0

### Setup for development

Run `$ make setup` to start developing locally. This will make sure all the dependencies are put in place and the Xcode-project will be generated and/or overwritten.

Dependencies are a mix of SPM (Swift Package Manager) and Carthage right now. The Xcode-project is generated using `xcodegen`.
The more complex build configuration(s) is done with the help of Fastlane. See the `./fastlane` directory for full setup.

## Overview

OpenHealthCardKit bundles submodules that provide the functionality
necessary for accessing and interacting with German Health Cards via a mobile iOS device.

OpenHealthCardKit consists of the submodules

-   CardReaderProviderApi

-   HealthCardAccess

-   HealthCardControl

-   NFCCardReaderProvider

As a reference for each submodule see also the `IntegrationTests`.
Also see a [Demo App](https://github.com/gematik/ref-OpenHealthCardApp-iOS) on GitHub using this framework.

### CardReaderProviderApi

(Smart)CardReader protocols for interacting with `HealthCardAccess`.

### HealthCardAccess

This library contains the classes for cards, commands, card file systems and error handling.

#### HealthCardAccess API

The HealthCardAccessKit API Structure contains the `HealthCard` class representing all supported card types,
the `Commands` and `Responses` groups with all supported commands and responses for health cards,
the `CardObjects` group with the possible objects on a health cards
and the `Operation` group for cascading and executing commands on health cards.

##### Health Cards

The class `HealthCard` represents the potential types of health cards by storing a `HealthCardStatus` property which in
case of being *valid* by itself stores a `HealthCardPropertyType` which at the time of writing is represented by either
one of the following

-   egk ("elektronische Gesundheitskarte")

-   hba ("Heilberufeausweis")

-   smcb ("Security Module Card Typ B").

The `HealthCardPropertyType` by itself stores the `CardGeneration` (G1, G1P, G2, G2.1) as well.

Furthermore the `HealthCard` object contains the physical card from a card reader and the current card channel.

##### Commands

The `Commands` groups contains all available `HealthCardCommand` objects for health cards through the `HealthCardCommandBuilder`.

#### Code Samples

##### Create a command

The design of this API follows the [command design pattern](https://en.wikipedia.org/wiki/Command_pattern)
leveraging Swift’s [Combine Framework](https://developer.apple.com/documentation/combine/).
The command objects are designed to fulfil the use-cases described in the [Gematik COS specification](https://www.vesta-gematik.de/standards/detail/standards/spezifikation-des-card-operating-system-cos-elektrische-schnittstelle-1/).
After creating a command object resp. sequence you can execute it on a Healthcard with the help of `publisher(for:)`.
More information on how to configure the commands can also be found in the Gematik COS specification.

Following example shall send a SELECT and a READ command to a smart card
in order to select and read the certificate stored in the file EF.C.CH.AUT.R2048 in the application ESIGN.

First we want to to create a `SelectCommand` object passing a `ApplicationIdentifier`. We use one of the predefined
helper functions by using `HealthCardCommand.Select`.

One could also use the `HealthCardCommandBuilder` to construct a customized `HealthCardCommand`
by setting the APDU-bytes manually.

    let eSign = EgkFileSystem.DF.ESIGN
    let selectEsignCommand = HealthCardCommand.Select.selectFile(with: eSign.aid)

##### Setting an execution target

We execute the created command `CardType` instance which has been typically provided by a `CardReaderType`.

In the next example we use a `HealthCard` object representing an eGK (elektronische Gesundheitskarte)
as one kind of a `HealthCardType` implementing the `CardType` protocol.

    // initialize your CardReaderType instance
    let cardReader: CardReaderType = CardSimulationTerminalTestCase.reader
    let card = try cardReader.connect([:])!
    let healthCardStatus = HealthCardStatus.valid(cardType: .egk(generation: .g2))
    let eGk = try HealthCard(card: card, status: healthCardStatus)
    let publisher: AnyPublisher<HealthCardResponseType, Error> = selectEsignCommand.publisher(for: eGk)

A created command can be lifted to the Combine framework with `publisher(for:writetimeout:readtimeout)`.
The result of the command execution can be validated against an expected `ResponseStatus`,
e.g. SUCCESS (0x9000).

    let checkResponse = publisher.tryMap { healthCardResponse -> HealthCardResponseType in
        guard healthCardResponse.responseStatus == ResponseStatus.success else {
            throw HealthCard.Error.operational // throw a meaningful Error
        }
        return healthCardResponse
    }

##### Create a Command Sequence

It is possible to chain further commands via the `flatMap` operator for subsequent execution:
First create a command and lift it onto a Combine monad, then create a publisher using the `flatMap` operator, e.g.

    Just(AnyHealthCardCommand.build())
        .flatMap { command in command.pusblisher(for: card) }

Eventually use `eraseToAnyPublisher()`.

    let readCertificate = checkResponse
        .tryMap { _ -> HealthCardCommandType in
            let sfi = EgkFileSystem.EF.esignCChAutR2048.sfid!
            return try HealthCardCommand.Read.readFileCommand(with: sfi, ne: 0x076C - 1)
        }
        .flatMap { command in
            command.publisher(for: eGk)
        }
        .eraseToAnyPublisher()

##### Process Execution result

When the whole command chain is set up we have to subscribe to it.
We really only will receive one value before completion, so something as simple as this `sink()`
convenience publisher is useful.

    readCertificate
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    DLog("Completed")
                case let .failure(error):
                    DLog("Error: \(error)")
                }
            },
            receiveValue: { healthCardResponse in
                DLog("Got a certifcate")
                let certificate = healthCardResponse.data!
                // proceed with certificate data here
                // use swiftUI to a show success message on screen etc.
            }
        )

### HealthCardControl

This library can be used to realize use cases for interacting with a German Health Card
(eGk, elektronische Gesundheitskarte) via a mobile device.

Typically you would use this library as the high level API gateway for your mobile application
to send predefined command chains to the Health Card and interpret the responses.

For more info, please find the low level part `HealthCardAccess`.
and a [Demo App](https://github.com/gematik/ref-OpenHealthCardApp-iOS) on GitHub.

See the [Gematik GitHub IO](https://gematik.github.io/) page for a more general overview.

#### Code Samples

Take the necessary preparatory steps for signing a challenge on the Health Card, then sign it.

    expect {
        let challenge = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8])
        let format2Pin = try Format2Pin(pincode: "123456")
        return try Self.healthCard.verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
            .flatMap { _ in
                Self.healthCard.sign(data: challenge)
            }
            .eraseToAnyPublisher()
            .test()
            .responseStatus
    } == ResponseStatus.success

Encapsulate the [PACE protocol](https://www.bsi.bund.de/DE/Publikationen/TechnischeRichtlinien/tr03110/index_htm.html)
steps for establishing a secure channel with the Health Card and expose only a simple API call .

    try KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.negotiateSessionKey(
        card: CardSimulationTerminalTestCase.healthCard,
        can: can,
        writeTimeout: 0,
        readTimeout: 10
    )

See the integration tests [IntegrationTests/HealthCardControl/](include::../../IntegrationTests/HealthCardControl/)
for more already implemented use cases.

### NFCCardReaderProvider

A `CardReaderProvider` implementation that handles the
communication with the Apple iPhone NFC interface.

### NFCDemo

The NFCDemo iOS App target demonstrates the use of OHCKit and the NFCCardReader\[Provider\] specifically by utilizing
said framework to connect to and establish a secure communications channel with an eGK Card via NFC.

The App consist out of two screens/views. The first one will prompt the user for the CAN number.
The second prompts for the PIN. This PIN is verified on the card against `mrpinHome` when the `connect` button is tapped.
