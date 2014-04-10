//
//  JGReuseCache.m
//
//  Created by Jaden Geller on 8/19/13.
//  Copyright (c) 2013 Jaden Geller. All rights reserved.
//

#import "JGReuseCache.h"

@interface JGReuseCache ()

@property (nonatomic) NSMutableDictionary *queues;
@property (nonatomic) NSMutableDictionary *classes;
@property (nonatomic) NSMutableDictionary *reuseBlocks;

@end

@implementation JGReuseCache

-(id)init{
    if (self = [super init]) {
        _queues = [NSMutableDictionary dictionary];
        _classes = [NSMutableDictionary dictionary];
        _reuseBlocks = [NSMutableDictionary dictionary];
        
        // Free memory when needed
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAllCaches) name: UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAllCaches) name: UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

+(JGReuseCache*)sharedCache{
    static JGReuseCache *cache;
    if (!cache) cache = [[JGReuseCache alloc] init];
    return cache;
}

-(NSHashTable*)queueForClass:(Class)objectClass{
    NSHashTable *queue = self.queues[objectClass];
    
    // Throw exception if class is not registered
    //if (!queue) [NSException raise:@"Class not registered for reuse" format:@"Class \"%@\" is not registered for reuse",objectClass];
    
    return queue;
}

-(NSHashTable*)queueForIdentifier:(id<NSCopying>)identifier{
    NSHashTable *queue = self.queues[identifier];
    
    // Throw exception if identifier is not registered
    if (!queue) [NSException raise:@"Identifier not registered for reuse" format:@"\"%@\" is not a registered reuse identifier",identifier];

    return queue;
}

-(id<NSObject, JGReuse>)dequeueReusableObjectWithIdentifier:(id<NSCopying>)identifier{
    
    NSHashTable *queue = [self queueForIdentifier:identifier];
    
    id <NSObject, JGReuse> object = [queue anyObject];
    
    if (object) {
        // Remove object from queue
        [queue removeObject:object];
    }
    else{
        // Create object if queue is empty
        Class objectClass = self.classes[identifier];
        object = [[objectClass alloc]init];
        object.reuseIdentifier = identifier;
    }
    
    [self prepareObjectForReuse:object withIdentifier:identifier];
    
    return object;
}

-(UIView*)dequeueReusableViewWithTag:(NSInteger)tag{
    id<NSCopying> identifier = [JGReuseCache reuseIdentifierForTag:tag];
    NSHashTable *queue = [self queueForIdentifier:identifier];
    
    UIView *object = [queue anyObject];
    if (object) {
        // Remove object from queue
        [queue removeObject:object];
    }
    else{
        // Create object if queue is empty
        Class objectClass = self.classes[identifier];
        object = [[objectClass alloc]init];
        object.tag = tag;
    }
    
    [self prepareObjectForReuse:object withIdentifier:identifier];
    
    return object;
}

-(id<NSObject>)dequeueReusableObjectWithClass:(Class)objectClass{
    NSHashTable *queue = [self queueForClass:objectClass];
    
    id<NSObject> object = [queue anyObject];
    
    if (object) [queue removeObject:object]; // Remove object from queue
    else object = [[objectClass alloc]init]; // Create object is queue is empty
    
    [self prepareObjectForReuse:object withIdentifier:(id<NSCopying>)objectClass];
    
    return object;
}

-(void)prepareObjectForReuse:(id<NSObject>)object withIdentifier:(id<NSCopying>)identifier{
    void (^reuseBlock)(id<NSObject> object) = self.reuseBlocks[identifier];
    if (reuseBlock) reuseBlock(object);
}

-(void)enqueueReusableObject:(id<NSObject>)object withIdentifier:(id<NSCopying>)identifier{
    NSHashTable *queue = [self queueForIdentifier:identifier];
    
    if (self.classes[identifier] != object.class){
        // Object is incorrect class for identifier
        [NSException raise:@"Incorrect class for identifier" format:@"Reuse identifier \"%@\" registered for class \"%@\" but object is of class \"%@\"",identifier,self.classes[identifier],object.class];
    }
    else{
        // All is good; add object to queue based on reuse identifier
        [queue addObject:object];
    }

}

-(void)enqueueReusableObject:(id<NSObject>)object{
    NSLog(@"%@",[JGReuseCache reuseIdentifierForTag:[(UIView*)object tag]]);
    if ([object conformsToProtocol:@protocol(JGReuse)] && [(id<JGReuse>)object reuseIdentifier]) {
        // Conforms to JGReuse and has a defined reuse identifier
        // Enqueue by identifier
        
        id<NSCopying> reuseIdentifier = [(id<JGReuse>)object reuseIdentifier];
        [self enqueueReusableObject:object withIdentifier:reuseIdentifier];
        
        }
    else if([object isKindOfClass:[UIView class]] && self.queues[[JGReuseCache reuseIdentifierForTag:[(UIView*)object tag]]]){
        // Object is a view and has a registered tag
        // Enqueue by tag
        
        [self enqueueReusableObject:object withIdentifier:[JGReuseCache reuseIdentifierForTag:[(UIView*)object tag]]];
    }
    else{
        //Enqueue by class
        [[self queueForClass:object.class] addObject:object];
    }
}

-(BOOL)attemptToEnqueueObject:(id<NSObject>)object{
    @try {
        [self enqueueReusableObject:object];
    }
    @catch (NSException *exception) {
        return NO;
    }
}

