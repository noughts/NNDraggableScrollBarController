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
	BOOL _knobDragging;
    BOOL _isKnobHideTimerCancelled;
}

-(instancetype)initWithScrollView:(UIScrollView*)scrollView knobImage:(UIImage*)knobImage{
	if( self = [super init] ){
		_scrollView = scrollView;
		
		_kvoController = [FBKVOController controllerWithObserver:self];
		[_kvoController observe:_scrollView keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew action:@selector(onScrollViewScroll:)];
		
		/// ノブを追加
		_knob_iv = [[UIImageView alloc] initWithImage:knobImage];
		[_scrollView.superview addSubview:_knob_iv];
		_knob_iv.layer.zPosition = 1000;
		_knob_iv.userInteractionEnabled = YES;
		_scrollView.showsVerticalScrollIndicator = NO;
		_knob_iv.alpha = 0;
		
		UIPanGestureRecognizer* gr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onKnobPan:)];
		[_knob_iv addGestureRecognizer:gr];
	}
	return self;
}




-(void)onKnobPan:(UIPanGestureRecognizer*)gr{
	switch (gr.state) {
		case UIGestureRecognizerStateBegan:
            _isKnobHideTimerCancelled = YES;
			_knobDragging = YES;
			[_scrollView setContentOffset:_scrollView.contentOffset animated:NO];/// スクロールを止める
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
	CGFloat pct = (_scrollView.contentOffset.y + _scrollView.contentInset.top) / [self scrolllViewBottomEnd];
	
	CGFloat posY = knobEdgeInset.top + ([self knobScrollHeight] * pct);
	if( posY < knobEdgeInset.top ){
		posY = knobEdgeInset.top;
	}
	if( posY > [self knobScrollBottomEnd] ){
		posY = [self knobScrollBottomEnd];
	}
	_knob_iv.center = CGPointMake( posX, posY );
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
	if( _scrollView.dragging == 1 ){
		[self showKnob];
	} else {
		if( _knobDragging == NO ){
			[self hideKnob];
		}
	}
	[self updateKnobPosition];
}

-(void)flashKnob{
	[UIView animateWithDuration:0.25 animations:^{
		_knob_iv.alpha = 1;
	} completion:^(BOOL finished) {
		if( finished == NO ){
			return;
		}
		[UIView animateWithDuration:0.25 delay:1000 options:0 animations:^{
			_knob_iv.alpha = 0;
		} completion:nil];
	}];
}


-(void)showKnob{
    _isKnobHideTimerCancelled = YES;
	[UIView animateWithDuration:0.25 animations:^{
		_knob_iv.alpha = 1;
	}];
}


-(void)hideKnob{
    _isKnobHideTimerCancelled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if( _isKnobHideTimerCancelled ){
            return;
        }
       	[UIView animateWithDuration:0.25 animations:^{
            _knob_iv.alpha = 0;
        }];
    });

}


@end
