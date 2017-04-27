//
//  CardView.m
//  CardView
//
//  Created by Johnny on 2017/4/26.
//  Copyright © 2017年 Johnny. All rights reserved.
//

#import "CardView.h"
#import "CardItemView.h"

static const NSInteger ITEM_VIEW_COUNT = 4;
static const NSInteger AHEAD_ITEM_COUNT = 5;

@interface CardView () <CardItemViewDelegate>

@property (assign, nonatomic) NSInteger itemCount;
@property (assign, nonatomic) NSInteger removedCount;
@property (assign, nonatomic) BOOL isWorking;
@property (assign, nonatomic) BOOL isAskingMoreData;

@end

@implementation CardView

- (void)deleteTheTopItemViewWithLeft:(BOOL)left {
    if (self.isWorking) {
        return;
    }
    self.isWorking = YES;
    CardItemView *itemView = (CardItemView *)self.subviews.lastObject;
    [itemView removeWithLeft:left];
}

- (void)reloadData {
    if (_dataSource == nil) {
        return ;
    }
    self.isAskingMoreData = NO;
    self.itemCount = [self numberOfItemViews];
    
    if (self.subviews.count < ITEM_VIEW_COUNT) {
        for (NSInteger i = self.subviews.count; i < ITEM_VIEW_COUNT; i ++) {
            [self insertCard:self.removedCount+i];
        }
        [self sortCards];
    }
}

- (void)sortCardsWithRate:(CGFloat)rate animate:(BOOL)isAnmate {
    for (int i=1; i<self.subviews.count; i++) {
        NSInteger index = self.subviews.count-i-1;
        CardItemView *card = self.subviews[index];
        NSInteger y = i>ITEM_VIEW_COUNT-2 ? ITEM_VIEW_COUNT-2 : i;
        CGFloat realRate = y-rate>0 ? y-rate : 0;
        if (i == (ITEM_VIEW_COUNT-1)) {
            realRate = y;
        }
        CGFloat animationTime = isAnmate ? 0.2 : 0;
        [UIView animateKeyframesWithDuration:animationTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
            CGAffineTransform scaleTransfrom = CGAffineTransformMakeScale(1 - 0.02 * realRate, 1 - 0.02 * realRate);
            card.transform = CGAffineTransformTranslate(scaleTransfrom, 0, 10*realRate);
        } completion:nil];
    }
}

- (void)sortCards {
    [self sortCardsWithRate:0 animate:NO];
}

#pragma mark - Insert

- (void)insertCard:(NSInteger)index {
    if (index >= self.itemCount) {
        return;
    }
    CGSize size = [self itemViewSizeAtIndex:index];
    CardItemView *itemView = [self itemViewAtIndex:index];
    [self insertSubview:itemView atIndex:0];
    itemView.delegate = self;
    itemView.tag = index+1;
    itemView.frame = CGRectMake(self.frame.size.width / 2.0 - size.width / 2.0, self.frame.size.height / 2.0 - size.height / 2.0, size.width, size.height);
    itemView.userInteractionEnabled = YES;
    [itemView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestHandle:)]];
}

#pragma mark - CardViewDataSource

- (CGSize)itemViewSizeAtIndex:(NSInteger)index {
    if ([self.dataSource respondsToSelector:@selector(cardView:sizeForItemViewAtIndex:)] && index < [self numberOfItemViews]) {
        CGSize size = [self.dataSource cardView:self sizeForItemViewAtIndex:index];
        if (size.width > self.frame.size.width || size.width == 0) {
            size.width = self.frame.size.width;
        } else if (size.height > self.frame.size.height || size.height == 0) {
            size.height = self.frame.size.height;
        }
        return size;
    }
    return self.frame.size;
}

- (CardItemView *)itemViewAtIndex:(NSInteger)index {
    if ([self.dataSource respondsToSelector:@selector(cardView:itemViewAtIndex:)]) {
        CardItemView *itemView = [self.dataSource cardView:self itemViewAtIndex:index];
        if (itemView == nil) {
            return [[CardItemView alloc] init];
        } else {
            return itemView;
        }
    }
    return [[CardItemView alloc] init];
}

- (NSInteger)numberOfItemViews {
    if ([self.dataSource respondsToSelector:@selector(numberOfItemViewsInCardView:)]) {
        return [self.dataSource numberOfItemViewsInCardView:self];
    }
    return 0;
}

#pragma mark - CardViewDelegate

- (void)tapGestHandle:(UITapGestureRecognizer *)tapGest {
    if ([self.delegate respondsToSelector:@selector(cardView:didClickItemAtIndex:)]) {
        [self.delegate cardView:self didClickItemAtIndex:tapGest.view.tag - 1];
    }
}

#pragma mark - CardItemViewDelegate

- (void)cardItemViewDidRemoveFromSuperView:(CardItemView *)cardItemView {
    self.isWorking = NO;
    self.removedCount ++;
    [self insertCard:self.removedCount+ITEM_VIEW_COUNT-1];
    if (self.removedCount + ITEM_VIEW_COUNT > self.itemCount - AHEAD_ITEM_COUNT) {
        if (!self.isAskingMoreData) {
            self.isAskingMoreData = YES;
            if ([self.dataSource respondsToSelector:@selector(cardViewNeedMoreData:)]) {
                [self.dataSource cardViewNeedMoreData:self];
            }
        }
    } else {
        self.isAskingMoreData = NO;
    }
}

- (void)cardItemViewDidMoveRate:(CGFloat)rate anmate:(BOOL)anmate {
    [self sortCardsWithRate:rate animate:anmate];
}

@end