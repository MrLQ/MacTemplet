//
//  HHLabel.h
//  MacTemplet
//
//  Created by Bin Shang on 2019/6/20.
//  Copyright © 2019 Bin Shang. All rights reserved.
//

#import "NNTextField.h"

NS_ASSUME_NONNULL_BEGIN

/**
 类似 iOS中的UILabel
 */
@interface HHLabel : NNTextField

@property(nonatomic, strong) void(^mouseDownBlock)(HHLabel *sender);

@end

NS_ASSUME_NONNULL_END
