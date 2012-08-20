// vim: ts=4:sw=4
/*
 * screenresolution sets the screen resolution on Mac computers.
 * Copyright (C) 2011  John Ford <john@johnford.info>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

#import <Foundation/Foundation.h>	 
#include "screenresolution.h"
#include "version.h"

int main (int argc, const char *argv[]) {
    // http://developer.apple.com/library/IOs/#documentation/CoreFoundation/Conceptual/CFStrings/Articles/MutableStrings.html
    int i;
    CFMutableStringRef args = CFStringCreateMutable(NULL, 0);
    CFStringEncoding encoding = CFStringGetSystemEncoding();
    CFStringAppend(args, CFSTR("starting screenresolution argv="));
    for (i = 0 ; i < argc ; i++) {
        CFStringAppendCString(args, argv[i], encoding);
        // If I were so motivated, I'd probably use CFStringAppendFormat
        CFStringAppend(args, CFSTR(" "));
    }
    // This has security implications.  Will look at that later
    NSLog(@"%@", args);
    unsigned int exitcode = 0;

    if (argc > 1) {
        int d;
        int keepgoing = 1;
        CGError rc;
        uint32_t displayCount = 0;
        uint32_t activeDisplayCount = 0;
        CGDirectDisplayID *activeDisplays = NULL;

        rc = CGGetActiveDisplayList(0, NULL, &activeDisplayCount);
        if (rc != kCGErrorSuccess) {
            NSLog(@"%@", @"Error: failed to get list of active displays");
            return 1;
        }
        // Allocate storage for the next CGGetActiveDisplayList call
        activeDisplays = (CGDirectDisplayID *) malloc(activeDisplayCount * sizeof(CGDirectDisplayID));
        if (activeDisplays == NULL) {
            NSLog(@"%@", @"Error: could not allocate memory for display list");
            return 1;
        }
        rc = CGGetActiveDisplayList(activeDisplayCount, activeDisplays, &displayCount);
        if (rc != kCGErrorSuccess) {
            NSLog(@"%@", @"Error: failed to get list of active displays");
            return 1;
        }

        // This loop should probably be in another function.
        for (d = 0; d < displayCount && keepgoing; d++) {
            if (strcmp(argv[1], "get") == 0) {
                if (!listCurrentMode(activeDisplays[d], d)) {
                    exitcode++;
                }
            } else if (strcmp(argv[1], "list") == 0) {
                if (!listAvailableModes(activeDisplays[d], d)) {
                    exitcode++;
                }
            } else if (strcmp(argv[1], "set") == 0) {
                if (d < (argc - 2)) {
                    if (strcmp(argv[d+2], "skip") == 0 && d < (argc - 2)) {
                        printf("Skipping display %d\n", d);
                    } else {
                        struct config newConfig;
                        if (parseStringConfig(argv[d + 2], &newConfig)) {
                            if (!configureDisplay(activeDisplays[d], &newConfig, d)) {
                                exitcode++;
                            }
                        } else {
                            exitcode++;
                        }
                    }
                }
            } else if (strcmp(argv[1], "-help") == 0) {
                // Send help information to stdout since it was requested
                printf("\n  screenresolution sets the screen resolution on Mac computers.\n\n");
                printf("  screenresolution version %s\n", VERSION);
                printf("  Licensed under GPLv2\n");
                printf("  Copyright (C) 2011  John Ford <john@johnford.info>\n\n");
                printf("  usage: screenresolution [get]    - Show the resolution of all active displays\n");
                printf("         screenresolution [list]   - Show available resolutions of all active displays\n");
                printf("         screenresolution [skip] [display1resolution] [display2resolution]\n");
                printf("                                   - Sets display resolution and refresh rate\n");
                printf("         screenresolution -version - Displays version information for screenresolution\n"); 
                printf("         screenresolution -help    - Displays this help information\n\n"); 
                printf("  examples: screenresolution 800x600x32            - Sets main display to 800x600x32\n");
                printf("            screenresolution 800x600x32 800x600x32 - Sets both displays to 800x600x32\n");
                printf("            screenresolution skip 800x600x32       - Sets second display to 800x600x32\n\n");
            } else if (strcmp(argv[1], "-version") == 0) {
                printf("screenresolution version %s\nLicensed under GPLv2\n", VERSION);
                keepgoing = 0;
            } else {
                NSLog(@"I'm sorry %@. I'm afraid I can't do that", [NSString stringWithCString:getlogin() encoding:NSUTF8StringEncoding]);
                // Send help information to stderr
                NSLog(@"%@", @"    Error: unable to copy current display mode\n\n");
                NSLog(@"    screenresolution version %@ -- Licensed under GPLv2\n\n\n", [NSString stringWithCString:VERSION encoding:NSUTF8StringEncoding]);
                NSLog(@"%@", @"     usage: screenresolution [get]  - Show the resolution of all active displays");
                NSLog(@"%@", @"            screenresolution [list] - Show available resolutions of all active displays");
                NSLog(@"%@", @"            screenresolution [skip] [display1resolution] [display2resolution]");
                NSLog(@"%@", @"                                    - Sets display resolution and refresh rate");
                NSLog(@"%@", @"            screenresolution -version - Displays version information for screenresolution");
                NSLog(@"%@", @"            screenresolution -help    - Displays this help information\n\n");
                NSLog(@"%@", @"     examples: screenresolution set 800x600x32            - Sets main display to 800x600x32");
                NSLog(@"%@", @"               screenresolution set 800x600x32 800x600x32 - Sets both displays to 800x600x32");
                NSLog(@"%@", @"               screenresolution skip 800x600x32       - Sets second display to 800x600x32\n\n");
                exitcode++;
                keepgoing = 0;
            }
        }
        free(activeDisplays);
        activeDisplays = NULL;
    } else {
        NSLog(@"%@", @"Incorrect command line");
        exitcode++;
    }
    return exitcode > 0;
}
