//
//  AylaDefines.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 10/5/15.
//  Copyright © 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_feature(objc_generics) || __has_extension(objc_generics)
    #define AYLA_GENERIC(...) <__VA_ARGS__>
#else
    #define AYLA_GENERIC(...)
#endif
