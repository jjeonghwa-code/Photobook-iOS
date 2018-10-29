//
//  DeliveryDetailsTests.swift
//  PhotobookTests
//
//  Created by Jaime Landazuri on 30/05/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import XCTest
@testable import Photobook

class DeliveryDetailsTests: XCTestCase {
    
    func validDetails() -> DeliveryDetails {
        let deliveryDetails = DeliveryDetails()
        deliveryDetails.firstName = "George"
        deliveryDetails.lastName = "Clowney"
        deliveryDetails.email = "g.clowney@clownmail.com"
        deliveryDetails.phone = "399945528234"
        deliveryDetails.line1 = "9 Fiesta Place"
        deliveryDetails.line2 = "Old Street"
        deliveryDetails.city = "London"
        deliveryDetails.zipOrPostcode = "CL0 WN4"
        deliveryDetails.stateOrCounty = "Clownborough"
        deliveryDetails.country = Country(name: "United Kingdom", codeAlpha2: "UK", codeAlpha3: "GBA", currencyCode: "GBP")
        
        return deliveryDetails
    }
    
    func testCopy() {
        let validDetails = self.validDetails()
        let validDetailsCopy = validDetails.copy() as! DeliveryDetails
        
        XCTAssertEqual(validDetails.firstName, validDetailsCopy.firstName)
        XCTAssertEqual(validDetails.lastName, validDetailsCopy.lastName)
        XCTAssertEqual(validDetails.email, validDetailsCopy.email)
        XCTAssertEqual(validDetails.phone, validDetailsCopy.phone)
        XCTAssertEqual(validDetails.line1, validDetailsCopy.line1)
        XCTAssertEqual(validDetails.line2, validDetailsCopy.line2)
        XCTAssertEqual(validDetails.city, validDetailsCopy.city)
        XCTAssertEqual(validDetails.zipOrPostcode, validDetailsCopy.zipOrPostcode)
        XCTAssertEqual(validDetails.stateOrCounty, validDetailsCopy.stateOrCounty)
        XCTAssertEqual(validDetails.country.codeAlpha2, validDetailsCopy.country.codeAlpha2)
    }
    
    func testIsValid_shouldBeTrueWithAValidAddress() {
        let deliveryDetails = validDetails()
        XCTAssertTrue(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfFirstNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfFirstNameIsEmpty() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = ""
        XCTAssertFalse(deliveryDetails.isValid)
    }

    func testIsValid_shouldBeFalseIfLastNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfLastNameIsEmpty() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = ""
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfEmailIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.email = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }

    func testIsValid_shouldBeFalseIfEmailIsNotValid() {
        let deliveryDetails = validDetails()
        deliveryDetails.email = "notrealmail@bonkers"
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfPhoneIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.phone = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfPhoneIsNotValid() {
        let deliveryDetails = validDetails()
        deliveryDetails.phone = "3434"
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfLine1IsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.line1 = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfTheCityIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.city = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testIsValid_shouldBeFalseIfThePostCodeIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.zipOrPostcode = nil
        XCTAssertFalse(deliveryDetails.isValid)
    }
    
    func testDescriptionWithoutLine1_shouldReturnTheRightAddress() {
        let addressDescription = validDetails().descriptionWithoutLine1()
        XCTAssertEqual(addressDescription, "Old Street, London, Clownborough, CL0 WN4, United Kingdom")
    }
    
    func testFullName_shouldBeNilIfFirstNameAndLastNameAreMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        deliveryDetails.lastName = nil
        XCTAssertNil(deliveryDetails.fullName)
    }
    
    func testFullName_shouldReturnFullName() {
        let deliveryDetails = validDetails()
        XCTAssertEqualOptional(deliveryDetails.fullName, "George Clowney")
    }
    
    func testFullName_shouldReturnLastNameIfFirstNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.firstName = nil
        XCTAssertEqualOptional(deliveryDetails.fullName, "Clowney")
    }

    func testFullName_shouldReturnLastNameIfLastNameIsMissing() {
        let deliveryDetails = validDetails()
        deliveryDetails.lastName = nil
        XCTAssertEqualOptional(deliveryDetails.fullName, "George")
    }

    func testDetails_canBePersisted() {
        let deliveryDetails = validDetails()
        DeliveryDetails.add(deliveryDetails)
        DeliveryDetails.loadSavedDetails()
        XCTAssertEqual([deliveryDetails], DeliveryDetails.savedDeliveryDetails)
    }
    
    func testSelectedDetails() {
        let deliveryDetails = validDetails()
        let deliveryDetails2 = validDetails()
        let deliveryDetails3 = validDetails()

        DeliveryDetails.add(deliveryDetails)
        DeliveryDetails.add(deliveryDetails3)
        DeliveryDetails.add(deliveryDetails2)
        
        let selected = DeliveryDetails.selectedDetails()
        XCTAssertEqualOptional(selected, deliveryDetails2)
    }
    
    func testJsonRepresentation() {
        let deliveryDetails = validDetails()
        
        let dictionary = deliveryDetails.jsonRepresentation()
        XCTAssertEqualOptional(dictionary["recipient_first_name"], deliveryDetails.firstName)
        XCTAssertEqualOptional(dictionary["recipient_last_name"], deliveryDetails.lastName)
        XCTAssertEqualOptional(dictionary["recipient_name"], deliveryDetails.fullName)
        XCTAssertEqualOptional(dictionary["address_line_1"], deliveryDetails.line1)
        XCTAssertEqualOptional(dictionary["address_line_2"], deliveryDetails.line2)
        XCTAssertEqualOptional(dictionary["city"], deliveryDetails.city)
        XCTAssertEqualOptional(dictionary["county_state"], deliveryDetails.stateOrCounty)
        XCTAssertEqualOptional(dictionary["postcode"], deliveryDetails.zipOrPostcode)
        XCTAssertEqualOptional(dictionary["country_code"], deliveryDetails.country.codeAlpha3)
    }
    
    func testDetails_shouldBeEmpty() {
        XCTAssertTrue(DeliveryDetails.savedDeliveryDetails.count == 0)
    }
    
    func testDetails_shouldSaveTheDetails() {
        let deliveryDetails = validDetails()
        DeliveryDetails.add(deliveryDetails)
        DeliveryDetails.loadSavedDetails()
        XCTAssertEqual([deliveryDetails], DeliveryDetails.savedDeliveryDetails)
    }
    
    func testDetails_shouldEditTheDetails() {
        let deliveryDetails = validDetails()
        DeliveryDetails.add(deliveryDetails)
        deliveryDetails.city = "Clowntown"
        DeliveryDetails.edit(deliveryDetails, at: 0)
        DeliveryDetails.loadSavedDetails()
        XCTAssertEqual([deliveryDetails], DeliveryDetails.savedDeliveryDetails)
    }
    
    func testDetails_shouldRemoveTheDetails() {
        let deliveryDetails = validDetails()
        DeliveryDetails.add(deliveryDetails)
        DeliveryDetails.remove(deliveryDetails)
        XCTAssertFalse(DeliveryDetails.savedDeliveryDetails.contains(deliveryDetails))
    }
    
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: DeliveryDetails.savedDetailsKey)
        DeliveryDetails.loadSavedDetails()
    }
}