-(void)registerObjectReuseForIdentifier:(id<NSCopying>)identifier class:(Class)objectClass{
    // Make sure reuse identifier is not already registered
    Class alreadyRegistered = self.classes[identifier];
    if (alreadyRegistered) {
        [NSException raise:@"Identifier is already registered for reuse" format:@"Identifier \"%@\" is already registered to class \"%@\" for reuse",identifier,alreadyRegistered];
    }
    else if (![objectClass conformsToProtocol:@protocol(JGReuse)]){
        [NSException raise:@"Class does not conform to protocol" format:@"Class \"%@\" does not conform to protocol JGReuse",objectClass];
    }
    else{
        // Add class to class dictionary for reuse identifier
        [self.classes setObject:objectClass forKey:identifier];
        
        // Add hash table to queue dictionary for reuse identifier
        // Hash table checks for duplicates with pointer equality, not object equality
        [self.queues setObject:[NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality] forKey:identifier];
    }
}

-(void)registerObjectReuseForClass:(Class)objectClass{
    BOOL alreadyRegistered = (BOOL)self.queues[(id<NSCopying>)objectClass];
    if (alreadyRegistered) {
        [NSException raise:@"Class is already registered for reuse" format:@"Class \"%@\" is already registered for reuse",objectClass];
    }
    else{
        [self.queues setObject:[NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality] forKey:(id<NSCopying>)objectClass];
    }
}

-(void)registerViewReuseForTag:(NSInteger)tag{
    [self registerViewReuseForTag:tag subclass:[UIView class]];
}

-(void)registerViewReuseForTag:(NSInteger)tag subclass:(Class)subclass{
    id<NSCopying> identifier = [JGReuseCache reuseIdentifierForTag:tag];

    // Make sure reuse identifier is not already registered
    Class alreadyRegistered = self.classes[identifier];
    if (alreadyRegistered) {
        [NSException raise:@"Tag is already registered for reuse" format:@"Tag \"%@\" is already registered to class \"%@\" for reuse",identifier,alreadyRegistered];
    }
    else if (![subclass isSubclassOfClass:[UIView class]]){
        [NSException raise:@"Class is not a subclass of UIView" format:@"Class \"%@\" is not a subclass of UIView",subclass];
    }
    else{
        // Add class to class dictionary for reuse identifier
        [self.classes setObject:subclass forKey:identifier];
        
        // Add hash table to queue dictionary for reuse identifier
        // Hash table checks for duplicates with pointer equality, not object equality
        [self.queues setObject:[NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality] forKey:identifier];
    }
}

-(void)registerObjectReuseForIdentifier:(id<NSCopying>)identifier class:(Class)objectClass reuseBlock:(void (^)(id<NSObject> object))reuseBlock{
    [self registerObjectReuseForIdentifier:identifier class:objectClass];
    self.reuseBlocks[identifier] = reuseBlock;
}

-(void)registerObjectReuseForClass:(Class)objectClass reuseBlock:(void (^)(id<NSObject> object))reuseBlock{
    [self registerObjectReuseForClass:objectClass];
    self.reuseBlocks[(id<NSCopying>)objectClass] = reuseBlock;
}

-(void)registerViewReuseForTag:(NSInteger)tag reuseBlock:(void (^)(id<NSObject> object))reuseBlock{
    [self registerViewReuseForTag:tag];
    self.reuseBlocks[[JGReuseCache reuseIdentifierForTag:tag]] = reuseBlock;
}

-(void)registerViewReuseForTag:(NSInteger)tag subclass:(Class)subclass reuseBlock:(void (^)(id<NSObject> object))reuseBlock{
    [self registerViewReuseForTag:tag subclass:subclass];
    self.reuseBlocks[[JGReuseCache reuseIdentifierForTag:tag]] = reuseBlock;
}

-(void)deregisterObjectReuseForIdentifier:(id<NSCopying>)identifier{
    [self.classes removeObjectForKey:identifier];
    [self.queues removeObjectForKey:identifier];
    [self.reuseBlocks removeObjectForKey:identifier];
}

-(void)deregisterObjectReuseForClass:(Class)objectClass{
    [self.queues removeObjectForKey:(id<NSCopying>)objectClass];
    [self.reuseBlocks removeObjectForKey:(id<NSCopying>)objectClass];
}

-(void)deregisterViewReuseForTag:(NSInteger)tag{
    [self deregisterObjectReuseForIdentifier:[JGReuseCache reuseIdentifierForTag:tag]];
}

-(void)deregisterAllObjectReuseIdentifiers{
    [self.classes removeAllObjects];
    [self.queues removeAllObjects];
    [self.reuseBlocks removeAllObjects];
}

-(void)clearAllCaches{
    for (NSHashTable *hashTable in self.queues) {
        [hashTable removeAllObjects];
    }
}

-(void)clearCacheForIdentifier:(id<NSCopying>)identifier{
    [self.queues[identifier] removeAllObjects];
}

-(void)clearCacheForClass:(Class)objectClass{
    [self.queues[(id<NSCopying>)objectClass] removeAllObjects];
}

-(void)clearCacheForTag:(NSInteger)tag{
    [self.queues[[JGReuseCache reuseIdentifierForTag:tag]] removeAllObjects];
}

+(id<NSCopying>)reuseIdentifierForTag:(NSInteger)tag{
    return @[[UIView class], [NSNumber numberWithInteger:tag]];
}

@end
