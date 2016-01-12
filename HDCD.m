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

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;

 // saving context
@property (strong, nonatomic) NSManagedObjectContext *privateContext;

 // UI context
@property (strong, nonatomic) NSManagedObjectContext *mainContext;

 // data context
+ (NSManagedObjectContext *)createTempPrivateContext;

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

+ (void)initEnvironmentWithModelName:(NSString *)modelName sqliteFileName:(NSString *)fileName {
    [[self sharedInstance] initEnvironmentWithModelName:modelName sqliteFileName:fileName];
}
- (void)initEnvironmentWithModelName:(NSString *)modelName sqliteFileName:(NSString *)fileName {
    _modelName = modelName;
    _sqliteFileName = fileName;
    [self initCoreDataStack];
}

- (void)initCoreDataStack
{
    // 1、初始化 model
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    self.managedObjectModel = managedObjectModel;
    
    // 2、初始化 coordinator
    // 这里把数据库文件存储在了 Documents 目录，然后做了 iCloud 上传屏蔽
    NSURL *documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *dbFileURL = [documentURL URLByAppendingPathComponent:_sqliteFileName];
    NSLog(@"core data db URL = %@", dbFileURL);
    
    NSError *error = nil;
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:dbFileURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [dbFileURL skipICloudBackup];
    
    // 3、初始化 子母context
    if (persistentStoreCoordinator != nil) {
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        privateContext.persistentStoreCoordinator = persistentStoreCoordinator;
        self.privateContext = privateContext;
        
        NSManagedObjectContext *mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        mainContext.parentContext = privateContext;
        self.mainContext = mainContext;
    }

}

+ (NSManagedObjectContext *)privateContext {
    return [self sharedInstance].privateContext;
}

+ (NSManagedObjectContext *)mainContext {
    return [self sharedInstance].mainContext;
}

+ (NSManagedObjectContext *)createTempPrivateContext {
    NSManagedObjectContext *ctx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    ctx.parentContext = [self sharedInstance].mainContext;
    return ctx;
}

+ (NSManagedObjectModel *)managedObjectModel {
    return [self sharedInstance].managedObjectModel;
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
