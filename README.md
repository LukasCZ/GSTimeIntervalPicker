## GSTimeIntervalPicker

A UI component for picking time interval, with support of setting upper time interval limit.

![](sample.gif)

[Video z té sample app]

## Why this exist?
When building Reminders in [Timelines](http://timelinesapp.io), I stumbled upon the need of letting user pick a time interval between 0 and 3 hours. UIDatePicker in its .CountDownTimer mode supports almost what I needed, but not quite - there is no way how to limit the time interval. With this class, I attempted to fully replicate this UIDatePicker-countDownTimer behaviour, while adding the support to limit the interval.

## Features

* Allows limiting the time interval
* Appearance matches exactly that of UIDatePicker in countDownTimer mode
* *hours* label changes to *hour* when 1 hour is selected
* informs of changes using callback block `^onTimeIntervalChanged(NSTimeInterval interval)`
* supports setting step (1 min, 5 min, 20 min etc.), same as in UIDatePicker
* when `maxTimeInterval` is bigger than 1 hour, minutes can be scrolled infinitely.
* direct subclass of `UIPickerView` - you get the same sizing as with date pickers

## How do I use it?

Since GSTimeIntervalPicker is a subclass of UIPickerView, it carries its intrinsic content size and therefore plays nicely with Autolayout, inputViews and self sizing cells.

```
GSTimeIntervalPicker *picker = [[GSTimeIntervalPicker alloc] init];
picker.maxTimeInterval = (3600 * 3);    // set the limit
picker.minuteInterval = 5;
picker.timeInterval = (3600 * 1.5);    	// 1 h 45 minutes
picker.onTimeIntervalChanged = ^(NSTimeInterval newTimeInterval) {
	// Use the value
};
```

**As an inputView**

Simply assign the picker to the `inputView` property like so:
myFirstResponderObject.inputView = picker;

**As a self-sizing cell**
Create a cell and place this picker inside of it, pinning it to all 4 sides. I prefer using Storyboards and prototype cells for that:

1. Make your cell 217 points tall.
2. Drag a UIPickerView into your cell, and set its class to `GSTimeIntervalPicker` in the Identity Inspector
3. Pin it to all 4 sides, like so:

[[ Screenshot toho self-sizeování ]]

<img src="xib_sizing-1x.png" width="696px" srcset="xib_sizing-1x.png 1x, xib_sizing-2x.png 2x">

To see how this works, try out the sample app attached with this code.

**As just a view in your view controller**
That's pretty much the same as using it in the table view cell, and more details are beyond the scope of this readme.

---

I hope you'll find this helpful :). And - I know, it's not in Swift! I might convert it one day. For now, take it as an exercise.

If you have any questions, you can contact me on Twitter <a href="http://twitter.com/luksape target="_blank">@luksape</a>.
