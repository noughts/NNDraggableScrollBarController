//
//  PSViewController.m
//  PSDraggableScrollBarController
//
//  Created by Koichi Yamamoto on 11/13/2015.
//  Copyright (c) 2015 Koichi Yamamoto. All rights reserved.
//

#import "NNViewController.h"
#import <NNDraggableScrollBarController.h>

@implementation NNViewController{
	__weak IBOutlet UITableView* _tableView;
	NNDraggableScrollBarController* _scrollBarController;
}

- (void)viewDidLoad{
	[super viewDidLoad];
	
	_tableView.contentInset = _tableView.scrollIndicatorInsets;
	
	UIImage* knob_img = [UIImage imageNamed:@"grid_scrollBarKnob"];
	_scrollBarController = [[PSDraggableScrollBarController alloc] initWithScrollView:_tableView knobImage:knob_img];
}


-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[_tableView flashScrollIndicators];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return 20;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	cell.textLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.row)];
	return cell;
}



@end
