//
//  JGCollectionViewController.m
//  JGReuseCacheExample
//
//  Created by Jaden Geller on 12/27/13.
//  Copyright (c) 2013 Jaden Geller. All rights reserved.
//

#import "JGCollectionViewController.h"
#import "JGReuseCache.h"

const NSInteger kViewReuseTag = 760;

@implementation JGCollectionViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[JGReuseCache sharedCache] registerViewReuseForTag:kViewReuseTag reuseBlock:^(id<NSObject> object) {
        UIView *view = (UIView*)object;
        view.backgroundColor = [UIColor redColor];
    }];
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"kExampleCell" forIndexPath:indexPath];
    [cell reuseContents];
    
    CGFloat w = cell.frame.size.width / 10;
    CGFloat h = cell.frame.size.height / 10;
    
    int count = 0;
    int max = (sin(indexPath.row)+1)*50;
    for (int x = 0; x < 10; x++) {
        for (int y = 0; y < 10; y++) {
            if (count > max) goto leave; // don't judge!!
            UIView *view = [[JGReuseCache sharedCache] dequeueReusableViewWithTag:kViewReuseTag];
            view.frame = CGRectMake(w * x, h * y, w, h);
            if ((x + y) & 1) view.backgroundColor = [UIColor greenColor];
            [cell addSubview:view];
            count++;
        }
    }
    
    leave: return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 100;
}

@end
