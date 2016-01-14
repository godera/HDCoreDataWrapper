//
//  NSManagedObject+HDCD.m
//  agent
//
//  Created by LiMing on 14-6-24.
//  Copyright (c) 2014年 bangban. All rights reserved.
//

#import "NSManagedObject+HDCD.h"

@implementation NSManagedObject (HDCD)

+ (NSError *)saveAsyncWithCompletion:(SaveResult)completion {
    return [HDCD saveContextAsyncWithCompletion:completion];
}

+ (__kindof NSManagedObject *)createNew {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:[HDCD mainContext]];
}

+ (void)deleteObject:(NSManagedObject *)object {
    [[HDCD mainContext] deleteObject:object];
}

+ (__kindof NSManagedObject *)fetchTheOneWithPredicate:(NSPredicate *)predicate{
    NSManagedObjectContext *ctx = [HDCD mainContext];
    NSFetchRequest *fetchRequest = [self createFetchRequestWithContext:ctx predicate:predicate orderBy:nil offset:0 limit:0];
    NSError* error = nil;
    NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ErrorLog(@"fetchTheOneWithPredicate error: %@", error.localizedDescription);
        return nil;
    }
    if (results.count == 0) {
        return nil;
    }
    if (results.count > 1) {
        [results enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx > 0) {
                [self deleteObject:obj];
            }
        }];
    }
    return results[0];
}

+(void)fetchTheOneAsyncWithPredicate:(NSPredicate *)predicate complete:(TheOneResult)complete{
    NSManagedObjectContext *ctx = [HDCD createTempPrivateContext];
    [ctx performBlock:^{
        NSFetchRequest *fetchRequest = [self createFetchRequestWithContext:ctx predicate:predicate orderBy:nil offset:0 limit:0];
        NSError* error = nil;
        NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
        if (error) {
            ErrorLog(@"fetchTheOneAsyncWithPredicate error: %@", error.localizedDescription);
            [[HDCD mainContext] performBlock:^{
                complete(nil, error);
            }];
            return;
        }
        if (results.count == 0) {
            [[HDCD mainContext] performBlock:^{
                complete(nil, nil);
            }];
            return;
        }
        if (results.count > 1) {
            [results enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx > 0) {
                    [self deleteObject:obj];
                }
            }];
        }
        NSManagedObjectID *objId = ((NSManagedObject*)results[0]).objectID;
        [[HDCD mainContext] performBlock:^{
            __kindof NSManagedObject *object = [[HDCD mainContext] objectWithID:objId];
            if (complete) {
                complete(object, nil);
            }
        }];
    }];
}

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit {
    NSManagedObjectContext *ctx = [HDCD mainContext];
    NSFetchRequest *fetchRequest = [self createFetchRequestWithContext:ctx predicate:predicate orderBy:orders offset:offset limit:limit];
    NSError *error = nil;
    NSArray *results = [ctx executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ErrorLog(@"fetchWithPredicate error: %@", error.localizedDescription);
    }
    return results;
}

+ (void)fetchAsyncWithPredicate:(NSPredicate *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit complete:(ListResult)complete {
    NSManagedObjectContext *ctx = [HDCD createTempPrivateContext];
    [ctx performBlock:^{
        NSFetchRequest *fetchRequest = [self createFetchRequestWithContext:ctx predicate:predicate orderBy:orders offset:offset limit:limit];
        NSError* error = nil;
        NSArray* results = [ctx executeFetchRequest:fetchRequest error:&error];
        if (error) {
            ErrorLog(@"fetchAsyncWithPredicate error: %@", error.localizedDescription);
        }
        NSMutableArray *result_ids = [[NSMutableArray alloc] init];
        for (NSManagedObject *item  in results) {
            [result_ids addObject2:item.objectID];
        }
        [[HDCD mainContext] performBlock:^{
            NSMutableArray *final_results = [[NSMutableArray alloc] init];
            for (NSManagedObjectID *oid in result_ids) {
                [final_results addObject2:[[HDCD mainContext] objectWithID:oid]];
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
        [[HDCD mainContext] performBlock:^{
            NSMutableArray *objArray = [[NSMutableArray alloc] init];
            for (NSManagedObjectID *anObjID in objectIdArray) {
                [objArray addObject2:[[HDCD mainContext] objectWithID:anObjID]];
            }
            if (complete) {
                complete([objArray copy], nil);
            }
        }];
    }];
}

/// MARK: 查询请求的构造，注意：predicate 是字串
+ (NSFetchRequest *)createFetchRequestWithContext:(NSManagedObjectContext *)ctx predicate:(NSPredicate *)predicate orderBy:(NSArray *)orders offset:(NSUInteger)offset limit:(NSUInteger)limit
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:ctx]];
    if (predicate) {
        fetchRequest.predicate = predicate;
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
