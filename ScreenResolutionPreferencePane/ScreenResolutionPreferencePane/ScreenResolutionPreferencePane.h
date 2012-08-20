//
//  ScreenResolutionPreferencePane.h
//  ScreenResolutionPreferencePane
//
//  Created by Shazron Abdullah on 8/18/12.
//  Copyright (c) 2012 Shazron Abdullah. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <Foundation/Foundation.h>
#import "screenresolution.h"

@interface MaxRetinaConfig : NSObject {
}

@property (nonatomic, assign) struct config current;
@property (nonatomic, assign,getter=isEnabled) BOOL enabled;
@property (nonatomic, assign,getter=isConfigurable) BOOL configurable;
@property (nonatomic, assign) CGDisplayModeRef displayMode;
@property (nonatomic, assign) CGDisplayModeRef scaledMode;
@property (nonatomic, assign) CGDirectDisplayID displayId;

@end

@interface ScreenResolutionPreferencePane : NSPreferencePane
{
    IBOutlet NSTextField* labelLink;
    IBOutlet NSTextField* labelVersion;
    IBOutlet NSTextField* labelWarning;
    IBOutlet NSButton* buttonSetMaxRetinaResolution;
}

@property (nonatomic, copy) NSString* bundleName;
@property (nonatomic, copy) NSString* bundleVersion;
@property (nonatomic, copy) NSString* bundleId;
@property (retain) MaxRetinaConfig* retinaConfig;

- (void)mainViewDidLoad;
- (id)initWithBundle:(NSBundle *)bundle;
- (void) updateUserInterface;
- (IBAction) linkClicked:(id)sender;
- (IBAction) imageClicked:(id)sender;

@end
