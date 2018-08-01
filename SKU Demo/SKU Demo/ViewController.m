//
//  ViewController.m
//  SKU Demo
//
//  Created by yifo on 2018/8/1.
//  Copyright © 2018年 yanhaiqiang. All rights reserved.
//

#import "ViewController.h"
#import "UICollectionViewLeftAlignedLayout.h"
#import "AttributeCell.h"
#import "AttributeHeaerView.h"

#define kAttributeCell          @"AttributeCell"
#define kAttributeHeaerView     @"AttributeHeaerView"

#define SCREEN_WIDTH [[UIScreen mainScreen]bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen]bounds].size.height


static CGFloat const STATEBAR_HEIGHT     = 50;
static CGFloat const TABBAR_HEIGHT     = 49;


#define reallySize(a) (CGFloat)a * SCREEN_WIDTH / 375.0

#define RGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

@interface ViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic ,strong)NSMutableDictionary * skuResult;//!<最终得到的排列组合方式

@property (nonatomic ,strong)UICollectionView * collectionView;

@property (nonatomic ,strong)NSMutableArray * dataSource;//!<数据源

@property (nonatomic ,strong)NSMutableArray * selectedArr;//!<选中的数据

@property (nonatomic ,strong)NSMutableDictionary * newSkuResult;

@property (nonatomic ,strong)UILabel * goodsNameLabel;//!<商品名

@property (nonatomic ,strong)UILabel * goodsPriceLabel;//!<商品价格

@property (nonatomic, strong) UIImageView *goodsImg;//商品图


@property (nonatomic ,strong)NSString * goodsPrice;//!<商品价格

@property (nonatomic ,strong)NSString * goodsId;//!<商品id

@property (nonatomic ,strong)NSMutableArray * headerList;//!<组头的提示信息

@property (nonatomic ,strong)NSMutableArray * seletedIndexPaths;//!<选中的indexPath

@property (nonatomic ,strong)NSMutableArray * seletedIdArray;//!<选中的id

@property (nonatomic ,strong)NSMutableArray * seletedEnable;//!<不允许选择的indexPath

@property (nonatomic ,strong)NSMutableArray * notSelectedArray;//!<不允许选择的indexPath

@property (nonatomic ,strong)NSString * currentTitle;//!<当前第一行的提示信息
@property (nonatomic, assign) int count;

@end

@implementation ViewController

- (instancetype)initWithDic:(NSDictionary *)dic {
    if (self) {
        _skuData = dic;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    [self createUI];
    [self readDataSource];
}

#pragma mark - 确定按钮点击
- (void)submitAction{
    int i = 0;
    [self.notSelectedArray removeAllObjects];
    for (id obj in self.seletedIndexPaths) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:0 inSection:i];
            [self.notSelectedArray addObject:indexPath];
        }
        i++;
    }
    
    [self.collectionView reloadData];
    BOOL isAllSelected = self.notSelectedArray.count == 0;
    if (isAllSelected) {
        NSArray * goodsIds = [self getGoodsId];
        NSString * goodsId = [goodsIds firstObject];
        NSLog(@"goodID = %@", goodsId);
    }else {
        return;
    }
    
    [self dismissFeatureViewControllerWithTag:101];
}
#pragma mark - 退出当前界面
- (void)dismissFeatureViewControllerWithTag:(NSInteger)tag {
    
    __weak typeof(self)weakSelf = self;
    [weakSelf dismissViewControllerAnimated:YES completion:^{
        if (_selectedArr.count == self.dataSource.count) {//当选择全属性才传递出去
            
            dispatch_sync(dispatch_get_global_queue(0, 0), ^{
                
                NSDictionary *paDict = @{
                                         @"Tag" : [NSString stringWithFormat:@"%zd",tag],
                                         @"goods_id" : self.goodsId,
                                         @"Array" : _selectedArr
                                         };
                NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:paDict];
                [[NSNotificationCenter defaultCenter]postNotificationName:@"goods_proprety_noti" object:nil userInfo:dict];
                
            });
        }
        UIWindow *widow = [UIApplication sharedApplication].keyWindow;
        widow.backgroundColor = [UIColor whiteColor];
    }];
}

