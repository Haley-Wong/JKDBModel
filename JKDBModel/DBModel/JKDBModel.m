//
//  JKBaseModel.m
//  JKBaseModel
//
//  Created by zx_04 on 15/6/27.
//  Copyright (c) 2015年 joker. All rights reserved.
//  github:https://github.com/Joker-King/JKDBModel

#import "JKDBModel.h"

#import "JKDBHelper.h"
#import "ZXCommonTool.h"

#import <objc/runtime.h>

@interface JKDBModel ()

// 获取这个属性值的详细类型
// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101

@property (nonatomic,strong)NSMutableArray * columnDetailTypes;

@end



@implementation JKDBModel

#pragma mark - override method
+ (void)initialize
{
    if (self != [JKDBModel self]) {
        [self createTable];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
        _columnDetailTypes = [[NSMutableArray alloc]  initWithArray:[dic objectForKey:@"detailType"]];
    }
    
    return self;
}

#pragma mark - base method
/**
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys
{
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSMutableArray *detailProTypes = [NSMutableArray array];
    
    NSArray *theTransients = [[self class] transients];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTransients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        [detailProTypes addObject:propertyType];
        /*
         各种符号对应类型，部分类型在新版SDK中有所变化，如long 和long long
         c char         C unsigned char
         i int          I unsigned int
         l long         L unsigned long
         s short        S unsigned short
         d double       D unsigned double
         f float        F unsigned float
         q long long    Q unsigned long long
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
         
         
         64位下long 和long long 都是Tq
         SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
         因为在项目中用的类型不多，故只考虑了少数类型
         */
        if ([propertyType hasPrefix:@"T@"]) {
            [proTypes addObject:SQLTEXT];
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            [proTypes addObject:SQLINTEGER];
        } else {
            [proTypes addObject:SQLREAL];
        }
        
    }
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",detailProTypes,@"detailType",nil];
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties
{
    NSDictionary *dict = [self.class getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSMutableArray * detailTypes = [NSMutableArray array];
    
    if ([self needPk]) {
        //这里添加了主键
        [proNames addObject:primaryId];
        [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQLINTEGER,PrimaryKey]];
    }
    
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    [detailTypes addObjectsFromArray:[dict objectForKey:@"detailType"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",detailTypes,@"detailType",nil];
}

/** 数据库中是否存在表 */
+ (BOOL)isExistInTable
{
    __block BOOL res = NO;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
         res = [db tableExists:tableName];
    }];
    return res;
}

/** 获取列名 */
+ (NSArray *)getColumns
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    NSMutableArray *columns = [NSMutableArray array];
     [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
         NSString *tableName = NSStringFromClass(self.class);
         FMResultSet *resultSet = [db getTableSchema:tableName];
         while ([resultSet next]) {
             NSString *column = [resultSet stringForColumn:@"name"];
             [columns addObject:column];
         }
         [resultSet close];
     }];
    return [columns copy];
}

/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable
{
    __block BOOL res = YES;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *columeAndType = [self.class getColumeAndTypeString];
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
        
        NSLog(@"建立表sql %@",sql);

        if (![db executeUpdate:sql]) {
            res = NO;
            *rollback = YES;
            return;
        };
        
        NSMutableArray *columns = [NSMutableArray array];
        
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        [resultSet close];

        NSDictionary *dict = [self.class getAllProperties];
        NSArray *properties = [dict objectForKey:@"name"];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
        //过滤数组
        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
        for (NSString *column in resultArray) {
            NSUInteger index = [properties indexOfObject:column];
            NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
            NSLog(@"更新表sql %@",sql);
            if (![db executeUpdate:sql]) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }
    }];
    
    return res;
}




#pragma mark - util method
+ (NSString *)getColumeAndTypeString
{
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

- (NSString *)description
{
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id  proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return [NSArray array];
}


+ (NSArray *)conditionArray{
    
    return @[];
}

+ (NSArray <NSString *> *)noNeedInSaveOrUpdateArray{
    return @[];
}

/**
 *  是否需要主键
 *  默认不需要
 *  @return YES 需要 No 不需要
 */
+ (BOOL)needPk{
    return NO;
}


/**
 *  valueForKey
 *  保存数据库的使用 array dictionary 转成 json string
 *  @return
 */
- (id)zx_valueForKey:(NSString *)key{
    id value = [self valueForKey:key];
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        value = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
    }
    return value;
}


