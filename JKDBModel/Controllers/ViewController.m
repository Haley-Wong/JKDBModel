//
//  ViewController.m
//  JKBaseModel
//
//  Created by zx_04 on 15/6/16.
//  Copyright (c) 2015年 joker. All rights reserved.
//

#import "ViewController.h"
#import "QueryTableViewController.h"
#import "User.h"
#import "Depart.h"
#import "JKDBHelper.h"

@implementation ViewController

#pragma mark - 插入数据
/** 创建多条子线程 */
- (IBAction)insertData:(id)sender {
    UIImage *image = [UIImage imageNamed:@"portrait"];
    NSData *imageData = UIImagePNGRepresentation(image);
    for (int i = 0; i < 10; i++) {
        User *user = [[User alloc] init];
        user.name = [NSString stringWithFormat:@"麻子%d",i];
        user.sex = @"男";
        user.age = 10+i;
        user.createTime = 1368082020;
        user.imageData = imageData;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user save];
        });
    }
}

/** 子线程一:插入多条用户数据 */
- (IBAction)insertData2:(id)sender {

    dispatch_queue_t q1 = dispatch_queue_create("queue1", NULL);
    dispatch_async(q1, ^{
        for (int i = 0; i < 5; ++i) {
            User *user = [[User alloc] init];
            user.name = @"赵五";
            user.sex = @"女";
            user.age = i+5;
            [user save];
        }
    });
}

- (IBAction)insertData3:(id)sender {
    for (int i = 0; i < 1000; ++i) {
        User *user = [[User alloc] init];
        user.name = @"张三";
        user.sex = @"男";
        user.age = i+5;
        [user save];
    }
}

/** 子线程三：事务插入数据 */
- (IBAction)insertData4:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 500; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"李四%d",i];
            user.age = 10+i;
            user.sex = @"女";
            [array addObject:user];
        }
        [User saveObjects:array];
    });
}

#pragma mark - 删除数据
/** 通过条件删除数据 */
- (IBAction)deleteData:(id)sender {
//    [User deleteObjectsByCriteria:@" WHERE pk < 10"];
    [User deleteObjectsWithFormat:@"Where %@ < %d",@"pk",10];
}

/** 创建多个线程删除数据 */
- (IBAction)deleteData2:(id)sender {
    for (int i = 0; i < 5; i++) {
        User *user = [[User alloc] init];
        user.pk = 1+i;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user deleteObject];
        });
    }
}

/** 子线程用事务删除数据 */
- (IBAction)deleteData3:(id)sender {

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 500; i++) {
            User *user = [[User alloc] init];
            user.pk = 501+i;
            [array addObject:user];
        }
        [User deleteObjects:array];
    });
}

#pragma mark - 修改数据
/** 创建多个线程更新数据 */
- (IBAction)updateData1:(id)sender {
    UIImage *image = [UIImage imageNamed:@"eay"];
    NSData *imageData = UIImagePNGRepresentation(image);
    for (int i = 0; i < 5; i++) {
        User *user = [[User alloc] init];
        user.name = [NSString stringWithFormat:@"更新%d",i];
        user.age = 120+i;
        user.pk = 5+i;
        user.imageData = imageData;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [user update];
        });
    }
}

/**单个子线程批量更新数据，利用事务 */
- (IBAction)updateData:(id)sender {
    dispatch_queue_t q3 = dispatch_queue_create("queue3", NULL);
    dispatch_async(q3, ^{
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < 500; i++) {
            User *user = [[User alloc] init];
            user.name = [NSString stringWithFormat:@"啊我哦%d",i];
            user.age = 88+i;
            user.pk = 10+i;
            [array addObject:user];
        }
        [User updateObjects:array];
    });
    
}

#pragma mark - 查询
/** 查询单条记录 */
- (IBAction)queryData1:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"第一条:%@",[User findFirstByCriteria:@" WHERE age = 20 "]);
    });
}

/**  条件查询多条记录 */
- (IBAction)queryData2:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"小于20岁:%@",[User findByCriteria:@" WHERE age < 20 "]);
    });
}

/** 查询全部数据 */
- (IBAction)queryData3:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"全部:%@",[User findAll]);
    });
}

