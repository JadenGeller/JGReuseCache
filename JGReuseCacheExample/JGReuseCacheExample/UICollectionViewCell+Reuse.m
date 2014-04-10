//
//  UICollectionViewCell+Reuse.m
//  JGReuseCacheExample
//
//  Created by Jaden Geller on 4/9/14.
//  Copyright (c) 2014 Jaden Geller. All rights reserved.
//

#import "UICollectionViewCell+Reuse.h"
#import "JGReuseCache.h"

@implementation UICollectionViewCell (Reuse)

-(void)reuseContents{
    for (UIView *view in self.subviews) [[JGReuseCache sharedCache]attemptToEnqueueObject:view];
}

@end