#pragma mark - UI相关
- (void)createUI{
    self.currentTitle = @"";
    [self createGoodsInfoView];
    [self createCollectionView];
    [self createSubmitButton];
}

///商品信息视图
- (void)createGoodsInfoView{
    UIView * superView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 110)];
    UIImageView *goodsImg = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 80, 80)];
    
    self.goodsImg = goodsImg;
    [superView addSubview:goodsImg];
    
    self.goodsNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(110, 15, SCREEN_WIDTH - 125, 50)];
    self.goodsPriceLabel = [[UILabel alloc]initWithFrame:CGRectMake(110, 40 + 30, SCREEN_WIDTH - 125, 20)];
    self.goodsNameLabel.textColor = [UIColor darkGrayColor];
    self.goodsNameLabel.font = [UIFont systemFontOfSize:14];
    self.goodsNameLabel.numberOfLines = 2;
    self.goodsPriceLabel.textColor = RGBA(228, 27, 70, 1);;
    [superView addSubview:self.goodsNameLabel];
    [superView addSubview:self.goodsPriceLabel];
    [self.view addSubview:superView];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, superView.bounds.size.height-0.5, SCREEN_WIDTH-30, 0.5)];
    lineView.backgroundColor = [UIColor darkGrayColor];
    [superView addSubview:lineView];
    
}

///规格列表
- (void)createCollectionView{
    UICollectionViewLeftAlignedLayout * flowLayout = [[UICollectionViewLeftAlignedLayout alloc]init];
    flowLayout.minimumInteritemSpacing = 15;
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 110, SCREEN_WIDTH, SCREEN_HEIGHT*0.8 - STATEBAR_HEIGHT - 110) collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    [self.collectionView registerNib:[UINib nibWithNibName:kAttributeCell bundle:nil] forCellWithReuseIdentifier:kAttributeCell];
    [self.collectionView registerNib:[UINib nibWithNibName:kAttributeHeaerView bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kAttributeHeaerView];
}