/** 分页查询数据 */
- (IBAction)queryData:(id)sender {
    static int pk = 5;
    NSArray *array = [User findByCriteria:[NSString stringWithFormat:@" WHERE pk > %d limit 10",pk]];
    pk = ((User *)[array lastObject]).pk;
    NSLog(@"array:%@",array);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *title = @"查询";
    int type = 3;
    if ([segue.identifier isEqualToString:@"One"]) {
        title = @"查询一条数据";
        type = 1;
    } else if ([segue.identifier isEqualToString:@"Two"]){
        title = @"条件查询";
        type = 2;
    }else if ([segue.identifier isEqualToString:@"Three"]){
        title = @"查询全部";
        type = 3;
    }else if ([segue.identifier isEqualToString:@"Four"]){
        title = @"分页查询";
        type = 4;
    }
    
    QueryTableViewController *destVC = segue.destinationViewController;
    destVC.title = title;
    destVC.type = type;
}

- (IBAction)changeDire:(id)sender {
    [[JKDBHelper shareInstance] changeDBWithDirectoryName:@"Joker"];
}

//#pragma mark - 不使用FMDatabaseQueue，直接使用FMDatabase
//
//- (NSString *)getDBPath
//{
//    NSString* docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSFileManager *filemanage = [NSFileManager defaultManager];
//    docsdir = [docsdir stringByAppendingPathComponent:@"FMDBDemo"];
//    BOOL isDir;
//    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
//    if (!exit || !isDir) {
//        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"myDB.sqlite"];
//    return dbpath;
//}
//
///** 用db创建User表*/
//- (IBAction)dbCreateUserTable:(id)sender {
//    [User createUserTableByDB];
//}
//
///** 用db插入User数据*/
//- (IBAction)dbInsertData:(id)sender {
//    
//    //多线程插入数据
//    for (int i = 0; i < 5; i++) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            User *user = [[User alloc] init];
//            user.name = @"dbName一";
//            user.ID_no = [NSString stringWithFormat:@"%d",55555+i];
//            user.age = 555+i;
//            [user saveByDB];
//        });
//    }
//    
//    //利用事务插入数据
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSMutableArray *array = [NSMutableArray array];
//        for (int i = 0; i < 5; i++) {
//            User *user = [[User alloc] init];
//            user.name = @"db事务";
//            user.ID_no = [NSString stringWithFormat:@"%d",66666+i];
//            user.age = 66+i;
//            [array addObject:user];
//            [user release];
//        }
//        
//        [User saveObjectsByDB:array];
//    });
//}
//
///** 用db删除User数据*/
//- (IBAction)dbDeleteData:(id)sender {
//    //多线程插入数据
//    for (int i = 0; i < 5; i++) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            User *user = [[User alloc] init];
//            user.ID = i+5;
//            [user deleteObjectByDB];
//        });
//    }
//    
//    //利用事务删除数据
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSMutableArray *array = [NSMutableArray array];
//        for (int i = 0; i < 5; i++) {
//            User *user = [[User alloc] init];
//            user.ID = i+10;
//            [array addObject:user];
//            [user release];
//        }
//        
//        [User deleteObjectsByDB:array];
//    });
//}
//
///** 用db更新User数据*/
//- (IBAction)dbUpdateData:(id)sender {
//    //多线程插入数据
//    for (int i = 0; i < 5; i++) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            
//            User *user = [[User alloc] init];
//            user.name = @"db更新";
//            user.ID_no = [NSString stringWithFormat:@"%d",55+i];
//            user.age = 55555+i;
//            user.ID = i +1;
//            [user saveByDB];
//        });
//    }
//    
//    //利用事务更新数据
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSMutableArray *array = [NSMutableArray array];
//        for (int i = 0; i < 5; i++) {
//            User *user = [[User alloc] init];
//            user.name = @"db更新";
//            user.ID_no = [NSString stringWithFormat:@"%d",55+i];
//            user.age = 55555+i;
//            user.ID = i +10;
//            [array addObject:user];
//            [user release];
//        }
//        [User updateObjectsByDB:array];
//    });
//}
//
///** 用db查询User数据*/
//- (IBAction)dbQueryData:(id)sender {
//    //查询全部
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [User findAllByDB];
//    });
//    //条件查询
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [User findBySqlByDB:@" WHERE age = 20 "];
//    });
//    //查询单个
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [User findFirstBySqlByDB:@" WHERE age = 20 "];
//    });
//}

@end
