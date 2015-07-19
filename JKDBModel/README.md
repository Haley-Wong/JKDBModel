# JKDBModel
FMDB数据库操作的封装，继承JKDBModel后一行代码实现CURD操作。<br>
因为项目中主要是多线程中操作数据库，所以Demo里都是多线程操作的方式，该类也可以在主线程中使用。<br>
依赖FMDB，支持ARC和非ARC。<br>
不需要实体与数据库映射的属性，添加到transients数组即可。<br>
#怎么使用？
将项目中DBModel和FMDB两个文件夹拖进工程，然后添加libsqlite3.dylib库。<br>
创建自己的实体类，继承JKDBModel即可。<br>
例如User 继承自DBModel，然后可以直接直接调用 User对象的CURD操作。<br>
[user save];<br>
[user saveOrUpdate];<br>
[user deleteObject];<br>
[user update];<br>
[User findAll];<br>
[User findByXXX];<br>
.......

#主要方法展示
/**获取该类的所有属性 */
+ (NSDictionary *)getPropertys;


/** 获取所有属性，包括主键 */
+ (NSDictionary *)getAllProperties;


/** 数据库中是否存在表 */
+ (BOOL)isExistInTable;


/** 保存或更新,如果不存在主键保存,有主键，则更新 */
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


/** 查询全部数据 */
+ (NSArray *)findAll;


/** 通过主键查询 */
+ (instancetype)findByPK:(int)inPk;

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria;


/** 通过条件查找数据,这样可以进行分页查询 @" WHERE pk > 5 limit 10" */
+ (NSArray *)findByCriteria:(NSString *)criteria;

/** 创建表 */
+ (BOOL)createTable;
+ 
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写 */
+ (NSArray *)transients;

# 注意事项
有部分方法是类方法，有些是私有方法。<br>
有问题的地方欢迎指正。
