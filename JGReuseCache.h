//
//  JGReuseCache.h
//
//  Created by Jaden Geller on 8/19/13.
//  Copyright (c) 2013 Jaden Geller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UITableViewCell+Reuse.h"
#import "UICollectionViewCell+Reuse.h"

@protocol JGReuse <NSObject>

@property (nonatomic, copy) id<NSCopying> reuseIdentifier;

@end

@interface JGReuseCache : NSObject

+(JGReuseCache*)sharedCache;

-(id<NSObject, JGReuse>)dequeueReusableObjectWithIdentifier:(id<NSCopying>)identifier;
-(id<NSObject>)dequeueReusableObjectWithClass:(Class)objectClass;
-(UIView*)dequeueReusableViewWithTag:(NSInteger)tag;

-(void)enqueueReusableObject:(id<NSObject>)object;
-(BOOL)isReusableObject:(id<NSObject>)object;
-(BOOL)attemptToEnqueueObject:(id<NSObject>)object;

-(void)registerObjectReuseForIdentifier:(id<NSCopying>)identifier class:(Class)objectClass;
-(void)registerObjectReuseForIdentifier:(id<NSCopying>)identifier class:(Class)objectClass reuseBlock:(void (^)(id<NSObject> object))reuseBlock;

-(void)registerObjectReuseForClass:(Class)objectClass;
-(void)registerObjectReuseForClass:(Class)objectClass reuseBlock:(void (^)(id<NSObject> object))reuseBlock;

-(void)registerViewReuseForTag:(NSInteger)tag;
-(void)registerViewReuseForTag:(NSInteger)tag subclass:(Class)subclass;
-(void)registerViewReuseForTag:(NSInteger)tag reuseBlock:(void (^)(id<NSObject> object))reuseBlock;
-(void)registerViewReuseForTag:(NSInteger)tag subclass:(Class)subclass reuseBlock:(void (^)(id<NSObject> object))reuseBlock;

-(void)deregisterObjectReuseForIdentifier:(id<NSCopying>)identifier;
-(void)deregisterObjectReuseForClass:(Class)objectClass;
-(void)deregisterViewReuseForTag:(NSInteger)tag;
-(void)deregisterAllObjectReuseIdentifiers;

-(void)clearAllCaches;
-(void)clearCacheForIdentifier:(id<NSCopying>)identifier;
-(void)clearCacheForTag:(NSInteger)tag;
-(void)clearCacheForClass:(Class)objectClass;

@end