///提交按钮
- (void)createSubmitButton{
    UIButton * submit = [[UIButton alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT*0.8 - TABBAR_HEIGHT, SCREEN_WIDTH, 49)];
    submit.backgroundColor = RGBA(228, 27, 70, 1);
    [submit setTitle:@"确定" forState:UIControlStateNormal];
    [submit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [submit addTarget:self action:@selector(submitAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submit];
}

#pragma mark - DataSource
///读取数据
- (void)readDataSource{
    
    NSDictionary * skuDate = self.skuData[@"skuDate"];
    NSMutableArray * tempArray = [[NSMutableArray alloc]init];
    NSArray * allKeys = [skuDate allKeys];
    for (int i = 0; i < allKeys.count; i++) {
        NSString * key = allKeys[i];
        NSDictionary * dic = [skuDate objectForKey:key];
        NSDictionary * skuDic = @{key:dic};
        [tempArray addObject:skuDic];
    }
    self.skuResult = [skuDate mutableCopy];
    
    ///处理SKU数据
    [self createDataSource:tempArray];
    
    ///处理页面展示数据
    [self reloadDataSource:self.skuData];
}

#pragma mark - 处理页面展示数据
- (void)reloadDataSource:(NSDictionary *)object{
    
    [self.newSkuResult removeAllObjects];
    [self.seletedIdArray removeAllObjects];
    [self.seletedIndexPaths removeAllObjects];
    [self.selectedArr removeAllObjects];
    
    NSDictionary * result = object;
    self.newSkuResult = self.skuResult;
    
    ///计算所有可组合方式的价格，取出最大值和最小值，即价格区间
    NSMutableArray * allPrice = [[NSMutableArray alloc]init];
    
    for (NSString *key in self.newSkuResult.allKeys) {
        NSArray *prices = self.newSkuResult[key][@"prices"];
        [allPrice addObjectsFromArray:prices];
    }
    
    NSArray * rePrices = [self change:allPrice];
    NSString * minPrice = [[rePrices firstObject] stringValue];
    NSString * maxPrice = [[rePrices lastObject] stringValue];
    self.goodsPrice = [maxPrice isEqualToString:minPrice] ? minPrice : [NSString stringWithFormat:@"￥%@~￥%@",minPrice,maxPrice];
    
    //实际开发中可以用SD替换成网络图片
    self.goodsImg.image = [UIImage imageNamed:@"goodsImage.jpg"];
    
    //商品名以及默认的商品id
    NSDictionary * dic = result;
    self.goodsPriceLabel.text = [NSString stringWithFormat:@"¥%@", dic[@"price"]];
    
    self.goodsId = dic[@"minId"];
    [self.dataSource removeAllObjects];
    NSArray * array = dic[@"siftKey"];
    
    /**
     *将默认选中项加入到数组中
     *由于我是在每次点击确定后重新请求接口，刷新页面，所有不需要记录当前选中的属性
     *每次遍历后台返回的数据
     *如果不请求的话，需要在点击方法中记录一下当前上次选中的属性，下次进入的时候默认选中
     */
    for (int i = 0; i < array.count; i++) {
        NSDictionary *sectionDic = array[i];
        NSArray *itemArr = sectionDic[@"standardInfoList"];
        for (int j = 0; j < itemArr.count; j++) {
            NSDictionary *itemDic = itemArr[j];
            if ([itemDic[@"isSelect"] integerValue] == 1) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                [self.seletedIndexPaths addObject:indexPath];
                [self.seletedIdArray addObject:itemDic[@"attrValueId"]];
                [self.selectedArr addObject:itemDic[@"standardName"]];
            }
        }
    }
    
    NSString *attString = [self.selectedArr componentsJoinedByString:@" "];
    NSString *str = [NSString stringWithFormat:@"已选：%@",attString];
    self.goodsNameLabel.text = str;
    
    
    if ([array isKindOfClass:[NSNull class]]) {
        return;
    }
    
    int i = 0;
    for (NSDictionary * dic in array) {
        ///添加数据源
        [self.dataSource addObject:dic];
        
        ///处理选中的数据
        NSArray *  standardInfoList = dic[@"standardInfoList"];
        NSString * standardListName = dic[@"standardListName"];
        int x = -1;
        NSString * attrValueId = @"";
        for (int j = 0; j < standardInfoList.count; j++) {
            NSDictionary * dict = standardInfoList[j];
            NSString * isSelected = dict[@"isSelected"];
            NSString * AttrValueId = dict[@"attrValueId"];
            if ([standardListName isEqualToString:@"成色"]) {
                NSString * AttrvalueTitle = dict[@"attrvalueTitle"];
                [self.headerList addObject:AttrvalueTitle];
            }
            
            //如果有选中的就跳出该循环 并把下标赋值给x
            if ([isSelected isEqualToString:@"1"]) {
                x = j;
                attrValueId = AttrValueId;
                break;
            }
        }
        
        //x = -1表示当前没有选中的,添加默认值
        //        if (x == -1) {
        //            [self.seletedIndexPaths addObject:@"0"];
        //            [self.seletedIdArray addObject:@""];
        //        }
        //        else{
        //            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:x inSection:i];
        //            [self.seletedIndexPaths addObject:indexPath];
        //            [self.seletedIdArray addObject:attrValueId];
        //        }
        i++;
    }
    
    [self handDisenableData];
}

///处理不可选的数据
- (void)handDisenableData{
    [self.seletedEnable removeAllObjects];
    
    ///取出self.skuResult中所有可能的排列组合方式(keysArray)
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    //    for (NSDictionary * dict in self.newSkuResult) {
    //        NSString * key = [dict allKeys].firstObject;
    //        [keysArray addObject:key];
    //    }
    
    for (NSString *key in self.newSkuResult.allKeys) {
        [keysArray addObject:key];
    }
    
    //处理不可选的数据
    for (int i = 0; i < self.dataSource.count; i++) {
        NSDictionary * subDic = self.dataSource[i];
        NSArray *  standardInfoList = subDic[@"standardInfoList"];
        for (int j = 0; j < standardInfoList.count; j++) {
            NSDictionary * dict = standardInfoList[j];
            NSIndexPath * currentIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            NSString * AttrValueId = dict[@"attrValueId"];
            NSMutableArray * tempArray = [[NSMutableArray alloc]initWithArray:self.seletedIdArray];
            
            //从已经选好的组合中，移除当前组之前的id，并插入新的id
            [tempArray removeObjectAtIndex:i];
            [tempArray insertObject:AttrValueId atIndex:i];
            NSMutableArray * resultArray = [[NSMutableArray alloc]init];
            for (NSString * str in tempArray) {
                //过滤掉没有选择的组
                if (![[NSString stringWithFormat:@"%@", str] isEqualToString:@""]) {
                    [resultArray addObject:str];
                }
            }
            
            ///重新排序，拼接
            NSArray * changeArray = [self change:resultArray];
            NSString * resultKey = [changeArray componentsJoinedByString:@";"];
            //如果self.skuResult中所有的组合没有当前拼接的key，说明该规格与当前已选规格互斥，即不可选
            if (![keysArray containsObject:resultKey]) {
                [self.seletedEnable addObject:currentIndexPath];
            }
        }
    }
    [self.collectionView reloadData];
}

- (void)calculatePrice
{
    NSMutableArray * resultArray = [[NSMutableArray alloc]init];
    for (NSString * str in self.seletedIdArray) {
        if (![[NSString stringWithFormat:@"%@", str] isEqualToString:@""]) {
            [resultArray addObject:str];
        }
    }
    NSArray * skeyArray =  [self change:resultArray];
    
    NSString * key = [skeyArray componentsJoinedByString:@";"];
    NSString * price = self.goodsPrice;
    
    for (NSString *p_key in self.newSkuResult.allKeys) {
        if ([p_key isEqualToString:key]) {
            NSArray * prices = self.newSkuResult[key][@"prices"];
            NSMutableArray * rPrices = [[NSMutableArray alloc]initWithArray:prices];
            NSArray * rePrices = [self change:rPrices];
            NSString * minPrice = [[rePrices firstObject] stringValue];
            NSString * maxPrice = [[rePrices lastObject] stringValue];
            if ([maxPrice isEqualToString:minPrice]) {
                price = [NSString stringWithFormat:@"￥%@",minPrice];
            }
            else {
                price = [NSString stringWithFormat:@"￥%@~￥%@",minPrice,maxPrice];
            }
        }
    }
    self.goodsPriceLabel.text = price;
}

///取出对应商品id
- (NSArray *)getGoodsId
{
    NSMutableArray * resultArray = [[NSMutableArray alloc]init];
    for (NSString * str in self.seletedIdArray) {
        if (![[NSString stringWithFormat:@"%@", str] isEqualToString:@""]) {
            [resultArray addObject:str];
        }
    }
    NSArray * skeyArray =  [self change:resultArray];
    NSString * key = [skeyArray componentsJoinedByString:@";"];
    NSArray * goodsIds;
    
    
    
    for (NSString * skey in [self.newSkuResult allKeys]) {
        if ([key isEqualToString:skey]) {
            NSDictionary * dict = self.newSkuResult[key];
            NSArray * productIds = dict[@"productIds"];
            goodsIds = productIds;
        }
    }
    return goodsIds;
}

#pragma mark - 处理sku数据源
/*
 array对应的结构
 [
 {
 "34;29;18;9;2" = {
 price = "2650.00";
 productId = 852;
 stocksNumber = 10;
 };
 },
 {
 "34;28;15;11;4" = {
 price = "2799.00";
 productId = 1177;
 stocksNumber = 10;
 };
 },
 ...
 ]
 */
- (void)createDataSource:(NSArray *)array{
    NSMutableArray * keysArray = [[NSMutableArray alloc]init];
    NSMutableArray *valuesArray = [[NSMutableArray alloc]init];
    
    ///由于数据格式的问题，需要这么处理一下，这一步的操作是为了取出array中所有的key和value
    for (int i = 0; i < array.count; i++) {
        NSDictionary * dic = array[i];
        NSArray * keys = [dic allKeys];
        NSString * key = keys.firstObject;
        NSDictionary * value = [dic objectForKey:key];
        [keysArray addObject:key];
        [valuesArray addObject:value];
    }
    
    for (int j = 0; j < keysArray.count; j++) {
        //        @autoreleasepool {
        
        ///key对应的结构   34;29;18;9;2,
        NSString * key = keysArray[j];
        
        //使用" ; " 分割当前的字符串
        //subKeyAttrs对应的结构  [34,29,18,9,2]
        NSArray * subKeyAttrs = [key componentsSeparatedByString:@";"];
        NSMutableArray * newArray = [[NSMutableArray alloc]initWithArray:subKeyAttrs];
        
        //resultArray对应的结构  [2,9,18,29,34]
        NSArray * resultArray = [self change:newArray];
        
        
        ///取出所有可能的组合方式
        NSArray * combArr = [self combInArray:resultArray];
        
        ///value的结构
        /*
         *  {
         *      price = "2650.00";
         *      productId = 852;
         *      stocksNumber = 10;
         *  }
         */
        NSDictionary * value = valuesArray[j];
        
        //            for (int k = 0; k< combArr.count; k++) {
        //                [self addSKUResult:combArr[k] sku:value];
        //            }
        
        for (NSArray *_id in combArr) {
            [self addSKUResult:_id sku:value];
        }
        ///添加完整的组合，即五项全部选中
        NSString *keys = [resultArray componentsJoinedByString:@";"];
        NSString * price = [NSString stringWithFormat:@"%@",value[@"price"]];
        NSString * productId = value[@"productId"];
        NSString * count = [NSString stringWithFormat:@"%@",value[@"stocksNumber"]];
        NSMutableArray * prices = [[NSMutableArray alloc]init];
        NSMutableArray * productIds = [[NSMutableArray alloc]init];
        [prices addObject:price];
        [productIds addObject:productId];
        NSDictionary * dic = @{@"stocksNumber":count,@"prices":prices,@"productIds":productIds};
        //            NSDictionary * dict = @{keys:dic};
        //            [self.skuResult addObject:dict];
        self.skuResult[keys] = dic;
        //        }
    }
    
    /*
     *  至此，遍历出了当前商品对应的所有组合方式，以及组合方式相对应的商品属性(商品数量，价格(数组形式)，ID(数组形式))
     *  将其添加到了self.skuResult中，数据源部分完成，接下来做UI以及逻辑层的东西
     */
    
}

#pragma mark -------排序方法-------
- (NSArray *)change:(NSMutableArray *)array {
    NSMutableArray *mArray = @[].mutableCopy;
    for (NSString *string in array) {
        [mArray addObject:@([string integerValue])];
    }
    NSArray *sorted = [mArray.copy sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return obj1 > obj2;
    }];
    [sorted sortedArrayHint];
    return sorted;
}

