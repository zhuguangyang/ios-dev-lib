//
//  MyButton.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "MyButton.h"

@implementation MyButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder])
    {
        self.layer.borderWidth = 1.5;
        self.layer.cornerRadius = 4.5;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGColorRef borderColorRef = CGColorCreate(colorSpace,(CGFloat[]){ 0.92f, 0.92f, 0.92f, 1 });
        self.layer.borderColor = borderColorRef;
    }
    return self;
}

@end
