//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCConsole.h"
#import "ELCOverlayImageView.h"

@interface ELCAssetCell ()

@property (nonatomic, strong) NSArray *rowAssets;
@property (nonatomic, strong) NSMutableArray *imageViewArray;
@property (nonatomic, strong) NSMutableArray *overlayViewArray;
@property (nonatomic, strong) NSMutableArray *durationLabelArray;

@end

@implementation ELCAssetCell

//Using auto synthesizers

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [self addGestureRecognizer:tapRecognizer];
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
        
        self.durationLabelArray = [[NSMutableArray alloc] initWithCapacity:4];
        
        self.alignmentLeft = YES;
	}
	return self;
}

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
    for (UIImageView *view in _imageViewArray) {
        [view removeFromSuperview];
    }
    for (ELCOverlayImageView *view in _overlayViewArray) {
        [view removeFromSuperview];
    }
    for (UILabel *label in _durationLabelArray) {
        [label removeFromSuperview];
    }
    
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {
        
        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        
        if (i < [_imageViewArray count]) {
            UIImageView *imageView = [_imageViewArray objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];
        } else {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:asset.asset.thumbnail]];
            [_imageViewArray addObject:imageView];
        }
        
        if (i < [_overlayViewArray count]) {
            ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = asset.assetType == ALAssetTypeVideo ? NO : YES;
        } else {
            if (overlayImage == nil) {
                overlayImage = [UIImage imageNamed:@"Overlay.png"];
            }
            ELCOverlayImageView *overlayView = [[ELCOverlayImageView alloc] initWithImage:overlayImage];
            [_overlayViewArray addObject:overlayView];
            overlayView.hidden = asset.assetType == ALAssetTypeVideo ? NO : YES;
        }
        
        UILabel *durationLabel = nil;
        if (i < [_durationLabelArray count]) {
            durationLabel = [_durationLabelArray objectAtIndex:i];
        } else {
            durationLabel = [[UILabel alloc] init];
            [_durationLabelArray addObject:durationLabel];
            durationLabel.textColor = [UIColor whiteColor];
            durationLabel.font = [UIFont systemFontOfSize:12];
            durationLabel.textAlignment = NSTextAlignmentRight;
            durationLabel.backgroundColor = [UIColor clearColor];
        }
        durationLabel.hidden = asset.assetType == ALAssetTypeVideo ? NO : YES;
        NSUInteger duration = ceil(asset.duration);
        NSUInteger minutes = duration / 60;
        NSUInteger seconds = duration % 60;
        NSString *timeFormat = seconds < 10 ? @"%lu:0%lu" : @"%lu:%lu";
        durationLabel.text = [NSString stringWithFormat:timeFormat, (unsigned long)minutes, (unsigned long)seconds];
    }
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    int c = (int32_t)self.rowAssets.count;
    CGFloat totalWidth = c * 75 + (c - 1) * 4;
    CGFloat startX;
    
    if (self.alignmentLeft) {
        startX = 4;
    }else {
        startX = (self.bounds.size.width - totalWidth) / 2;
    }
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            asset.selected = !asset.selected;
            ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.hidden = !asset.selected;
            if (asset.selected) {
                asset.index = [[ELCConsole mainConsole] numOfSelectedElements];
                [overlayView setIndex:asset.index+1];
                [[ELCConsole mainConsole] addIndex:asset.index];
            }
            else
            {
                int lastElement = [[ELCConsole mainConsole] numOfSelectedElements] - 1;
                [[ELCConsole mainConsole] removeIndex:lastElement];
            }
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)layoutSubviews
{
    int c = (int32_t)self.rowAssets.count;
    CGFloat totalWidth = c * 75;
    
    static CGFloat scale;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scale = [[UIScreen mainScreen] scale];
    });
    
    CGFloat cellsSpacing = (self.bounds.size.width - totalWidth) / (c + 1);
    cellsSpacing = ceil(scale*cellsSpacing)/scale;
    CGFloat startX = cellsSpacing;
    
	CGRect frame = CGRectMake(startX, 2, 75, 75);
    CGRect durationFrame = CGRectMake(32.0, 56.0, 40.0, 19.0);    
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];

        UILabel *durationLabel = [_durationLabelArray objectAtIndex:i];
        [durationLabel setFrame:durationFrame];
        [overlayView addSubview:durationLabel];
		
		frame.origin.x = frame.origin.x + frame.size.width + cellsSpacing;
	}
}


@end
