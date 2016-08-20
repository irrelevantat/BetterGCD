//
//  BetterGCDPipeTests.swift
//  BetterGCDPipeTests
//
//  Created by Sebastian Hojas on 19/08/16.
//  Copyright © 2016 Sebastian Hojas. All rights reserved.
//

import XCTest
@testable import BetterGCD

class BetterGCDPipeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    enum Error: ErrorType
    {
        case Fatal
    }
    
    func testBasic() {
        
        var testOrder = [3,2,1]
        let expectation = self.expectationWithDescription("last block")
        
        GCDPipe<Int>().async { (_) -> Int? in
            XCTAssertTrue(testOrder.popLast() == 1)
            return 9870
            }.async { (value) -> Int? in
                
                XCTAssertTrue(value == 9870)
                XCTAssertTrue(testOrder.popLast() == 2)
                
                return nil
            }.async { (value) -> (Int?) in
                
                let isOnMainQueue = (dispatch_queue_get_label(dispatch_get_main_queue()) == dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
                XCTAssertTrue(isOnMainQueue)
                
                XCTAssertTrue(value == nil)
                XCTAssertTrue(testOrder.popLast() == 3)
                expectation.fulfill()
                return nil
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testCatch()
    {
        var testOrder = [3,2,1]
        let expectation = self.expectationWithDescription("last block")
        
        
        GCDPipe<Int>().async { (_) -> Int? in
            XCTAssertTrue(testOrder.popLast() == 1)
            return nil
            }.async { (value) -> Int? in
                XCTAssertTrue(testOrder.popLast() == 2)
                throw Error.Fatal
            }.async { (value) -> (Int?) in
                XCTFail()
                return nil
        }.catching { (error) in
            XCTAssertTrue(testOrder.popLast() == 3)
            XCTAssertTrue(error as? Error == Error.Fatal)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
        
    }
    
    func testAfter()
    {
        let expectation = self.expectationWithDescription("last block")
        
        GCDPipe<NSDate>().async { (_) -> (NSDate?) in
            return NSDate()
        }.after(1).async { (date) -> (NSDate?) in
            guard let date = date else {
                XCTFail()
                return nil
            }
            XCTAssertEqualWithAccuracy(abs(date.timeIntervalSinceNow), 1, accuracy: 0.2)
            return NSDate()
        }.after(2).async { (date) -> (NSDate?) in
            guard let date = date else {
                XCTFail()
                return nil
            }
            XCTAssertEqualWithAccuracy(abs(date.timeIntervalSinceNow), 2, accuracy: 0.2)
            expectation.fulfill()
            return nil
        }
        
        self.waitForExpectationsWithTimeout(4.0, handler: nil)
        
    }
    
    func testWithoutPipe()
    {
        let expectation = self.expectationWithDescription("last block")
        var testOrder = [5,4,3,2,1]
        
        GCD().async { 
            XCTAssertTrue(testOrder.popLast() == 1)
            }.async {
            XCTAssertTrue(testOrder.popLast() == 2)
        }.after(2).async {
            XCTAssertTrue(testOrder.popLast() == 3)
            expectation.fulfill()
        }.async {
            XCTAssertTrue(testOrder.popLast() == 4)
            throw Error.Fatal
        }.catching { (error) in
            XCTAssertTrue(testOrder.popLast() == 5)
            XCTAssertTrue(error as? Error == Error.Fatal)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(4.0, handler: nil)
        
    }
    
    func testRepititionGCD()
    {
        var testOrder = (0...102).reverse().map { $0 }
        let expectation = self.expectationWithDescription("last block")
        
        var counter = 0
        
        GCD().cycle(100).async {
            XCTAssertTrue(testOrder.popLast() == counter)
            counter += 1
        }.async {
            XCTAssertTrue(testOrder.popLast() == 100)
            throw Error.Fatal
        }.catching { (error) in
            XCTAssertTrue(testOrder.popLast() == 101)
            XCTAssertTrue(error as? Error == Error.Fatal)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(6.0, handler: nil)
        
    }
    
    func testRepititionGCDPipe()
    {
        
        var testOrder = (0...11).reverse().map { $0 }
        let expectation = self.expectationWithDescription("last block")
        var counter = 0

        GCDPipe<NSDate>().async { _ in
            return NSDate()
        }.cycle(10).after(0.5).async { date in
            guard let date = date else {
                XCTFail()
                return nil
            }
            XCTAssertEqualWithAccuracy(abs(date.timeIntervalSinceNow), 0.5, accuracy: 0.1)
            XCTAssertTrue(testOrder.popLast() == counter)
            counter += 1
            
            return NSDate()
            }.async { date in
                guard let date = date else {
                    XCTFail()
                    return nil
                }
                XCTAssertTrue(testOrder.popLast() == 10)
                XCTAssertEqualWithAccuracy(abs(date.timeIntervalSinceNow), 0.05, accuracy: 0.2)
                throw Error.Fatal
            }.async { _ in
                XCTFail()
                return nil
            }.catching { error in
                XCTAssertTrue(testOrder.popLast() == 11)
                XCTAssertTrue(error as? Error == Error.Fatal)
                expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)

        
        
    }
    
    func testDocu()
    {
        
        
        GCD().async { 
            throw Error.Fatal
        }.async { 
            // never called
        }.catching { error in
            print("Error: \(error) in async block")
        }
        
    }
    
}
