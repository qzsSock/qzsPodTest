//
//  CommentTextView.m
//  WanDaoHui
//
//  Created by 爱吃鱼的猫 on 2019/10/29.
//  Copyright © 2019  谢祖兴. All rights reserved.
//

#import "CommentTextView.h"

@interface CommentTextView()<UITextViewDelegate>
@property (nonatomic, copy) void(^textBlock)(NSString *text);
@property (nonatomic, copy) void(^dismissBlock)(void);
@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UITextView *textView;
@end

@implementation CommentTextView



@end
