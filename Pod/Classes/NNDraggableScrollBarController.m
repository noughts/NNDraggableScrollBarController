//
//  PSDraggableScrollBarController.m
//  Pods
//
//  Created by noughts on 2015/11/13.
//
//

#import "NNDraggableScrollBarController.h"
#import "FBKVOController.h"
#import "NBULogStub.h"
#import "FrameAccessor.h"

@implementation NNDraggableScrollBarController{
	__weak UIScrollView* _scrollView;
	FBKVOController* _kvoController;
	UIImageView* _knob_iv;
    UILabel* _label;
	BOOL _knobDragging;
    NSTimer* _hideKnob_timer;
    NSUInteger _noMoveFrameCounter;
}

-(instancetype)initWithScrollView:(UIScrollView*)scrollView knobImage:(UIImage*)knobImage{
	if( self = [super init] ){
		_scrollView = scrollView;
		
		_kvoController = [FBKVOController controllerWithObserver:self];
		[_kvoController observe:_scrollView keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew action:@selector(onScrollViewScroll:)];
		
        [self addKnobWithImage:knobImage];/// ノブを追加
        [self addLabel];
        
        _hideKnob_timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30 target:self selector:@selector(onTick:) userInfo:nil repeats:YES];
	}
	return self;
}




#pragma mark - public

-(void)setLabelFontSize:(NSUInteger)labelFontSize{
    _labelFontSize = labelFontSize;
     _label.font = [UIFont systemFontOfSize:labelFontSize];
}









-(void)onTick:(NSTimer*)timer{
//    NBULogInfo(@"_noMoveFrameCounter = %@", @(_noMoveFrameCounter));
    _noMoveFrameCounter++;
    if( _noMoveFrameCounter == 30*1.5 ){
        [self hideKnobAndLabel];
    }
}

/// ノブ追加
-(void)addKnobWithImage:(UIImage*)knobImage{
    _knob_iv = [[UIImageView alloc] initWithImage:knobImage];
    [_scrollView.superview addSubview:_knob_iv];
    _knob_iv.layer.zPosition = 1000;
    _knob_iv.userInteractionEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _knob_iv.alpha = 0;
    
    UIPanGestureRecognizer* gr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onKnobPan:)];
    [_knob_iv addGestureRecognizer:gr];
}

/// ラベル追加
-(void)addLabel{
    _label = [[UILabel alloc] init];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.backgroundColor = [[UIColor alloc] initWithWhite:0 alpha:0.5];
    _label.layer.cornerRadius = 6;
    _label.clipsToBounds = YES;
    _label.textColor = [UIColor whiteColor];
    _label.font = [UIFont systemFontOfSize:12];
    [_scrollView.superview addSubview:_label];
    _label.layer.zPosition = 1000;
    _label.userInteractionEnabled = NO;
    _label.alpha = 0;
}


-(void)updateLabelWithString:(NSString*)str{
    _label.text = str;

    CGSize maxSize = CGSizeMake(1000,1000);
    CGSize newSize = [_label sizeThatFits:maxSize];
    
    CGRect frame = _label.frame;
    frame.size = CGSizeMake(newSize.width + 10, newSize.height+10);
    _label.frame = frame;
    
    _label.layer.anchorPoint = CGPointMake(1, 0.5);
}


-(void)onKnobPan:(UIPanGestureRecognizer*)gr{
	switch (gr.state) {
		case UIGestureRecognizerStateBegan:
			_knobDragging = YES;
			[_scrollView setContentOffset:_scrollView.contentOffset animated:NO];/// 現在の慣性スクロールを止める
            [self showLabel];
			break;
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
			_knobDragging = NO;
		default:
			break;
	}
	
	UIEdgeInsets knobEdgeInset = [self knobEdgeInsets];
	
	CGFloat touchY = [gr locationInView:_scrollView.superview].y;
	CGFloat pct = 0;
	
	if( touchY < knobEdgeInset.top ){
		pct = 0;// 上すぎ
	} else if( touchY > [self knobScrollBottomEnd] ){
		pct = 1;// 下すぎ
	} else {
		touchY -= knobEdgeInset.top;
		pct = touchY / [self knobScrollHeight];
	}
	CGFloat targetScrollPosY = -_scrollView.contentInset.top + [self scrolllViewBottomEnd] * pct;
	_scrollView.contentOffsetY = targetScrollPosY;
}



-(UIEdgeInsets)knobEdgeInsets{
	CGFloat top = _scrollView.contentInset.top + _knob_iv.height/2;
	CGFloat bottom = _scrollView.contentInset.bottom + _knob_iv.height / 2;
	return UIEdgeInsetsMake(top, 0, bottom, 0);
}



-(void)updateKnobPosition{
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	UIEdgeInsets knobEdgeInset = [self knobEdgeInsets];
	
	CGFloat posX = screenSize.width - _knob_iv.width/2;
    CGFloat scrollViewPosY = (_scrollView.contentOffset.y + _scrollView.contentInset.top);
	CGFloat pct = scrollViewPosY / [self scrolllViewBottomEnd];
	
	CGFloat posY = knobEdgeInset.top + ([self knobScrollHeight] * pct);
	if( posY < knobEdgeInset.top ){
		posY = knobEdgeInset.top;
	}
	if( posY > [self knobScrollBottomEnd] ){
		posY = [self knobScrollBottomEnd];
	}
	_knob_iv.center = CGPointMake( posX, posY );
    
    /// ラベルの位置も更新
    if( [_dataSource respondsToSelector:@selector(scrollBarController:titleForPosition:)] ){
        NSString* title = [_dataSource scrollBarController:self titleForPosition:scrollViewPosY];
        [self updateLabelWithString:[NSString stringWithFormat:@"%@",title]];
    } else {
        [self hideLabel];
    }
    _label.center = CGPointMake(posX - 54, posY);
    
}


/// ScrollViewのスクロール下限
-(CGFloat)scrolllViewBottomEnd{
	return _scrollView.contentSize.height - _scrollView.height + _scrollView.contentInset.top + _scrollView.contentInset.bottom;
}

/// ノブのスクロール下限
-(CGFloat)knobScrollBottomEnd{
	return _scrollView.superview.height - [self knobEdgeInsets].bottom;
}

/// ノブの可動できる高さ
-(NSUInteger)knobScrollHeight{
	return _scrollView.height - _scrollView.contentInset.top - _scrollView.contentInset.bottom - _knob_iv.height;
}


-(void)onScrollViewScroll:(NSDictionary*)sender{
	NBULogInfo(@"isDragging = %@", @(_scrollView.isDragging));
	NBULogInfo(@"isTracking = %@", @(_scrollView.isTracking));
	if( _scrollView.isDragging || _scrollView.isTracking || _knobDragging ){
		 [self showKnob];
	}
	
    _noMoveFrameCounter = 0;
	[self updateKnobPosition];
    if( _scrollView.tracking ){
        /// スクロールビューをドラッグしていたらラベルは消す
        [self hideLabel];
    }
}



-(void)hideKnobAndLabel{
    [UIView animateWithDuration:0.25 animations:^{
        _knob_iv.alpha = 0;
        _label.alpha = 0;
    }];
}


-(void)showKnob{
//	NBULogInfo(@"showKnob");
	[UIView animateWithDuration:0.25 animations:^{
		_knob_iv.alpha = 1;
	}];
}



-(void)showLabel{
    [UIView animateWithDuration:0.25 animations:^{
        _label.alpha = 1;
    }];
}

-(void)hideLabel{
    [UIView animateWithDuration:0.25 animations:^{
        _label.alpha = 0;
    }];
}


@end
