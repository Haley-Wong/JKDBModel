//
//  JKBaseModel.h
//  JKBaseModel
//
//  Created by zx_04 on 15/6/27.
//  Copyright (c) 2015年 joker. All rights reserved.
//  github:https://github.com/Joker-King/JKDBModel

#import <Foundation/Foundation.h>



/** SQLite五种数据类型 */
#define SQLTEXT     @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL     @"REAL"
#define SQLBLOB     @"BLOB"
#define SQLNULL     @"NULL"
#define PrimaryKey  @"primary key"

#define primaryId   @"pk"



/**
 * 
 *
 *  数据 model 继承自 JKDBModel
 *  在这里 直接维护 数据库的操作
 *
 *  note： armv6 v7 时候的 几种基本类型 对应数据库 字段类型
 *  大部分情况下，我们并不需要 主键.
 *
 *  tips:
    1.主键 pk ,查找什么的完全依赖主键pk，这是一个大问题。这里对是否需要创建pk 自定义 ，默认不需要
 *  2.根据 conditionArray 指定的 列名称，进行条件判断
 *  3.列名称为空的 不会建表
 *
 *  更多的 自定义功能，可以直接 本类进行修改
 *
 *  https://github.com/Haley-Wong/JKDBModel
 */


@interface JKDBModel : NSObject

// 这个主键 没有什么实际作用
// 起主键名字 是很困难的，
/** 主键 id */
@property (nonatomic, assign)   int        pk;

/** 列名  */
@property (retain, readonly, nonatomic) NSMutableArray         *columeNames;
/** 列类型 */
@property (retain, readonly, nonatomic) NSMutableArray         *columeTypes;

/**
 *  从数据库返回的model  YES
 */
@property (nonatomic,assign)BOOL comefromDB;

/** 
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys;

/** 获取所有属性，包括主键 ,如果不需要主键，则不包含*/
+ (NSDictionary *)getAllProperties;

/** 数据库中是否存在表 */
+ (BOOL)isExistInTable;

/** 表中的字段*/
+ (NSArray *)getColumns;


/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable;


#pragma mark - override

/**< 需要被overrite 的方法 
 
 require
     update delete select 的判断依据字段
 */
+ (NSArray <NSString *> *)conditionArray;

/**< 保存的时候 执行 update的 不能｜不需要 进行修改的 列名字
     如果overide 了这个api ，后续需要更新这些字断 可以使用
    
    zx_updateNoNeedInSaveOrUpdateArray ||
    zx_updateWithSql
 
 option
 
 */
+ (NSArray <NSString *> *)noNeedInSaveOrUpdateArray;


/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
    
 option
 */
+ (NSArray <NSString *> *)transients;

/**
 *  是否需要主键 
 *  默认不需要
 *  @return YES 需要 No 不需要
 */
+ (BOOL)needPk;


#pragma mark - for Common
#pragma mark -  以下api 是 依赖 conditionArray 条件的列字段

/** 通过依赖关系 批量保存 或者 更新 数据 */
+ (BOOL)zx_saveOrUpdateObjects:(NSArray *)array;

/**
 *  单个 插入
 *  @return YES 成功，NO 失败
 */
- (BOOL)zx_insert;


/**
 *  单个更新
 */
- (BOOL)zx_updateNoNeedInSaveOrUpdateArray;

/**
 *  子类可以 override  这些 来更新 特定列名  
 *  单独更新
 *
 *  @param sql
 */
- (BOOL)zx_updateWithSql:(NSString *)sql;


#pragma mark - 查找 从数据库中

/**
 *  从数据库找到所有的 model
 *
 *  @return
 */
+ (NSArray *)zx_findAll;

/**
 *  根据model 和 依赖关系  直接查找
 *
 *  @return 返回 找到返回model ，没有 返回nil
 */
- (instancetype )zx_find;






#pragma mark - DEPRECATED
#pragma mark - 以下api 是依赖主键pk的 


/** 保存或更新
 * 如果不存在主键，保存，
 * 有主键，则更新
 */
- (BOOL)saveOrUpdate;


/** 批量保存数据 */
+ (BOOL)saveObjects:(NSArray *)array;



/** 保存或更新
 * 如果根据特定的列数据可以获取记录，则更新，
 * 没有记录，则保存
 */
- (BOOL)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue;


/** 保存单个数据 */
- (BOOL)save;


/** 更新单个数据 */
- (BOOL)update;

/** 批量更新数据*/
+ (BOOL)updateObjects:(NSArray *)array;


/** 删除单个数据 */
- (BOOL)deleteObject;


/** 批量删除数据 */
+ (BOOL)deleteObjects:(NSArray *)array;

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria;

/** 通过条件删除 (多参数）--2 */
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...;

/** 清空表 */
+ (BOOL)clearTable;

/** 查询全部数据 */
+ (NSArray *)findAll;

/** 通过主键查询 */
+ (instancetype)findByPK:(int)inPk;

+ (instancetype)findFirstWithFormat:(NSString *)format, ...;

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria;

+ (NSArray *)findWithFormat:(NSString *)format, ...;

/** 通过条件查找数据 
 * 这样可以进行分页查询 @" WHERE pk > 5 limit 10"
 */
+ (NSArray *)findByCriteria:(NSString *)criteria;



#pragma mark - for custom


@end
