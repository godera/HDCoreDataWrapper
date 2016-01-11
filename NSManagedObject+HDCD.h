//
//  NSManagedObject+HDCD.h
//  agent
//
//  Created by LiMing on 14-6-24.
//  Copyright (c) 2014年 bangban. All rights reserved.
//

typedef void (^TheOneResult)(__kindof NSManagedObject *theOne, NSError *error);
typedef void (^ListResult)(NSArray *list, NSError *error);
typedef NSArray * (^FetchBlock)(NSManagedObjectContext *ctx, NSString *className);

#import <CoreData/CoreData.h>
#import "HDCD.h"

@interface NSManagedObject (HDCD)

 // 增、删、改 内容变动后 想将其存储到数据库 都要执行此 save 方法
+ (NSError*)saveAsyncWithComplete:(SaveResult)complete;

 // 增
+ (__kindof NSManagedObject *)createNew;

 // 删
+ (void)deleteObject:(NSManagedObject *)object;

 // 同步改：同步查询到唯一的那个 NSManagedObject 对象，然后对其进行修改
+ (__kindof NSManagedObject *)fetchTheOneWithPredicate:(NSString *)predicate;

 // 异步改：异步查询到唯一的那个 NSManagedObject 对象，然后对其进行修改
+ (void)fetchTheOneAsyncWithPredicate:(NSString *)predicate complete:(TheOneResult)complete;

/* 同步查询
 * @orders 是排序字段的组合，如果在字段前面加【-】号即代表降序，默认升序
 * @offset 0代表不设定
 * @limit 0代表不设定
 */
+ (NSArray *)fetchWithPredicate:(NSString *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit;

/* 异步查询
 * @orders 是排序字段的组合，如果在字段前面加【-】号即代表降序，默认升序
 * @offset 0代表不设定
 * @limit 0代表不设定
 */
+ (void)fetchAsyncWithPredicate:(NSString *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit complete:(ListResult)complete;

 // 异步自由查询
+ (void)fetchAsyncWithBlock:(FetchBlock)fetchBlock complete:(ListResult)complete;

@end