/*
 *   这一步取出了array中对象之间除了array本身之外所有可能的组合方式
 *   例如 array [2,9,18,29,34]
 *   返回的新数组为
 *   [
 *      [2],
 *      ...,
 *      [34],
 *      [2,9],
 *      ...,
 *      [29,34],
 *      [2,9,18],
 *      ...
 *      [18,29,34],
 *      [2,9,18,29],
 *      [9,18,29,34],
 *   ]
 */
- (NSArray *)combInArray:(NSArray *)array{
    if ([array isKindOfClass:[NSNull class]] || array.count == 0) {
        return @[];
    }
    int len = (int)array.count;
    
    NSMutableArray * newArray = [[NSMutableArray alloc]init];
    for (int n = 1; n < len; n++) {
        /*
         *  aaFlags的结构
         *  [
         *      [1,0,0,0,0],
         *      [0,1,0,0,0],
         *      [0,0,1,0,0],
         *      [0,0,0,1,0],
         *      [0,0,0,0,1],
         *  ]
         */
        NSMutableArray * aaFlags = [[NSMutableArray alloc]initWithArray:[self getComFlags:len n:n]];
        while (aaFlags.count != 0) {
            /*
             *  aFlag的结构
             *  [1,0,0,0,0]
             */
            NSMutableArray * aFlag = [[NSMutableArray alloc]initWithArray:[aaFlags firstObject]];
            
            /*
             *  aaFlags的结构
             *  [
             *      [0,1,0,0,0],
             *      [0,0,1,0,0],
             *      [0,0,0,1,0],
             *      [0,0,0,0,1],
             *  ]
             */
            [aaFlags removeObjectAtIndex:0];
            
            NSMutableArray * aComb = [[NSMutableArray alloc]init];
            
            //aFlag对应的结构  [1,0,0,0,0]
            //array对应的结构  [2,9,18,29,34]
            for (int i = 0; i < len; i++) {
                if ([aFlag[i] intValue] == 1) {
                    [aComb addObject:array[i]];
                }
            }
            [newArray addObject:aComb];
        }
    }
    return newArray;
}


