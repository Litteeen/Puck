#import "PuckToggle.h"

@implementation PuckToggle

- (UIImage *)iconGlyph {
  
  return [UIImage imageNamed:@"toggleIcon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
  
}

- (UIColor *)selectedColor {

	return [UIColor blueColor];

}

- (BOOL)isSelected {

  return _selected;

}

- (void)setSelected:(BOOL)selected {

  _selected = selected;

  [super refreshState];

  if (_selected) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"puckCallNotification" object:nil];
  }

}

@end
