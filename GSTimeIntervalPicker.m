//
//  GSTimeIntervalPicker.m
//  Timelines
//
//  Created by Lukas Petr on 12/1/16.
//  Copyright © 2016 Glimsoft. All rights reserved.
//

#import "GSTimeIntervalPicker.h"

#define kComponentViewWidth     80
#define kComponentViewHeight    32

#define kComponentHours         0
#define kComponentMinutes       1

#define kLargeInteger           400     // Used to simulate infinite wheel effect.


@interface GSTimeIntervalPicker () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UILabel *hoursLabel;
@property (nonatomic, strong) UILabel *minLabel;

@property (nonatomic) NSInteger step;
@property (nonatomic) NSInteger countOfMinuteSteps;     // How many steps fit within one hour.
@property (nonatomic) NSInteger countOfHours;           // How many hours do we display.
@property (nonatomic) NSInteger maxMinutesRemainder;    // Used to limit upper-bound selection.

@property (nonatomic) BOOL showingHoursPlural;

@end


@implementation GSTimeIntervalPicker


#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.dataSource = self;
    self.delegate = self;

    _step = 5;
    _countOfMinuteSteps = 60 / _step;
    _allowZeroTimeInterval = NO;
    _showingHoursPlural = YES;
    
    // This ensures the selection lines are visible (fix found at http://stackoverflow.com/a/40076366/1459762)
    [self selectRow:0 inComponent:0 animated:YES];
    
    self.maxTimeInterval = (3600 * 3);      // 3 hours
    
    // Create and add static labels.
    self.hoursLabel = [self newStaticLabelWithText:NSLocalizedString(@"hours", nil)];
    [self addSubview:self.hoursLabel];
    
    self.minLabel = [self newStaticLabelWithText:NSLocalizedString(@"min", nil)];
    [self addSubview:self.minLabel];
    
    [self updateStaticLabelsPositions];
    [self reloadAllComponents];
}

- (UILabel *)newStaticLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, kComponentViewHeight)];
    label.text = text;
    label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    return label;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateStaticLabelsPositions];
}

- (void)updateStaticLabelsPositions {
    // Position the static labels
    CGFloat y = ((CGRectGetHeight(self.frame) / 2) - 14.5);
    
    CGFloat viewWidth = CGRectGetWidth(self.frame);
    CGFloat x1 = (viewWidth / 2) - 49;
    CGFloat x2 = (viewWidth / 2) + 62;
    
    self.hoursLabel.frame = CGRectMake(x1, y, 75, kComponentViewHeight);
    self.minLabel.frame = CGRectMake(x2, y, 75, kComponentViewHeight);
}


#pragma mark - Public methods

- (void)setMaxTimeInterval:(NSTimeInterval)maxTimeInterval {
    _maxTimeInterval = maxTimeInterval;
    
    NSInteger maxTimeIntervalInMinutes = (NSInteger)(maxTimeInterval / 60);
    NSInteger hours = maxTimeIntervalInMinutes / 60;
    NSInteger mins = maxTimeIntervalInMinutes - (hours * 60);
    
    _maxMinutesRemainder = mins;
    _countOfHours = hours;
    [self reloadComponent:kComponentHours];
    [self reloadComponent:kComponentMinutes];
    
    // Force the reload
    self.timeInterval = MIN(self.timeInterval, self.maxTimeInterval);
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
    [self setTimeInterval:timeInterval animated:NO];
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval animated:(BOOL)animated {
    _timeInterval = timeInterval;
    
    NSAssert(timeInterval <= self.maxTimeInterval, @"GSTimeIntervalPicker -setTimeInterval: argument is higher than maxTimeInterval.");
    
    _timeInterval = timeInterval;
    
    NSInteger durationInMinutes = (NSInteger)(timeInterval / 60);
    NSInteger hours = durationInMinutes / 60;
    NSInteger mins = durationInMinutes - (hours * 60);
    
    [self selectRow:hours inComponent:kComponentHours animated:animated];
    
    
    NSInteger selectedRow = [self selectedRowInComponent:kComponentMinutes];
    
    if (selectedRow == 0) {
        // We are still in the initialization steps -> place ourselves in the middle
        NSInteger newMinutesRow = (NSInteger)round((CGFloat)mins / (CGFloat)_step);
        if (_countOfHours > 0) {
            // Place it in the middle of our 'infinite' wheel.
            newMinutesRow += (_countOfMinuteSteps * (kLargeInteger / 2));
        }
        [self selectRow:newMinutesRow inComponent:kComponentMinutes animated:animated];
    }
    else {
        // Scroll by the shortest possible amount to the newly selected minutes.
        NSInteger currentMins = (selectedRow % _countOfMinuteSteps) * _step;
        NSInteger changeOfMinutes = mins - currentMins;
        if (changeOfMinutes > 30) {
            // Scroll the other way around
            changeOfMinutes = changeOfMinutes - 60;
        }
        NSInteger changeInSteps = (NSInteger)roundf((CGFloat)changeOfMinutes / _step);
        if (changeInSteps == 0) {
            // We are over limit, but when divided by step, it gets rounded off to zero -> scroll down anyway.
            changeInSteps = -1;
        }
        
        [self selectRow:selectedRow + changeInSteps inComponent:kComponentMinutes animated:animated];
    }
    
    self.showingHoursPlural = (hours != 1);
}

- (void)setMinuteInterval:(NSInteger)minuteInterval {
    // Check the validity
    NSArray *validMinuteIntervals = @[@1, @2, @3, @4, @5, @6, @10, @12, @15, @20, @30];
    if ([validMinuteIntervals containsObject:@(minuteInterval)] == NO) {
        minuteInterval = 1;     // Minute interval wasn't valid, use the default one
    }
    
    _step = minuteInterval;
    self.countOfMinuteSteps = 60 / _step;
    
    [self reloadComponent:kComponentMinutes];
    
    // Get the minutes remainder and select the relevant cell
    NSInteger timeIntervalInMinutes = (NSInteger)(self.timeInterval / 60);
    NSInteger minutes = timeIntervalInMinutes % 60;
    NSInteger newMinutesRow = (NSInteger)round((CGFloat)minutes / (CGFloat)_step);
    if (newMinutesRow * _step > _maxMinutesRemainder) {
        // Disallow the integer rounding to exceed our limit.
        newMinutesRow -= 1;
    }
    
    if (_countOfHours > 0) {
        // Place it in the middle of our 'infinite' wheel
        newMinutesRow += (_countOfMinuteSteps * kLargeInteger / 2);
    }
    
    [self selectRow:newMinutesRow inComponent:kComponentMinutes animated:NO];
}

- (NSInteger)minuteInterval {
    return _step;
}


#pragma mark - UIPickerView Datasource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    switch (component) {
        case kComponentHours:
            return _countOfHours + 1;       // We have to account for the '0 hours' row.
            
        case kComponentMinutes:
            if (_countOfHours > 0) {
                return _countOfMinuteSteps * kLargeInteger;
            } else {
                return (_maxMinutesRemainder / _step) + 1;      // The '+1' is to account for the 0 at the beginning.
            }
        
        default:
            break;
    }
    
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UIView *viewWithLabel = view;
    
    if (viewWithLabel == nil) {
        viewWithLabel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kComponentViewWidth, kComponentViewHeight)];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(11, 0, 30, kComponentViewHeight)];
        label.font = [UIFont systemFontOfSize:23];
        label.textAlignment = NSTextAlignmentRight;
        [viewWithLabel addSubview:label];
    }
    
    UILabel *label = (UILabel *)viewWithLabel.subviews[0];
    
    NSInteger number = 0;
    if (component == kComponentHours) {
        number = row;
    } else if (component == kComponentMinutes) {
        number = (row % _countOfMinuteSteps) * _step;
    }
    
    label.text = [NSString stringWithFormat:@"%lu", (long)number];
    
    return viewWithLabel;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kComponentViewHeight;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 106;
}


