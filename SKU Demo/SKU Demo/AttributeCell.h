//
//  AttributeCell.h
//  SKUDemo
//
//  Created by HFL on 2018/4/27.
//  Copyright © 2018年 albee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttributeCell : UICollectionViewCell

@property (nonatomic ,strong)NSDictionary * propsInfo;//!<规格信息
@property (weak, nonatomic) IBOutlet UILabel *propsLabel;

@end