#pragma mark - 以下 api 是 依赖 conditionArray 列名称的

/**
 * 根据条件 从数据库中查找
 *
 */
+ (NSArray *)zx_findByCriteria:(NSString *)criteria inDB:(FMDatabase *)db{
    
    NSMutableArray * users = [NSMutableArray array];
    
    NSString *tableName = NSStringFromClass(self.class);
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
    FMResultSet *resultSet = [db executeQuery:sql];
    while ([resultSet next]) {
        JKDBModel *model = [self fetchResult:resultSet];
        [users addObject:model];
    }
    [resultSet close];

    return users;
}

#pragma mark - 解析从数据库 得到的结果
+ (JKDBModel *)fetchResult:(FMResultSet *)resultSet{

    JKDBModel *model = [[self.class alloc] init];
    for (int i=0; i< model.columeNames.count; i++) {
        NSString *columeName = [model.columeNames objectAtIndex:i];
        NSString *columeType = [model.columeTypes objectAtIndex:i];
        NSString *detailType  =[model.columnDetailTypes objectAtIndex:i];
        
        //TODO  注意这里的转换
        if ([columeType isEqualToString:SQLTEXT]) {
            
            NSString * result = [resultSet stringForColumn:columeName];
            id obj;
            if ([detailType hasPrefix:@"T@\"NSMutableArray\""]||[detailType hasPrefix:@"T@\"NSArray\""]) {
                // 数组
                obj = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            }
            else if([detailType hasPrefix:@"T@\"NSMutableDictionary\""]||[detailType hasPrefix:@"T@\"NSDictionary\""]){
                // 字典
                obj = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            }else{
                obj = result;
            }
            
            [model setValue:obj forKey:columeName];
            
        } else {
            [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
        }
    }
    return model;
}


/**
 * 根据model  从数据库中查找 是否包含model 指定条件的 数据
 *
 */
+ (NSArray *)zx_findFromTableByModel:(JKDBModel *)dbModel inDB:(FMDatabase *)db{

    if ([ZXCommonTool zx_arrayIsEmpty:[self conditionArray]]) {
        return @[];
    }
    NSString * sql = [self zx_findWhereSqlByModel:dbModel];
    
    return [self zx_findByCriteria:sql inDB:db];
}

/**
 * 根据model 指定条件数组 生成查找 where 语句
 *
 */
+ (NSString *)zx_findWhereSqlByModel:(JKDBModel *)dbModel{
    
    if ([ZXCommonTool zx_arrayIsEmpty:[self conditionArray]]) {
        return @"";
    }
    NSArray * conditionary = [[self class] conditionArray];
    NSMutableString * sql = [NSMutableString stringWithString:@"WHERE"];
    NSString * columnValue;
    for (NSString * columnName in  conditionary) {
        columnValue = [dbModel zx_valueForKey:columnName];
        [sql appendFormat:@" %@=%@ and",columnName,columnValue];
    }
    // 删除结尾的 " and"
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 4, 4)];
    return sql;
}


/**
 *  批量插入 或 更新  依据依赖关系
 *
 */
