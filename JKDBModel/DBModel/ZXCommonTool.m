//
//  ZXCommonTool.m
//  yuyou
//
//  Created by ganyanchao on 7/27/16.
//  Copyright © 2016 Zhang Xiu Inc. All rights reserved.
//

#import "ZXCommonTool.h"
#import "sys/utsname.h"


@implementation ZXCommonTool

+ (BOOL)zx_strIsEmpty:(NSString *)str{

    return !(str && [str isKindOfClass:[NSString class]] && str.length &&![str isEqual:[NSNull null]]);
}

+ (BOOL)zx_arrayIsEmpty:(NSArray *)array{
    
    return !(array && [array isKindOfClass:[NSArray class]] && array.count && ![array isEqual:[NSNull null]]);
}


+ (BOOL)zx_dicIsEmpty:(NSDictionary *)dic{

  return !(dic && [dic isKindOfClass:[NSDictionary class]] && dic.count && ![dic isEqual:[NSNull null]]);
}

+ (NSString *)replayPlaybackTimeFormatterWith:(long long)msseconds{

    long long  seconds = ceil(msseconds / 1000); // ms - s
    
    long min = seconds / 60;
    long sec = seconds % 60;
    NSString * result = [NSString stringWithFormat:@"%ld:%02ld",min,sec];
    return result;
}


+ (NSString *)safeOfString:(NSString *)str{
    
    if ([self zx_strIsEmpty:str]) {
        return @"";
    }
    return str;
}



+(NSString *)deviceModel{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    static NSDictionary * mapping;
    if (!mapping) {
        mapping = @{
                    //iPhone
                    @"iPhone1,1":@"iPhone 1G",
                    @"iPhone1,2":@"iPhone 3G",
                    @"iPhone2,1":@"iPhone 3GS",
                    @"iPhone3,1":@"iPhone 4",
                    @"iPhone3,2":@"Verizon iPhone 4",
                    @"iPhone4,1":@"iPhone 4S",
                    @"iPhone5,1":@"iPhone 5",
                    @"iPhone5,2":@"iPhone 5",
                    @"iPhone5,3":@"iPhone 5C",
                    @"iPhone5,4":@"iPhone 5C",
                    @"iPhone6,1":@"iPhone 5S",
                    @"iPhone6,2":@"iPhone 5S",
                    @"iPhone7,1":@"iPhone 6 Plus",
                    @"iPhone7,2":@"iPhone 6",
                    @"iPhone8,1":@"iPhone 6s",
                    @"iPhone8,2":@"iPhone 6s Plus",
                    //iPod
                    @"iPod1,1":@"iPod Touch 1G",
                    @"iPod2,1":@"iPod Touch 2G",
                    @"iPod3,1":@"iPod Touch 3G",
                    @"iPod4,1":@"iPod Touch 4G",
                    @"iPod5,1":@"iPod Touch 5G",
                    //iPad
                    @"iPad1,1":@"iPad",
                    @"iPad2,1":@"iPad 2 (WiFi)",
                    @"iPad2,2":@"iPad 2 (GSM)",
                    @"iPad2,3":@"iPad 2 (CDMA)",
                    @"iPad2,4":@"iPad 2 (32nm)",
                    @"iPad2,5":@"iPad mini (WiFi)",
                    @"iPad2,6":@"iPad mini (GSM)",
                    @"iPad2,7":@"iPad mini (CDMA)",
                    @"iPad4,4":@"iPad mini 2",
                    @"iPad4,5":@"iPad mini 2",
                    @"iPad4,6":@"iPad mini 2",
                    @"iPad4,7":@"iPad mini 3",
                    @"iPad4,8":@"iPad mini 3",
                    @"iPad4,9":@"iPad mini 3",
                    @"iPad3,1":@"iPad 3(WiFi)",
                    @"iPad3,2":@"iPad 3(CDMA)",
                    @"iPad3,3":@"iPad 3(4G)",
                    @"iPad3,4":@"iPad 4 (WiFi)",
                    @"iPad3,5":@"iPad 4 (4G)",
                    @"iPad3,6":@"iPad 4 (CDMA)",
                    @"iPad4,1":@"iPad Air",
                    @"iPad4,2":@"iPad Air",
                    @"iPad4,3":@"iPad Air",
                    @"iPad5,3":@"iPad Air 2",
                    @"iPad5,4":@"iPad Air 2",
                    //模拟器
                    @"i386":@"iPhone Simulator",
                    @"x86_64":@"iPhone Simulator",
                    };
    }
    return mapping[deviceString]?mapping[deviceString]:@"iPhone";
}

+(NSString *)deviceCode{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}






@end
