//
//  AttributeCell.m
//  SKUDemo
//
//  Created by HFL on 2018/4/27.
//  Copyright © 2018年 albee. All rights reserved.
//

#import "AttributeCell.h"

@implementation AttributeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
}
- (void)setPropsInfo:(NSDictionary *)propsInfo{
    _propsInfo = propsInfo;
    self.propsLabel.text = propsInfo[@"standardName"];
}

@end