/*
 *  这一段不需要过多理解 因为我也忘了是怎么回事了
 *  总之是这么回事  传进来的len是当前这个key的组合方式的长度
 *  例如 len长度是5 那么n的值为 1，2，3，4
 *  返回的新数组的结构为
 *  [
 *      [1,0,0,0,0],
 *      [0,1,0,0,0],
 *      [0,0,1,0,0],
 *      [0,0,0,1,0],
 *      [0,0,0,0,1],
 *  ]
 *  即返回的新数组的长度以及二维数组的长度都跟len一致
 *  略过，复制粘贴即可
 */
- (NSArray *)getComFlags:(int)len n:(int)n
{
    if (!n || n < 1) {
        return @[];
    }
    NSMutableArray * aFlag = [[NSMutableArray alloc]init];
    BOOL bNext = YES;
    for (int i = 0; i < len; i++) {
        int q = i < n ? 1 : 0;
        [aFlag addObject:[NSNumber numberWithInt:q]];
    }
    NSMutableArray * aResult = [[NSMutableArray alloc]init];
    [aResult addObject:[aFlag copy]];
    int iCnt1 = 0;
    while (bNext) {
        iCnt1 = 0;
        for (int i = 0; i < len - 1; i++) {
            if ([aFlag[i] intValue] == 1 && [aFlag[i+1] intValue] == 0) {
                for (int  j = 0; j < i; j++) {
                    int w = j < iCnt1 ? 1 : 0;
                    [aFlag removeObjectAtIndex:j];
                    [aFlag insertObject:[NSNumber numberWithInt:w] atIndex:j];
                }
                [aFlag removeObjectAtIndex:i];
                [aFlag insertObject:@(0) atIndex:i];
                [aFlag removeObjectAtIndex:i+1];
                [aFlag insertObject:@(1) atIndex:i+1];
                NSArray * aTmp = [aFlag copy];
                [aResult addObject:aTmp];
                int e = (int)aTmp.count;
                NSString * tempString;
                for (int r = e - n; r < e; r ++) {
                    tempString = [NSString stringWithFormat:@"%@%@",tempString,aTmp[r]];
                }
                if ([tempString rangeOfString:@"0"].location == NSNotFound) {
                    bNext = false;
                }
                break;
            }
            if ([aFlag[i] intValue] == 1) {
                iCnt1++;
            }
        }
    }
    return aResult;
}

