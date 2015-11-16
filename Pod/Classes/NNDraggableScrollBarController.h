//
//  PSDraggableScrollBarController.h
//  Pods
//
//  Created by noughts on 2015/11/13.
//
//

#import <Foundation/Foundation.h>
@protocol NNDraggableScrollBarControllerDataSource;


@interface NNDraggableScrollBarController : NSObject

-(instancetype)initWithScrollView:(UIScrollView*)scrollView knobImage:(UIImage*)knobImage;
@property(nonatomic,weak)id <NNDraggableScrollBarControllerDataSource> dataSource;

@end








#pragma mark - delegate定義

@protocol NNDraggableScrollBarControllerDataSource<NSObject>

-(NSString*)scrollBarController:(NNDraggableScrollBarController *)controller titleForPosition:(CGFloat)position;

@end
