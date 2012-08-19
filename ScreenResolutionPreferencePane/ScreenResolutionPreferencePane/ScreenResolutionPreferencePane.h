//
//  ScreenResolutionPreferencePane.h
//  ScreenResolutionPreferencePane
//
//  Created by Shazron Abdullah on 8/18/12.
//  Copyright (c) 2012 Shazron Abdullah. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <Foundation/Foundation.h>

@interface ScreenResolutionPreferencePane : NSPreferencePane
{
    IBOutlet NSTextField* labelVersion;
    IBOutlet NSTextField* labelWarning;
    IBOutlet NSButton* buttonSetMaxRetinaResolution;
}

@property (nonatomic, copy) NSString* bundleName;
@property (nonatomic, copy) NSString* bundleVersion;
@property (nonatomic, copy) NSString* bundleId;
@property (nonatomic, assign) BOOL setMaxRetinaResolution;

- (void)mainViewDidLoad;
- (id)initWithBundle:(NSBundle *)bundle;

@end
