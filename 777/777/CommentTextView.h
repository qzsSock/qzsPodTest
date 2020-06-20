//
//  CommentTextView.h
//  WanDaoHui
//
//  Created by 爱吃鱼的猫 on 2019/10/29.
//  Copyright © 2019  谢祖兴. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommentTextView : UIView
+ (void)showWithBackTextBlock:(void (^)(NSString *text))block dismissBlock:(void (^)(void))dismissBlock;
@end

NS_ASSUME_NONNULL_END
