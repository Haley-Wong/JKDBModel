//
//  ZXCommonTool.h
//  yuyou
//
//  Created by ganyanchao on 7/27/16.
//  Copyright © 2016 Zhang Xiu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZXCommonTool : NSObject


+ (BOOL)zx_strIsEmpty:(NSString *)str;

+ (BOOL)zx_arrayIsEmpty:(NSArray *)array;

+ (BOOL)zx_dicIsEmpty:(NSDictionary *)dic;


+ (NSString *)replayPlaybackTimeFormatterWith:(long long)seconds;

/**
 *  安全取 str
 *
 *  @param str 传入的str
 *
 *  @return str 本身 或者 @""
 */
+ (NSString *)safeOfString:(NSString *)str;


/**
 *  设备型号
 *
 *  @return
 */
+(NSString *)deviceModel;


/**
 *  设备code
 *
 *  @return iphone5,5
 */
+(NSString *)deviceCode;

@end
