//
//  PlayFileViewController.h
//  EZAudioPlayFileExample
//
//  Created by Syed Haris Ali on 12/1/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Cocoa/Cocoa.h>

// Import EZAudio header
#import "EZAudio.h"

/**
 Using the EZOutputDataSource to provide output data to the EZOutput component. 
 */
@interface GeneratorViewController : NSViewController <NSOpenSavePanelDelegate,
                                                       EZOutputDataSource,
                                                       EZOutputDelegate>

#pragma mark - Components
/**
 The EZAudioFile representing of the currently selected audio file
 */
@property (nonatomic, strong) EZAudioFile *audioFile;

/**
 The EZOutput component used to output the audio file's audio data.
 */
@property (nonatomic, strong) EZOutput *output;

/**
 The CoreGraphics based audio plot
 */
@property (nonatomic, weak) IBOutlet EZAudioPlotGL *audioPlot;


@property (nonatomic, weak) IBOutlet NSSlider *frequencySlider;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *generatorTypeSegmentedControl;

/**
 A label to display the audio file's current position.
 */
@property (nonatomic, weak) IBOutlet NSTextField *positionLabel;

/**
 A slider to indicate the current frame position in the audio file
 */
@property (nonatomic, weak) IBOutlet NSSlider *positionSlider;

/**
 A label to display the value of the rolling history length of the audio plot.
 */
@property (nonatomic, weak) IBOutlet NSTextField *rollingHistoryLengthLabel;

/**
 A slider to adjust the rolling history length of the audio plot.
 */
@property (nonatomic, weak) IBOutlet NSSlider *rollingHistoryLengthSlider;

/**
 A slider to adjust the volume.
 */
@property (nonatomic, weak) IBOutlet NSSlider *volumeSlider;

/**
 A label to display the volume of the audio plot.
 */
@property (nonatomic, weak) IBOutlet NSTextField *volumeLabel;

/**
 The microphone pop up button (contains the menu for choosing a microphone input)
 */
@property (nonatomic, weak) IBOutlet NSPopUpButton *outputDevicePopUpButton;

#pragma mark - Actions

- (IBAction)changeFrequency:(id)sender;
- (IBAction)changeGeneratorType:(id)sender;

/**
 Switches the plot drawing type between a buffer plot (visualizes the current stream of audio data from the update function) or a rolling plot (visualizes the audio data over time, this is the classic waveform look)
 */
-(IBAction)changePlotType:(id)sender;

/**
 Changes the length of the rolling history of the audio plot.
 */
- (IBAction)changeRollingHistoryLength:(id)sender;

/**
 Changes the volume of the audio coming out of the EZOutput.
 */
- (IBAction)changeVolume:(id)sender;

/**
 Begins playback if a file is loaded. Pauses if the file is already playing.
 */
-(IBAction)play:(id)sender;

@end
