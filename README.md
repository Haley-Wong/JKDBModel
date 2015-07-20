# JKDBModel
FMDB的封装，极大简化你的数据库操作，对于自己的扩展也非常简单<br>
封装类的数据库操作思路与多数FMDB封装不同，是直接实体类对象来做增、删、改、查。<br>
对原作者的框架反射部分做了简化，便于理解，原作者的源码github地址在本文尾部。

# why 为什么用它
该框架是本人在项目中用到的对FMDB的封装，它的特点如下：<br>
1.自动创建数据库、自动创建数据库表。<br>
2.自动检测字段添加新字段。<br>
3.一行代码实现数据库的CURD操作。<br>
4.源码及其简单，易于理解和掌握。<br>
5.扩展自己的功能也非常得简单，容易。<br>
6.支持arc和mrc。<br>

# how 怎么使用JKDBModel
使用JKDBModel非常的简单，只需要将FMDB和DBModel拖入项目中，然后添加`libsqlite3.dylib`<br>
然后让你的实体类继承自JKDBModel，你的实体类就具备了操作数据库的功能。

# demo中有CURD演示操作
效果图<br>
![](http://cc.cocimg.com/bbs/attachment/postcate/topic/16/313017_189_ccde14372754000f44c3edbcc68c9.png "CURD示例")

## CURD操作
操作都有保存和批量保存两种方式。<br>
例如<br>
保存操作：`[user save]`<br>
批量保存：`[User saveObjects:array]`

# 数据库操作api
```Objective-C
/** 数据库中是否存在表 */
+ (BOOL)isExistInTable;
/** 保存或更新
 * 如果不存在主键，保存，
 * 有主键，则更新
 */
- (BOOL)saveOrUpdate;
/** 保存单个数据 */
- (BOOL)save;
/** 批量保存数据 */
+ (BOOL)saveObjects:(NSArray *)array;
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
/** 清空表 */
+ (BOOL)clearTable;

/** 查询全部数据 */
+ (NSArray *)findAll;

/** 通过主键查询 */
+ (instancetype)findByPK:(int)inPk;

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria;

/** 通过条件查找数据 
 * 这样可以进行分页查询 @" WHERE pk > 5 limit 10"
 */
+ (NSArray *)findByCriteria:(NSString *)criteria;
/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable;

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写 
 */
+ (NSArray *)transients;
```
# 鸣谢
感谢原作者：https://github.com/li6185377/LKDaoBase <br>

如果你有什么问题或者有好的建议，请告知我。