/// 调用 258*30 = 7740
- (void)addSKUResult:(NSArray *)combArrItem sku:(NSDictionary *)sku
{
    //整理一下现有的东西
    /*
     *  combArrItem  一种排列组合方式 [2],[34],[2,9],[2,9,18],[9,18,29,34],
     *  sku          一组完整的组合对应出的商品的属性
     */
    NSString * key = [combArrItem componentsJoinedByString:@";"];
    
    /////////////////////////////////////////////////////////////////////////////////////
    
    if ([self.skuResult objectForKey:key]) {
        NSDictionary *dict = self.skuResult[key];
        NSString * count = [NSString stringWithFormat:@"%@",sku[@"stocksNumber"]];
        NSString * reCount = [NSString stringWithFormat:@"%@",dict[@"stocksNumber"]];
        int newCount = [reCount intValue] + [count intValue];
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"price"]];
        NSMutableArray * prices = [[NSMutableArray alloc] initWithArray:dict[@"prices"]];
        [prices addObject:price];
        NSString * productId = sku[@"productId"];
        NSMutableArray * productIds = [[NSMutableArray alloc] initWithArray:dict[@"productIds"]];
        [productIds addObject:productId];
        self.skuResult[key] = @{@"prices": prices, @"productIds": productIds, @"stocksNumber": @(newCount).stringValue};
    } else {
        NSString * price = [NSString stringWithFormat:@"%@",sku[@"price"]];
        NSString * productId = sku[@"productId"];
        NSString * count = [NSString stringWithFormat:@"%@",sku[@"stocksNumber"]];
        self.skuResult[key] = @{@"prices": @[price], @"productIds": @[productId], @"stocksNumber": count};
    }
}

