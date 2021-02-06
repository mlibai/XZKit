//
//  DataDigesterTests.m
//  XZKitTests
//
//  Created by Xezun on 2021/2/10.
//

#import <XCTest/XCTest.h>
#import <XZKit/XZKit.h>

@interface DataDigesterTests : XCTestCase

@end

@implementation DataDigesterTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testMD5 {
    NSString *strRaw = @"XZKit 教程";
    NSString *strMD5 = @"07538864E2A7306CB560AAB785E4E265";
    NSString *strSHA1 = @"C152ADAE72EDECD473D232B0D7AA4D6D1585F2A9";
    
    NSString *MD5 = strRaw.xz_MD5;
    XCTAssert([MD5 isEqual:strMD5]);
    
    NSString *SHA1 = strRaw.xz_SHA1;
    XCTAssert([SHA1 isEqual:strSHA1]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
