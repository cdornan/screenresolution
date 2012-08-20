//
//  ScreenResolutionPreferencePane.m
//  ScreenResolutionPreferencePane
//
//  Created by Shazron Abdullah on 8/18/12.
//  Copyright (c) 2012 Shazron Abdullah. All rights reserved.
//

#import "ScreenResolutionPreferencePane.h"
#import "screenresolution.h"

#define MAX_RETINA_WIDTH        2880
#define MAX_RETINA_HEIGHT       1800
#define MAX_RETINA_BIT_DEPTH    32

void MyDisplayReconfigurationCallBack (
                                       CGDirectDisplayID display,
                                       CGDisplayChangeSummaryFlags flags,
                                       void *userInfo)
{
    ScreenResolutionPreferencePane* pane = (ScreenResolutionPreferencePane*)userInfo;
    [pane updateUserInterface];
}

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    return [attrString autorelease];
}
@end

@implementation MaxRetinaConfig

@synthesize current, enabled, configurable, scaledMode, displayMode, displayId;

- (id) init
{
    if ((self = [super init]) != nil) {
        self.displayMode = NULL;
        self.scaledMode = NULL;
    }
    
    return self;
}

- (void) dealloc
{
    if (self.displayMode != NULL) {
        CGDisplayModeRelease(self.displayMode);
    }
    if (self.scaledMode != NULL) {
        CGDisplayModeRelease(self.scaledMode);
    }
    [super dealloc];
}

@end

@implementation ScreenResolutionPreferencePane

@synthesize bundleName, bundleVersion, bundleId, retinaConfig;

- (void) mainViewDidLoad
{
    [self updateUserInterface];
}

-(void)setHyperlink:(NSString*)hyperlink withTextField:(NSTextField*)inTextField andCaption:(NSString*)caption
{
    // both are needed, otherwise hyperlink won't accept mousedown
    [inTextField setAllowsEditingTextAttributes: YES];
    [inTextField setSelectable: YES];
    
    NSURL* url = [NSURL URLWithString:hyperlink];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:caption withURL:url]];
    
    // set the attributed string to the NSTextField
    [inTextField setAttributedStringValue: string];
    
    [string release];
}

- (void) updateUserInterface
{
    labelVersion.stringValue = [NSString stringWithFormat:@"%@ v%@", self.bundleName, self.bundleVersion];
    labelWarning.stringValue = @"";
    
    [self setHyperlink:labelLink.stringValue withTextField:labelLink andCaption:labelLink.stringValue];
    
    [self updateRetinaConfig];
    buttonSetMaxRetinaResolution.title = [NSString stringWithFormat:NSLocalizedString(@"set maximum %zux%zu resolution", nil), retinaConfig.current.w, retinaConfig.current.h];
    
    if (self.retinaConfig.isConfigurable) {
        [labelWarning setHidden:YES];
        [buttonSetMaxRetinaResolution setHidden:NO];
        [buttonSetMaxRetinaResolution setState:self.retinaConfig.isEnabled];
    } else {
        [labelWarning setHidden:NO];
        labelWarning.stringValue = NSLocalizedString(@"You do not have a connected retina display.", nil);
        [buttonSetMaxRetinaResolution setEnabled:NO];
    }
}

- (id) initWithBundle:(NSBundle *)bundle
{
    if ( ( self = [super initWithBundle:bundle] ) != nil ) {
        NSString* name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        self.bundleName = [name stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        self.bundleVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        self.bundleId = [bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        
        self.retinaConfig = nil;
        CGDisplayRegisterReconfigurationCallback (MyDisplayReconfigurationCallBack, self);
    } 
    
    return self;
}

- (void) updateRetinaConfig
{
    CGError rc;
    uint32_t displayCount = 0;
    uint32_t activeDisplayCount = 0;
    CGDirectDisplayID *activeDisplays = NULL;

    self.retinaConfig = [MaxRetinaConfig new];

    rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
    if (rc != kCGErrorSuccess) {
        labelWarning.stringValue = NSLocalizedString(@"Error: failed to get list of active displays", nil);
        return;
    }
    // Allocate storage for the next CGGetActiveDisplayList call
    activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
    if (activeDisplays == NULL) {
        labelWarning.stringValue = NSLocalizedString(@"Error: could not allocate memory for display list", nil);
        return;
    }
    rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
    if (rc != kCGErrorSuccess) {
        labelWarning.stringValue = NSLocalizedString(@"Error: failed to get list of active displays", nil);
        return;
    }
    
    for (int i=0; i < activeDisplayCount; ++i) {
                
        CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(activeDisplays[i]);
        
        struct config config;
        config.w = CGDisplayModeGetWidth(currentMode);
        config.h = CGDisplayModeGetHeight(currentMode);
        config.d = bitDepth(currentMode);
        config.r = CGDisplayModeGetRefreshRate(currentMode);
        
        if (config.w == MAX_RETINA_WIDTH && config.h == MAX_RETINA_HEIGHT && config.d == MAX_RETINA_BIT_DEPTH) {
            self.retinaConfig.current = config;
            self.retinaConfig.enabled = YES;
        }
        
        CGDisplayModeRelease(currentMode);
        
        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(activeDisplays[i], NULL);
        if (allModes == NULL) {
            return;
        }
        
        size_t allModesCount = CFArrayGetCount(allModes);
        for (int j = 0; j < allModesCount; j++) {
            CGDisplayModeRef currentMode = (CGDisplayModeRef) CFArrayGetValueAtIndex(allModes, j);
            
            struct config config;
            config.w = CGDisplayModeGetWidth(currentMode);
            config.h = CGDisplayModeGetHeight(currentMode);
            config.d = bitDepth(currentMode);
            config.r = CGDisplayModeGetRefreshRate(currentMode);
            
            if (config.w == MAX_RETINA_WIDTH && config.h == MAX_RETINA_HEIGHT && config.d == MAX_RETINA_BIT_DEPTH) {
                self.retinaConfig.current = config;
                self.retinaConfig.configurable = YES;
                self.retinaConfig.displayMode = CGDisplayModeRetain(currentMode);
                self.retinaConfig.displayId = activeDisplays[i];
            }
            
            if (config.w == (MAX_RETINA_WIDTH/2) && config.h == (MAX_RETINA_HEIGHT/2) && config.d == MAX_RETINA_BIT_DEPTH) {
                self.retinaConfig.scaledMode = CGDisplayModeRetain(currentMode);
            }

            //NSLog(@"w: %zu h: %zu d: %zu r: %f", config.w, config.h, config.d, config.r);
        }
    }
}

- (IBAction) checkboxClicked:(id)sender
{
    if ([sender state]) {
        if (self.retinaConfig.displayMode != NULL) {
            //CGDisplayCopyDisplayMode(self.retinaConfig.displayId);
            setDisplayToMode(self.retinaConfig.displayId, self.retinaConfig.displayMode);
        }
        
    } else if (self.retinaConfig.scaledMode != NULL) {
        setDisplayToMode(self.retinaConfig.displayId, self.retinaConfig.scaledMode);
        
    }
}

- (void) didUnselect
{
    // if we had actual apps, we would post a notification
}

- (IBAction) linkClicked:(id)sender
{
    NSString* url = labelLink.stringValue;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction) imageClicked:(id)sender
{
    NSString* url = @"http://www.gettyicons.com/free-icon/101/hallowen-icon-set/free-eye-icon-png/";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void) dealloc
{
    self.bundleName = nil;
    self.bundleId = nil;
    self.bundleVersion = nil;
    self.retinaConfig = nil;
    
    [super dealloc];
}

@end
