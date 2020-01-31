//
//  XZKitConstantsSwiftTests.swift
//  XZKitTests
//
//  Created by 徐臻 on 2020/1/30.
//  Copyright © 2020 Xezun Inc. All rights reserved.
//

import XCTest
import XZKit

class XZKitConstantsSwiftTests: XCTestCase {

    override func setUp() {
        isDebugMode = true
    }

    override func tearDown() {
        isDebugMode = false
    }

    func testConstants() {
        // 当前时间戳。
        XZLog("%@", TimeInterval.since1970);
        
        // OptionSet.none
        let state: UIControl.State = [];
        XZLog("%@", state);
    }
    
    func testString() {
        let string1 = String.init(formats: "%@ %02ld %.2f", "对象", 2, CGFloat.pi);
        let string2 = String.init(formats: "%@ %@ %@", "对象", 2, CGFloat.pi);
        XZLog("string1: \(string1), \nstring2: \(string2)")
        
        XZLog("cast NSNull to string: %@", String(casting: NSNull()))
        XZLog("cast object to string: %@", String(casting: self))
        XZLog("cast option to string: %@", self.accessibilityAttributedLabel)
        
        NSLog("----%@", self);
        
        XZLog("%@", String(isolating: "We are Super Man.", direction: .leftToRight));
        XZLog("%@", String(isolating: "We are Super Man.", direction: .rightToLeft));
        XZLog("%@", String(isolating: "We are Super Man.", direction: .firstStrong));
        
        XZLog("%@", "   234f \n".trimmingCharacters(in: " \t\n"))
        XZLog("%@", "我是中国人".transformingMandarinToLatin);
        
        XZLog("%@", "https://www.baidu.com/?keyword=中国#2".addingURIEncoding)
        XZLog("%@", "https://www.baidu.com/?keyword=中国#2".addingURIComponentEncoding)
        
        XZLog("%@", """
        第一行：ABC
        第二行：EDF
        """)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
