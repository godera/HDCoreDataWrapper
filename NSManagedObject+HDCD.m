//
//  NSManagedObject+HDCD.m
//  agent
//
//  Created by LiMing on 14-6-24.
//  Copyright (c) 2014年 bangban. All rights reserved.
//

#import "NSManagedObject+HDCD.h"

@implementation NSManagedObject (HDCD)

+ (NSError *)saveAsyncWithComplete:(SaveResult)complete {
    return [HDCD saveContextAsyncWithComplete:complete];
}

+ (__kindof NSManagedObject *)createNew {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class]) inManagedObjectContext:[HDCD sharedInstance].mainContext];
}

+ (void)deleteObject:(NSManagedObject *)object {
    [[HDCD sharedInstance].mainContext deleteObject:object];
}

+ (__kindof NSManagedObject *)fetchTheOneWithPredicate:(NSString *)predicate{
    NSManagedObjectContext *ctx = [HDCD sharedInstance].mainContext;
    NSFetchRequest *fetchRequest = [self makeFetchRequestWithContext:ctx predicate:predicate orderBy:nil offset:0 limit:0];
    NSError* error = nil;
    NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"fetchTheOneWithPredicate error: %@", error.localizedDescription);
        return nil;
    }
    if (results.count != 1) {
        return nil;
    }
    return results[0];
}

+(void)fetchTheOneAsyncWithPredicate:(NSString *)predicate complete:(TheOneResult)complete{
    NSManagedObjectContext *ctx = [HDCD createTempPrivateContext];
    [ctx performBlock:^{
        NSFetchRequest *fetchRequest = [self makeFetchRequestWithContext:ctx predicate:predicate orderBy:nil offset:0 limit:0];
        NSError* error = nil;
        NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"fetchTheOneAsyncWithPredicate error: %@", error.localizedDescription);
            [[HDCD sharedInstance].mainContext performBlock:^{
                complete(nil, error);
            }];
            return;
        }
        if (results.count != 1) {
            [[HDCD sharedInstance].mainContext performBlock:^{
                complete(nil, nil);
            }];
            return;
        }
        NSManagedObjectID *objId = ((NSManagedObject*)results[0]).objectID;
        [[HDCD sharedInstance].mainContext performBlock:^{
            __kindof NSManagedObject *object = [[HDCD sharedInstance].mainContext objectWithID:objId];
            if (complete) {
                complete(object, nil);
            }
        }];
    }];
}

+ (NSArray *)fetchWithPredicate:(NSString *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit {
    NSManagedObjectContext *ctx = [HDCD sharedInstance].mainContext;
    NSFetchRequest *fetchRequest = [self makeFetchRequestWithContext:ctx predicate:predicate orderBy:orders offset:offset limit:limit];
    NSError *error = nil;
    NSArray *results = [ctx executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"fetchWithPredicate error: %@", error.localizedDescription);
    }
    return results;
}

+ (void)fetchAsyncWithPredicate:(NSString *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit complete:(ListResult)complete {
    NSManagedObjectContext *ctx = [HDCD createTempPrivateContext];
    [ctx performBlock:^{
        NSFetchRequest *fetchRequest = [self makeFetchRequestWithContext:ctx predicate:predicate orderBy:orders offset:offset limit:limit];
        NSError* error = nil;
        NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
        if (error) {
            NSLog(@"fetchAsyncWithPredicate error: %@", error.localizedDescription);
        }
        NSMutableArray *result_ids = [[NSMutableArray alloc] init];
        for (NSManagedObject *item  in results) {
            [result_ids addObject2:item.objectID];
        }
        [[HDCD sharedInstance].mainContext performBlock:^{
            NSMutableArray *final_results = [[NSMutableArray alloc] init];
            for (NSManagedObjectID *oid in result_ids) {
                [final_results addObject2:[[HDCD sharedInstance].mainContext objectWithID:oid]];
            }
            if (complete) {
                complete(final_results, error);
            }
        }];
    }];
}

+ (void)fetchAsyncWithBlock:(FetchBlock)fetchBlock complete:(ListResult)complete {
    NSManagedObjectContext *ctx = [HDCD createTempPrivateContext];
    [ctx performBlock:^{
        NSArray *resultList = fetchBlock(ctx, NSStringFromClass([self class]));
        
        NSMutableArray *idArray = [[NSMutableArray alloc] init];
        for (NSManagedObject *obj in resultList) {
            [idArray addObject2:obj.objectID];
        }
        NSArray *objectIdArray = [idArray copy];
        [[HDCD sharedInstance].mainContext performBlock:^{
            NSMutableArray *objArray = [[NSMutableArray alloc] init];
            for (NSManagedObjectID *anObjID in objectIdArray) {
                [objArray addObject2:[[HDCD sharedInstance].mainContext objectWithID:anObjID]];
            }
            if (complete) {
                complete([objArray copy], nil);
            }
        }];
    }];
}

#pragma mark - 查询请求建立的方法
+ (NSFetchRequest *)makeFetchRequestWithContext:(NSManagedObjectContext *)ctx predicate:(NSString *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:ctx]];
    if (predicate) {
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:predicate]];
    }
    NSMutableArray *orderArray = [[NSMutableArray alloc] init];
    if (orders != nil) {
        for (NSString *order in orders) {
            NSSortDescriptor *orderDesc = nil;
            if ([[order substringToIndex:1] isEqualToString:@"-"]) {
                orderDesc = [[NSSortDescriptor alloc] initWithKey:[order substringFromIndex:1] ascending:NO];
            }else{
                orderDesc = [[NSSortDescriptor alloc] initWithKey:order ascending:YES];
            }
            [orderArray addObject2:orderDesc];
        }
        [fetchRequest setSortDescriptors:orderArray];
    }
    if (offset > 0) {
        [fetchRequest setFetchOffset:offset];
    }
    if (limit > 0) {
        [fetchRequest setFetchLimit:limit];
    }
    return fetchRequest;
}

@end