+ (BOOL)zx_saveOrUpdateObjects:(NSArray *)array{
    if ([ZXCommonTool zx_arrayIsEmpty:array]) {
        return NO;
    }
    
    //判断是否是JKBaseModel的子类 如果存在非 JKBaseModel 子类 就有问题了
    for (JKDBModel *model in array) {
        if (![model isKindOfClass:[JKDBModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSArray * noNeedArray = [[self class] noNeedInSaveOrUpdateArray];
        
        for (JKDBModel *model in array) {
            
            NSString *tableName = NSStringFromClass(model.class);
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray  array];
            
            NSString *sql;
            BOOL flag;
            // 判断是否存在 如果存在 则是更新
            NSArray * results = [self zx_findFromTableByModel:model inDB:db];
            
            if ([ZXCommonTool zx_arrayIsEmpty:results]) {
                //insert
                for (int i = 0; i < model.columeNames.count; i++) {
                    NSString *proname = [model.columeNames objectAtIndex:i];
                    if ([proname isEqualToString:primaryId]) {
                        continue;
                    }
                    [keyString appendFormat:@"%@,", proname];
                    [valueString appendString:@"?,"];
                    id value = [model zx_valueForKey:proname];
                    if (!value) {
                        value = @"";
                    }
                    [insertValues addObject:value];
                    
                }
                
                [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
                [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
                sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
                NSLog(@"插入的sql %@",sql);
                flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            }else{
                //update
                for (int i = 0; i < model.columeNames.count; i++) {
                    NSString *proname = [model.columeNames objectAtIndex:i];
                    if ([proname isEqualToString:primaryId]) {
                        continue;
                    }
                    if ([noNeedArray containsObject:proname]) {
                        continue;
                    }
                    
                    id value = [model zx_valueForKey:proname];
                    if (!value) {
                        value = @"";
                    }
                    [insertValues addObject:value];
                    [keyString appendFormat:@"%@ = ?,", proname];
                }
                [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
                valueString = [self zx_findWhereSqlByModel:model];

                sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ %@", tableName, keyString, valueString];
                NSLog(@"更新的sql %@",sql);
                flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            }
            
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            NSLog(flag?@"插入|更新 成功":@"插入｜更新 失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}


/**
 *  单个 插入
 *  @return YES 成功，NO 失败
 */
- (BOOL)zx_insert{
    
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    NSString * sql;
    //insert
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
            continue;
        }
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [self zx_valueForKey:proname];
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
    NSLog(@"插入的sql %@",sql);
    
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
   [jkDB.dbQueue inDatabase:^(FMDatabase *db){
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        NSLog(res?@"单个插入成功":@"单个插入失败");
    }];
    return res;
}


#pragma mark - 更新 自定义列名

/**
 *  单个更新 NoNeedInSaveOrUpdateArray
 *
 *  @return
 */
- (BOOL)zx_updateNoNeedInSaveOrUpdateArray{

    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSArray * noNeedArray = [[self class] noNeedInSaveOrUpdateArray];
        NSString *tableName = NSStringFromClass(self.class);
        
        NSMutableString *keyString = [NSMutableString string];  //update
        NSMutableString *valueString = [NSMutableString string];//where
        NSMutableArray *updateValues = [NSMutableArray  array];
        NSString *sql;
        
        //update
        for (int i = 0; i < noNeedArray.count; i++) {
            NSString *proname = noNeedArray[i];
            if ([proname isEqualToString:primaryId]) {
                continue;
            }
            id value = [self zx_valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
            [keyString appendFormat:@"%@ = ?,", proname];
        }
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        valueString = [self.class zx_findWhereSqlByModel:self];
        
        sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ %@", tableName, keyString, valueString];
        NSLog(@"更新noneed的sql %@",sql);
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        if (res) {
            NSLog(@"更新noneed成功");
        }
    }];
    return res;
}

/**
 *  子类可以 override  这些 来更新 特定列名
 *  单独更新
 *
 *  @param sql
 */
- (BOOL)zx_updateWithSql:(NSString *)sql{

    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSLog(@"单个自定义更新的sql %@",sql);
        res = [db executeUpdate:sql];
        if (res) {
            NSLog(@"单个自定义更新成功");
        }else{
            NSLog(@"单个自定义更新失败");
        }
    }];
    return res;
}


#pragma mark - 查找 从数据库中

+ (NSArray *)zx_findAll{

    NSLog(@"jkdb---%s",__func__);
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            
            JKDBModel *model = [self fetchResult:resultSet];
            model.comefromDB = YES;
            [users addObject:model];
        }
        [resultSet close];

    }];
    return users;
}


- (instancetype )zx_find{
    
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block JKDBModel * model = nil;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSArray * result = [self.class zx_findFromTableByModel:self inDB:db];
        if (result.count) {
            model = result[0];
            model.comefromDB = YES;
        }else{
           
        }
       
    }];
    return model;
}



