//
//  ScreenResolutionPreferencePane.m
//  ScreenResolutionPreferencePane
//
//  Created by Shazron Abdullah on 8/18/12.
//  Copyright (c) 2012 Shazron Abdullah. All rights reserved.
//

#import "ScreenResolutionPreferencePane.h"

@implementation ScreenResolutionPreferencePane

@synthesize bundleName, bundleVersion, bundleId;

- (void)mainViewDidLoad
{
    labelVersion.stringValue = [NSString stringWithFormat:@"%@ version %@", self.bundleName, self.bundleVersion];
    labelWarning.stringValue = @"This is the warning";
    
    CFPropertyListRef value = CFPreferencesCopyAppValue( CFSTR("SetMaxRetinaResolution"),  (CFStringRef)self.bundleId );
    if ( value && CFGetTypeID(value) == CFBooleanGetTypeID()  ) {
        [buttonSetMaxRetinaResolution setState:CFBooleanGetValue(value)];
    } else {
        [buttonSetMaxRetinaResolution setState:NO];
    }
}

- (id)initWithBundle:(NSBundle *)bundle
{
    if ( ( self = [super initWithBundle:bundle] ) != nil ) {
        NSString* name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        self.bundleName = [name stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        self.bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        self.bundleId = [bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        
        self.setMaxRetinaResolution = NO;
    }
    
    return self;
}

- (IBAction)checkboxClicked:(id)sender
{
    if ( [sender state] ) {
        CFPreferencesSetAppValue( CFSTR("SetMaxRetinaResolution"),
                                 kCFBooleanTrue, (CFStringRef)self.bundleId );
    } else {
        CFPreferencesSetAppValue( CFSTR("SetMaxRetinaResolution"),
                                 kCFBooleanFalse, (CFStringRef)self.bundleId );
    }
}

- (void)didUnselect
{
    if ( [buttonSetMaxRetinaResolution state] ) {
        CFPreferencesSetAppValue( CFSTR("SetMaxRetinaResolution"),
                                 kCFBooleanTrue, (CFStringRef)self.bundleId );
    } else {
        CFPreferencesSetAppValue( CFSTR("SetMaxRetinaResolution"),
                                 kCFBooleanFalse, (CFStringRef)self.bundleId );
    }
    
    // if we had actual apps, we would post a notification
}

@end
