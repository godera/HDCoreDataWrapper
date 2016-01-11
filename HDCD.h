//
//  HDCD.h
//  agent
//
//  Created by LiMing on 14-6-24.
//  Copyright (c) 2014年 bangban. All rights reserved.
//
// 版权归 mmDAO 的作者，本人只是改了一下类的名字和方法的名字，以方便自我使用；订正了一些错误，删减了方法
// 三层结构分别是 privateContext <- mainContext <- aTempPrivateContext

#import <Foundation/Foundation.h>

typedef void (^SaveResult)(NSError *error);

@interface HDCD : NSObject

@property (readonly, strong, nonatomic) NSOperationQueue *queue; // 没实现
/// writer
@property (readonly ,strong, nonatomic) NSManagedObjectContext *privateContext;
/// excutor
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainContext;

+ (HDCD *)sharedInstance;

// called in -application:didFinishLaunchingWithOptions:
+ (void)setEnvironmentWithModelName:(NSString *)modelName sqliteFileName:(NSString *)fileName;
// called in -applicationWillTerminate:
+ (void)saveContext:(NSError **)error;

+ (NSManagedObjectContext *)createTempPrivateContext;

+ (NSError *)saveContextAsyncWithComplete:(SaveResult)complete;

@end