#pragma mark - UIPickerView delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    NSInteger hours = [pickerView selectedRowInComponent:kComponentHours];
    NSInteger mins = ([pickerView selectedRowInComponent:kComponentMinutes] % _countOfMinuteSteps) * _step;
    
    if ((_allowZeroTimeInterval == NO) && (hours == 0 && mins == 0)) {
        // Just scroll to the next row
        NSInteger currentlySelectedRow = [pickerView selectedRowInComponent:kComponentMinutes];
        [self selectRow:currentlySelectedRow + 1 inComponent:kComponentMinutes animated:YES];
    }
    
    if (component == kComponentHours && hours == _countOfHours) {
        if (mins > _maxMinutesRemainder) {
            // Limit to maxMinutesRemainder, because we are at the max hour and exceeded minutes.
            NSInteger remainderForCalculation = _maxMinutesRemainder == 0 ? 60 : _maxMinutesRemainder;
            NSInteger changeOfMinutes = remainderForCalculation - mins;
            if (changeOfMinutes > 30) {
                // Scroll the other way around
                changeOfMinutes = changeOfMinutes - 60;
            }
            NSInteger changeInSteps = changeOfMinutes / _step;
            if (changeInSteps == 0) {
                // We are over limit, but when divided by step, it gets rounded off to zero -> scroll down anyway.
                changeInSteps = -1;
            }
            NSInteger selectedRow = [self selectedRowInComponent:kComponentMinutes];
            [self selectRow:selectedRow + changeInSteps inComponent:kComponentMinutes animated:YES];
        }
    }
    if (component == kComponentMinutes && hours == _countOfHours) {
        // It was scrolled in the minutes component and we are at the top hour.
        // If we are over maxMinutesRemainder, scroll the hour down.
        if (mins > _maxMinutesRemainder) {
            [self selectRow:hours - 1 inComponent:kComponentHours animated:YES];
        }
    }
    
    // Recalculate time interval after all these possible adjustments above
    hours = [pickerView selectedRowInComponent:kComponentHours];
    mins = ([pickerView selectedRowInComponent:kComponentMinutes] % _countOfMinuteSteps) * _step;
    _timeInterval = ((mins + (hours * 60)) * 60);
    
    self.showingHoursPlural = (hours != 1);
    
    if (self.onTimeIntervalChanged) {
        self.onTimeIntervalChanged(_timeInterval);
    }
}


#pragma mark - Support for hours singular label

- (void)setShowingHoursPlural:(BOOL)showingHoursPlural {
    if (_showingHoursPlural == showingHoursPlural) {
        return;
    }
    _showingHoursPlural = showingHoursPlural;
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.2;
    
    [self.hoursLabel.layer addAnimation:animation forKey:@"kCAFadeTransition"];
    
    self.hoursLabel.text = showingHoursPlural ? NSLocalizedString(@"hours", nil) : NSLocalizedString(@"hour", nil);
}


@end
