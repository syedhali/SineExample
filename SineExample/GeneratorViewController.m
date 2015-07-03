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

#import "GeneratorViewController.h"

double const SAMPLE_RATE = 44100.0;

typedef NS_ENUM(NSUInteger, GeneratorType)
{
    GeneratorTypeSine,
    GeneratorTypeSquare,
    GeneratorTypeTriangle,
    GeneratorTypeSawtooth,
    GeneratorTypeNoise,
};

@interface GeneratorViewController ()
@property (assign) GeneratorType type;
@property (nonatomic) double amplitude;
@property (nonatomic) double frequency;
@property (nonatomic) double sampleRate;
@property (nonatomic) double step;
@property (nonatomic) double theta;
@end

@implementation GeneratorViewController

//------------------------------------------------------------------------------
#pragma mark - Customize the Audio Plot
//------------------------------------------------------------------------------

- (void)awakeFromNib
{
    //
    // Customizing the audio plot's look
    //
    self.audioPlot.backgroundColor = [NSColor colorWithCalibratedRed: 0.557 green: 0.651 blue: 0.898 alpha: 1];
    self.audioPlot.color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldFill = NO;
    
    //
    // Create EZOutput to play audio data
    //
    AudioStreamBasicDescription inputFormat = [EZAudioUtilities monoFloatFormatWithSampleRate:SAMPLE_RATE];
    self.output = [EZOutput outputWithDataSource:self inputFormat:inputFormat];
    [self.output setDelegate:self];
    self.frequency = 200.0;
    self.sampleRate = inputFormat.mSampleRate;
    self.amplitude = 0.80;
    
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
    self.generatorTypeSegmentedControl.selectedSegment = self.type;
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (void)changeFrequency:(id)sender
{
    float value = [(NSSlider *)sender floatValue];
    self.frequency = value;
}

- (void)changeGeneratorType:(id)sender
{
    NSSegmentedControl *segmentControl = (NSSegmentedControl *)sender;
    self.type = [segmentControl selectedSegment];
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
    self.audioPlot.shouldMirror = NO;
}

//------------------------------------------------------------------------------

-(void)drawRollingPlot
{
    self.audioPlot.plotType = EZPlotTypeRolling;
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
    Float32 *buffer = (Float32 *)audioBufferList->mBuffers[0].mData;
    size_t bufferByteSize = (size_t)audioBufferList->mBuffers[0].mDataByteSize;
    double theta = self.theta;
    double frequency = self.frequency;
    double thetaIncrement = 2.0 * M_PI * frequency / SAMPLE_RATE;
    if (self.type == GeneratorTypeSine)
    {
        for (UInt32 frame = 0; frame < frames; frame++)
        {
            buffer[frame] = self.amplitude * sin(theta);
            theta += thetaIncrement;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }
        self.theta = theta;
    }
    else if (self.type == GeneratorTypeNoise)
    {
        for (UInt32 frame = 0; frame < frames; frame++)
        {
            buffer[frame] = self.amplitude * ((float)rand()/RAND_MAX) * 2.0f - 1.0f;
        }
    }
    else if (self.type == GeneratorTypeSquare)
    {
        for (UInt32 frame = 0; frame < frames; frame++)
        {
            buffer[frame] = self.amplitude * [EZAudioUtilities SGN:theta];
            theta += thetaIncrement;
            if (theta > 2.0 * M_PI)
            {
                theta -= 4.0 * M_PI;
            }
        }
        self.theta = theta;
    }
    else if (self.type == GeneratorTypeTriangle)
    {
        double samplesPerWavelength = SAMPLE_RATE / self.frequency;
        double ampStep = 2.0 / samplesPerWavelength;
        double step = self.step;
        for (UInt32 frame = 0; frame < frames; frame++)
        {
            if (step > 1.0)
            {
                step = 1.0;
                ampStep = -ampStep;
            }
            else if (step < -1.0)
            {
                step = -1.0;
                ampStep = -ampStep;
            }
            step += ampStep;
            buffer[frame] = self.amplitude * step;
        }
        self.step = step;
    }
    else if (self.type == GeneratorTypeSawtooth)
    {
        double samplesPerWavelength = SAMPLE_RATE / self.frequency;
        double ampStep = 1.0 / samplesPerWavelength;
        double step = self.step;
        for (UInt32 frame = 0; frame < frames; frame++)
        {
            if (step > 1.0)
            {
                step = -1.0;
            }
            step += ampStep;
            buffer[frame] = self.amplitude * step;
        }
        self.step = step;
    }
    else
    {
        memset(buffer, 0, bufferByteSize);
    }
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
