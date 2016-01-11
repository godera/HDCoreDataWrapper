//
//  HDCD.m
//  agent
//
//  Created by LiMing on 14-6-24.
//  Copyright (c) 2014年 bangban. All rights reserved.
//

#import "HDCD.h"

@interface HDCD ()
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, copy) NSString *sqliteFileName;
@end


@implementation HDCD

+(HDCD*)sharedInstance {
    static HDCD *singleInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[HDCD alloc] init];
    });
    return singleInstance;
}

+ (void)setEnvironmentWithModelName:(NSString *)modelName sqliteFileName:(NSString *)fileName {
    [[self sharedInstance] setEnvironmentWithModelName:modelName sqliteFileName:fileName];
}
- (void)setEnvironmentWithModelName:(NSString *)modelName sqliteFileName:(NSString *)fileName {
    _modelName = modelName;
    _sqliteFileName = fileName;
    [self initCoreDataStack];
}

- (void)initCoreDataStack {
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_privateContext setPersistentStoreCoordinator:coordinator];

        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainContext setParentContext:_privateContext];
    }

}


+ (NSManagedObjectContext *)createTempPrivateContext {
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    ctx.parentContext = [self sharedInstance].mainContext;
    return ctx;
}


- (NSManagedObjectModel *)managedObjectModel
{
    NSManagedObjectModel *managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_sqliteFileName];

    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    return persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
//    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


+ (NSError*)saveContextAsyncWithComplete:(SaveResult)complete{
    return [[self sharedInstance] saveContextAsyncWithComplete:complete];
}
-(NSError*)saveContextAsyncWithComplete:(SaveResult)complete{
    NSError *error;
    if ([_mainContext hasChanges]) {
        [_mainContext save:&error];
        [_privateContext performBlock:^{
            NSError *innerError = nil;
            [_privateContext save:&innerError];
            if (complete){
                [_mainContext performBlock:^{
                    complete(innerError);
                }];
            }
        }];
    }
    return error;
}

+ (void)saveContext:(NSError **)error {
    [[self sharedInstance] saveContext:error];
}
- (void)saveContext:(NSError **)error {
    if ([[HDCD sharedInstance].privateContext hasChanges]) {
        [[HDCD sharedInstance].privateContext save:error];
    }
}

@end
