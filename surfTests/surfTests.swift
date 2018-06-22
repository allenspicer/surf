//
//  surfTests.swift
//  surfTests
//
//  Created by Allen Spicer on 4/19/18.
//  Copyright © 2018 surf. All rights reserved.
//

import XCTest
@testable import surf

class surfTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_initial_view_is_not_nil(){
        let  controller = HomeViewController()
        let view = controller.view
        XCTAssertNotNil(view)
    }
    
    func test_second_view_is_not_nil(){
        let  controller = ViewController()
        let view = controller.view
        XCTAssertNotNil(view)
    }
    
    
    
    

    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//
//            let result = bouyDataServiceRequest{}
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