#pragma mark - CollectionView代理
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSDictionary * dic = self.dataSource[section];
    NSArray * array = dic[@"standardInfoList"];
    return array.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AttributeCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:kAttributeCell forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"standardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    cell.propsInfo = dict;
    
    //不可选
    if ([self.seletedEnable containsObject:indexPath]) {
        cell.backgroundColor = RGBA(245, 245, 245, 1);
        cell.propsLabel.textColor = [UIColor lightGrayColor];
        cell.userInteractionEnabled = NO;
    }
    //可选
    else{
        cell.backgroundColor = RGBA(242, 242, 242, 1);
        cell.propsLabel.textColor = [UIColor darkGrayColor];
        cell.userInteractionEnabled = YES;
    }
    
    //选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        cell.backgroundColor = RGBA(228, 27, 70, 1);
        cell.propsLabel.textColor = [UIColor whiteColor];
        cell.userInteractionEnabled = YES;
    }
    
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"standardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    NSString * string = dict[@"standardName"];
    CGFloat width = (string.length + 2) * 12;
    return CGSizeMake(width, 25);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * dic = self.dataSource[indexPath.section];
    NSArray * array = dic[@"standardInfoList"];
    NSDictionary * dict = array[indexPath.item];
    NSString * AttrValueId = dict[@"attrValueId"] ;
    NSString * AttrValueName = dict[@"standardName"] ;
    
    //取出所有选中状态的按钮标题
    //如果已经被选中则取消选中
    if ([self.seletedIndexPaths containsObject:indexPath]) {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:@"0" atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:@"" atIndex:indexPath.section];
        [self.selectedArr removeObjectAtIndex:indexPath.section];
        [self.selectedArr insertObject:@"" atIndex:indexPath.section];
    }
    else
    {
        [self.seletedIndexPaths removeObjectAtIndex:indexPath.section];
        [self.seletedIndexPaths insertObject:indexPath atIndex:indexPath.section];
        [self.seletedIdArray removeObjectAtIndex:indexPath.section];
        [self.seletedIdArray insertObject:AttrValueId atIndex:indexPath.section];
        [self.selectedArr removeObjectAtIndex:indexPath.section];
        [self.selectedArr insertObject:AttrValueName atIndex:indexPath.section];
    }
    NSString *attString = [self.selectedArr componentsJoinedByString:@" "];
    NSString *str = [NSString stringWithFormat:@"已选：%@",attString];
    self.goodsNameLabel.text = str;
    [self calculatePrice];
    
    NSString * StandardListName = dic[@"standardListName"];
    if ([StandardListName isEqualToString:@"成色"]) {
        id obj = self.seletedIndexPaths[indexPath.section];
        if ([obj isKindOfClass:[NSIndexPath class]]) {
            self.currentTitle = self.headerList[indexPath.item];
        }
        else
        {
            self.currentTitle = @"";
        }
    }
    ///重新处理不可选的规格
    [self handDisenableData];
    
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    AttributeHeaerView * headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kAttributeHeaerView forIndexPath:indexPath];
    NSDictionary * dic = self.dataSource[indexPath.section];
    headView.titleLabel.text = dic[@"standardListName"];
    
    ///该项没有选中
    if ([self.notSelectedArray containsObject:indexPath]) {
        headView.alertLabel.hidden = NO;
    }
    else
    {
        headView.alertLabel.hidden = YES;
    }
    
    if ([dic[@"standardListName"] isEqualToString:@"成色"]) {
        if (![self.currentTitle isEqualToString:@""]) {
            headView.specLabel.text = self.currentTitle;
            headView.specLabel.hidden = NO;
            headView.alertLabel.hidden = YES;
        }
        else
        {
            headView.specLabel.hidden = YES;
        }
    }
    else
    {
        headView.specLabel.hidden = YES;
    }
    
    return headView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(SCREEN_WIDTH, 30);
}

