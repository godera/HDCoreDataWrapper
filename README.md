HDCoreDataWrapper
====================

### 从此又能和CoreData愉快地玩耍啦

### 1、引入头文件
```
    #import "NSManagedObject+HDCD.h"
```

### 2、初始化和中断保存
```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [HDCD setEnvironmentWithModelName:@"HDCoreDataWrapper" sqliteFileName:@"HDCoreDataWrapper.sqlite"];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [HDCD saveContext:nil];
}
```

### 3、增加一个NSManagedObject
```objectivec
Entity *task = [Entity createNew];
task.task_id = @([self genId]);
task.title = _txInputBox.text;
task.detail = @"[not sure]";
task.done = @NO;
```

### 4、删除一个NSManagedObject
```objectivec
Entity *task = _dataArray[indexPath.row];
[Entity deleteObject:task];
```

### 5、保存变动
```objectivec
[Entity saveAsyncWithComplete:^(NSError *error) {
    _txInputBox.text = @"";
    [self fetchEntitys];
}];
```

#### 6、同步查询
```
NSArray *results = [Entity fetchWithPredicate:@"task_id>10" orderBy:@[@"task_id"] offset:0 limit:0];
```

#### 7、异步查询
```
[Entity fetchAsyncWithPredicate:@"task_id>10" orderBy:@[@"task_id"] offset:0 limit:0 complete:^(NSArray *result, NSError *error) {
    _dataArray = result;
    [_mainTable reloadData]; //reload table view
}];
```

### 8、异步自由查询
```
[Entity fetchAsyncWithBlock:^id(NSManagedObjectContext *ctx, NSString *className) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:className];
        [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"task_id" ascending:YES]]];
        NSError *error;
        NSArray *dataArray = [ctx executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"error = %@",error.localizedDescription);
            return nil;
        }else{
            return dataArray;
        }

    } complete:^(NSArray *result, NSError *error) {
        _dataArray = result;
        [_mainTable reloadData];
    }];
```
