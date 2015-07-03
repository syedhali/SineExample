//
//  PlayFileViewController.m
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

#import "PlayFileViewController.h"

double const SAMPLE_RATE = 44100;

@interface PlayFileViewController ()
@property (nonatomic) double frequency;
@property (nonatomic) double sampleRate;
@property (nonatomic) double theta;
@end

@implementation PlayFileViewController

//------------------------------------------------------------------------------
#pragma mark - Customize the Audio Plot
//------------------------------------------------------------------------------

- (void)awakeFromNib
{
    //
    // Customizing the audio plot's look
    //
    // Background color
    self.audioPlot.backgroundColor = [NSColor colorWithCalibratedRed: 0.816 green: 0.349 blue: 0.255 alpha: 1];
    // Waveform color
    self.audioPlot.color           = [NSColor colorWithCalibratedRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill      = YES;
    // Mirror
    self.audioPlot.shouldMirror    = YES;
    
    //
    // Create EZOutput to play audio data
    //
    AudioStreamBasicDescription inputFormat = [EZAudioUtilities monoFloatFormatWithSampleRate:SAMPLE_RATE];
    self.output = [EZOutput outputWithDataSource:self inputFormat:inputFormat];
    [self.output setDelegate:self];
    self.frequency = 200.0;
    self.sampleRate = inputFormat.mSampleRate;
    
    //
    // Reload the menu for the output device selector popup button
    //
    [self reloadOutputDevicePopUpButtonMenu];
    
    //
    // Configure UI components
    //
    self.frequencySlider.floatValue = self.frequency;
    self.volumeSlider.floatValue = [self.output volume];
    self.volumeLabel.floatValue = [self.output volume];
    self.rollingHistoryLengthSlider.intValue = [self.audioPlot rollingHistoryLength];
    self.rollingHistoryLengthLabel.intValue = [self.audioPlot rollingHistoryLength];
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (void)changeFrequency:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    self.frequency = value;
}

- (void)changedOutput:(NSMenuItem *)item
{
    EZAudioDevice *device = [item representedObject];
    [self.output setDevice:device];
}

//------------------------------------------------------------------------------

- (void)changePlotType:(id)sender
{
    NSInteger selectedSegment = [sender selectedSegment];
    switch(selectedSegment)
    {
        case 0:
            [self drawBufferPlot];
            break;
        case 1:
            [self drawRollingPlot];
            break;
        default:
            break;
    }
}

//------------------------------------------------------------------------------

- (void)changeVolume:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    [self.output setVolume:value];
    self.volumeLabel.floatValue = value;
}

//------------------------------------------------------------------------------

- (void)changeRollingHistoryLength:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    self.audioPlot.rollingHistoryLength = (int)value;
    self.rollingHistoryLengthLabel.floatValue = value;
}

//------------------------------------------------------------------------------

-(void)play:(id)sender
{
    if (![self.output isPlaying])
    {
        if (self.audioPlot.plotType == EZPlotTypeBuffer && self.audioPlot.shouldFill == YES)
        {
            self.audioPlot.plotType = EZPlotTypeRolling;
        }
        [self.output startPlayback];
    }
    else
    {
        [self.output stopPlayback];
    }
}

//------------------------------------------------------------------------------
#pragma mark - Action Extensions
//------------------------------------------------------------------------------

-(void)drawBufferPlot
{
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldFill = NO;
    self.audioPlot.shouldMirror = NO;
}

//------------------------------------------------------------------------------

-(void)drawRollingPlot
{
    self.audioPlot.plotType = EZPlotTypeRolling;
    self.audioPlot.shouldFill = YES;
    self.audioPlot.shouldMirror = YES;
}

//------------------------------------------------------------------------------

- (void)reloadOutputDevicePopUpButtonMenu
{
    NSArray *outputDevices = [EZAudioDevice outputDevices];
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *defaultOutputDeviceItem;
    for (EZAudioDevice *device in outputDevices)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:device.name
                                                      action:@selector(changedOutput:)
                                               keyEquivalent:@""];
        item.representedObject = device;
        item.target = self;
        [menu addItem:item];
        
        // If this device is the same one the microphone is using then
        // we will use this menu item as the currently selected item
        // in the microphone input popup button's list of items. For instance,
        // if you are connected to an external display by default the external
        // display's microphone might be used instead of the mac's built in
        // mic.
        if ([device isEqual:[self.output device]])
        {
            defaultOutputDeviceItem = item;
        }
    }
    self.outputDevicePopUpButton.menu = menu;
    
    //
    // Set the selected device to the current selection on the
    // microphone input popup button
    //
    [self.outputDevicePopUpButton selectItem:defaultOutputDeviceItem];
}

//------------------------------------------------------------------------------
#pragma mark - EZOutputDataSource
//------------------------------------------------------------------------------

- (OSStatus)        output:(EZOutput *)output
 shouldFillAudioBufferList:(AudioBufferList *)audioBufferList
        withNumberOfFrames:(UInt32)frames
                 timestamp:(const AudioTimeStamp *)timestamp
{
    double theta = self.theta;
    double frequency = self.frequency;
    double theta_increment = 2.0 * M_PI * frequency / SAMPLE_RATE;
    const int channel = 0;
    Float32 *buffer = (Float32 *)audioBufferList->mBuffers[channel].mData;
    for (UInt32 frame = 0; frame < frames; frame++)
    {
        buffer[frame] = sin(theta);
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    self.theta = theta;
    return noErr;
}

//------------------------------------------------------------------------------
#pragma mark - EZOutputDelegate
//------------------------------------------------------------------------------

- (void)       output:(EZOutput *)output
          playedAudio:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.audioPlot updateBuffer:buffer[0]
                          withBufferSize:bufferSize];
    });
}

//------------------------------------------------------------------------------

@end