#pragma mark - 懒加载
- (NSMutableDictionary *)skuResult
{
    if (_skuResult == nil) {
        _skuResult = [[NSMutableDictionary alloc]init];
    }
    return _skuResult;
}
- (NSMutableArray *)dataSource
{
    if (_dataSource == nil) {
        _dataSource = [[NSMutableArray alloc]init];
    }
    return _dataSource;
}
- (NSMutableDictionary *)newSkuResult
{
    if (_newSkuResult == nil) {
        _newSkuResult = [[NSMutableDictionary alloc]init];
    }
    return _newSkuResult;
}
- (NSMutableArray *)headerList
{
    if (_headerList == nil) {
        _headerList = [[NSMutableArray alloc]init];
    }
    return _headerList;
}
- (NSMutableArray *)seletedIdArray
{
    if (_seletedIdArray == nil) {
        _seletedIdArray = [[NSMutableArray alloc]init];
    }
    return _seletedIdArray;
}
- (NSMutableArray *)seletedIndexPaths
{
    if (_seletedIndexPaths == nil) {
        _seletedIndexPaths = [[NSMutableArray alloc]init];
    }
    return _seletedIndexPaths;
}
- (NSMutableArray *)seletedEnable
{
    if (_seletedEnable == nil) {
        _seletedEnable = [[NSMutableArray alloc]init];
    }
    return _seletedEnable;
}
- (NSMutableArray *)notSelectedArray
{
    if (_notSelectedArray == nil) {
        _notSelectedArray = [[NSMutableArray alloc]init];
    }
    return _notSelectedArray;
}
- (NSMutableArray *)selectedArr {
    if (_selectedArr == nil) {
        _selectedArr = [[NSMutableArray alloc] init];
    }
    return _selectedArr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

