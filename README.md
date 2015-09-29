# JKDBModel
FMDB的封装，极大简化你的数据库操作，对于自己的扩展也非常简单<br>
封装类的数据库操作思路与多数FMDB封装不同，是直接实体类对象来做增、删、改、查。<br>
代码中有比较详细的注释和讲解，有助于理解runtime的机制，如果能帮到你，麻烦给一个`star`。
对原作者的框架反射部分做了简化，便于理解，原作者的源码github地址在本文尾部。

# 为什么要封装这个类呢？
原项目使用的是sqlitepersistentobjects，多线程处理时，问题比较多<br>
多数FMDB框架功能比较多，代码量也比较大，但是很多功能不常用，而且也不便于理解，因此我考虑用简单易于理解的方式<br>
来封装一个适用于公司项目的轻量级小框架。<br>
因为项目需要在多线程下操作数据库，所以demo中的使用案例多数是多线程操作，但是单线程操作也适用。

# 特点
改进后的特点如下：<br>
1.自动创建数据库、自动创建数据库表。<br>
2.自动检测字段添加新字段。<br>
3.一行代码实现数据库的CURD操作。<br>
4.源码及其简单，易于理解和掌握。<br>
5.扩展自己的功能也非常得简单，容易。<br>
6.支持多线程，非线程阻塞。<br>
7.支持arc和mrc。<br>

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
# 更新
修改了创建表和字段检测功能方法。<br>
由于实际项目中，一个账号对应一个文件夹放数据库，经常会有切换账号登录的需求，在initialize创建数据库表，只执行一次，数据库不能保证一定创建，因此添加切换数据库功能，动态创建功能。 2015-08-25<br>
添加条件查询和删除的新方法：<br>
```
+ (instancetype)findFirstWithFormat:(NSString *)format, ...;

+ (NSArray *)findWithFormat:(NSString *)format, ...;

/** 通过条件删除 (多参数）--2 */
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...;
```
 更新于2015-09-08

# 提醒
SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL，我只做了少数类型的判断，<br>
如：int、unsigned int、short、unsigned short、BOOL，对象类型默认是字符串。<br>
当然你可以详细的把所有的类型判断都做出来，代码中有部分常用的表示符号，详细的可以查看apple 文档。<br>
理解代码比会使用代码更重要，望使用的时候先理解一下实现思路。<br>


# 鸣谢
动态获取Model的属性部分源自：https://github.com/li6185377/LKDaoBase <br>
增删改查封装思想源自：`SQLitePersistentObject`，与之前做Java时的数据库操作类似，更简易。

如果你有什么问题或者有更好的建议，请告知我，我会及时更正，修改。