#pragma mark - DEPRECATED custom
#pragma mark - 以下是 通过主键 来判断区分的 

/** 批量保存用户对象 */
+ (BOOL)saveObjects:(NSArray *)array
{
    //判断是否是JKBaseModel的子类
    for (JKDBModel *model in array) {
        if (![model isKindOfClass:[JKDBModel class]]) {
            return NO;
        }
    }
    __block BOOL res = YES;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (JKDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray  array];
            
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,", proname];
                [valueString appendString:@"?,"];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            NSLog(flag?@"插入成功":@"插入失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}


- (BOOL)save
{
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
            continue;
        }
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [self valueForKey:proname];
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
        NSLog(res?@"插入成功":@"插入失败");
    }];
    return res;
}




- (BOOL)saveOrUpdate
{
    id primaryValue = [self valueForKey:primaryId];
    if ([primaryValue intValue] <= 0) {
        return [self save];
    }
    return [self update];
}

- (BOOL)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue
{
    id record = [self.class findFirstByCriteria:[NSString stringWithFormat:@"where %@ = %@",columnName,columnValue]];
    if (record) {
        id primaryValue = [record valueForKey:primaryId]; //取到了主键PK
        if ([primaryValue intValue] <= 0) {
            return [self save];
        }else{
            self.pk = [primaryValue integerValue];
            return [self update];
        }
    }else{
        return [self save];
    }
}




/** 更新单个对象 */
- (BOOL)update
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
        for (int i = 0; i < self.columeNames.count; i++) {
            NSString *proname = [self.columeNames objectAtIndex:i];
            if ([proname isEqualToString:primaryId]) {
                continue;
            }
            [keyString appendFormat:@" %@=?,", proname];
            id value = [self valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
        }
        
        //删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, primaryId];
        [updateValues addObject:primaryValue];
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}

/** 批量更新用户对象*/
+ (BOOL)updateObjects:(NSArray *)array
{
    for (JKDBModel *model in array) {
        if (![model isKindOfClass:[JKDBModel class]]) {
            return NO;
        }
    }
    __block BOOL res = YES;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (JKDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                res = NO;
                *rollback = YES;
                return;
            }
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@" %@=?,", proname];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [updateValues addObject:value];
            }
            
            //删除最后那个逗号
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;", tableName, keyString, primaryId];
            [updateValues addObject:primaryValue];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag?@"更新成功":@"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}



/** 删除单个对象 */
- (BOOL)deleteObject
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
         NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

/** 批量删除用户对象 */
+ (BOOL)deleteObjects:(NSArray *)array
{
    for (JKDBModel *model in array) {
        if (![model isKindOfClass:[JKDBModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (JKDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                return ;
            }
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
             NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName,criteria];
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

/** 通过条件删除 (多参数）--2 */
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self deleteObjectsByCriteria:criteria];
}

/** 清空表 */
+ (BOOL)clearTable
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    return res;
}

/** 查询全部数据 */
+ (NSArray *)findAll
{
     NSLog(@"jkdb---%s",__func__);
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            JKDBModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                 NSString *columeName = [model.columeNames objectAtIndex:i];
                 NSString *columeType = [model.columeTypes objectAtIndex:i];
                 if ([columeType isEqualToString:SQLTEXT]) {
                     [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                 } else {
                     [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                 }
             }
            [users addObject:model];
            FMDBRelease(model);
        }
        [resultSet close];
    }];
    
    return users;
}

+ (instancetype)findFirstWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findFirstByCriteria:criteria];
}

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria
{
    NSArray *results = [self.class findByCriteria:criteria];
    if (results.count < 1) {
        return nil;
    }
    
    return [results firstObject];
}

+ (instancetype)findByPK:(int)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%d",primaryId,inPk];
    return [self findFirstByCriteria:condition];
}

+ (NSArray *)findWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findByCriteria:criteria];
}

/** 通过条件查找数据 */
+ (NSArray *)findByCriteria:(NSString *)criteria
{
    JKDBHelper *jkDB = [JKDBHelper shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            JKDBModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
        [resultSet close];
    }];
    
    return users;
}



@end
