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

#include "screenresolution.h"
	 
 size_t bitDepth(CGDisplayModeRef mode) {
     size_t depth = 0;
 	CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding(mode);
     // my numerical representation for kIO16BitFloatPixels and kIO32bitFloatPixels
     // are made up and possibly non-sensical
     if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO32BitFloatPixels), kCFCompareCaseInsensitive)) {
         depth = 96;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO64BitDirectPixels), kCFCompareCaseInsensitive)) {
         depth = 64;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO16BitFloatPixels), kCFCompareCaseInsensitive)) {
         depth = 48;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive)) {
         depth = 32;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(kIO30BitDirectPixels), kCFCompareCaseInsensitive)) {
         depth = 30;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive)) {
         depth = 16;
     } else if (kCFCompareEqualTo == CFStringCompare(pixelEncoding, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive)) {
         depth = 8;
     }
     CFRelease(pixelEncoding);
     return depth;
 }

 unsigned int configureDisplay(CGDirectDisplayID display, struct config *config, int displayNum) {
     unsigned int returncode = 1;
     CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
     if (allModes == NULL) {
         NSLog(CFSTR("Error: failed trying to look up modes for display %u"), displayNum);
     }

     CGDisplayModeRef newMode = NULL;
     CGDisplayModeRef possibleMode;
     size_t pw; // possible width.
     size_t ph; // possible height.
     size_t pd; // possible depth.
     double pr; // possible refresh rate
     int looking = 1; // used to decide whether to continue looking for modes.
     int i;
     for (i = 0 ; i < CFArrayGetCount(allModes) && looking; i++) {
         possibleMode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
         pw = CGDisplayModeGetWidth(possibleMode);
         ph = CGDisplayModeGetHeight(possibleMode);
         pd = bitDepth(possibleMode);
         pr = CGDisplayModeGetRefreshRate(possibleMode);
         if (pw == config->w &&
             ph == config->h &&
             pd == config->d &&
             pr == config->r) {
             looking = 0; // Stop looking for more modes!
             newMode = possibleMode;
         }
     }
     CFRelease(allModes);
     if (newMode != NULL) {
         NSLog(CFSTR("set mode on display %u to %ux%ux%u@%.0f"), displayNum, pw, ph, pd, pr);
         setDisplayToMode(display,newMode);
     } else {
         NSLog(CFSTR("Error: mode %ux%ux%u@%f not available on display %u"), 
                 config->w, config->h, config->d, config->r, displayNum);
         returncode = 0;
     }
     return returncode;
 }

 unsigned int setDisplayToMode(CGDirectDisplayID display, CGDisplayModeRef mode) {
     CGError rc;
     CGDisplayConfigRef config;
     rc = CGBeginDisplayConfiguration(&config);
     if (rc != kCGErrorSuccess) {
         NSLog(CFSTR("Error: failed CGBeginDisplayConfiguration err(%u)"), rc);
         return 0;
     }
     rc = CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
     if (rc != kCGErrorSuccess) {
         NSLog(CFSTR("Error: failed CGConfigureDisplayWithDisplayMode err(%u)"), rc);
         return 0;
     }
     rc = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
     if (rc != kCGErrorSuccess) {
         NSLog(CFSTR("Error: failed CGCompleteDisplayConfiguration err(%u)"), rc);        
         return 0;
     }
     return 1;
 }

 unsigned int listCurrentMode(CGDirectDisplayID display, int displayNum) {
     unsigned int returncode = 1;
     CGDisplayModeRef currentMode = CGDisplayCopyDisplayMode(display);
     if (currentMode == NULL) {
         NSLog(CFSTR("%s"), "Error: unable to copy current display mode");
         returncode = 0;
     }
     NSLog(CFSTR("Display %d: %ux%ux%u@%.0f"),
            displayNum,
            CGDisplayModeGetWidth(currentMode),
            CGDisplayModeGetHeight(currentMode),
            bitDepth(currentMode),
            CGDisplayModeGetRefreshRate(currentMode));
     CGDisplayModeRelease(currentMode);
     return returncode;
 }

 unsigned int listAvailableModes(CGDirectDisplayID display, int displayNum) {
     unsigned int returncode = 1;
     int i;
     CFArrayRef allModes = CGDisplayCopyAllDisplayModes(display, NULL);
     if (allModes == NULL) {
         returncode = 0;
     }
 #ifndef LIST_DEBUG
     printf("Available Modes on Display %d\n", displayNum);

 #endif
     CGDisplayModeRef mode;
     for (i = 0; i < CFArrayGetCount(allModes) && returncode; i++) {
         mode = (CGDisplayModeRef) CFArrayGetValueAtIndex(allModes, i);
         // This formatting is functional but it ought to be done less poorly.
 #ifndef LIST_DEBUG
         if (i % MODES_PER_LINE == 0) {
             printf("  ");
         } else {
             printf("\t");
         }
         char modestr [50];
         sprintf(modestr, "%lux%lux%lu@%.0f",
                CGDisplayModeGetWidth(mode),
                CGDisplayModeGetHeight(mode),
                bitDepth(mode),
                CGDisplayModeGetRefreshRate(mode));
         printf("%-20s ", modestr);
         if (i % MODES_PER_LINE == MODES_PER_LINE - 1) {
             printf("\n");
         }
 #else
         uint32_t ioflags = CGDisplayModeGetIOFlags(mode);
         printf("display: %d %4lux%4lux%2lu@%.0f usable:%u ioflags:%4x valid:%u safe:%u default:%u",
                 displayNum,
                 CGDisplayModeGetWidth(mode),
                 CGDisplayModeGetHeight(mode),
                 bitDepth(mode),
                 CGDisplayModeGetRefreshRate(mode),
                 CGDisplayModeIsUsableForDesktopGUI(mode),
                 ioflags,
                 ioflags & kDisplayModeValidFlag ?1:0,
                 ioflags & kDisplayModeSafeFlag ?1:0,
                 ioflags & kDisplayModeDefaultFlag ?1:0 );
         printf(" safety:%u alwaysshow:%u nevershow:%u notresize:%u requirepan:%u int:%u simul:%u",
                 ioflags & kDisplayModeSafetyFlags ?1:0,
                 ioflags & kDisplayModeAlwaysShowFlag ?1:0,
                 ioflags & kDisplayModeNeverShowFlag ?1:0,
                 ioflags & kDisplayModeNotResizeFlag ?1:0,
                 ioflags & kDisplayModeRequiresPanFlag ?1:0,
                 ioflags & kDisplayModeInterlacedFlag ?1:0,
                 ioflags & kDisplayModeSimulscanFlag ?1:0 );
         printf(" builtin:%u notpreset:%u stretched:%u notgfxqual:%u valagnstdisp:%u tv:%u vldmirror:%u\n",
                 ioflags & kDisplayModeBuiltInFlag ?1:0,
                 ioflags & kDisplayModeNotPresetFlag ?1:0,
                 ioflags & kDisplayModeStretchedFlag ?1:0,
                 ioflags & kDisplayModeNotGraphicsQualityFlag ?1:0,
                 ioflags & kDisplayModeValidateAgainstDisplay ?1:0,
                 ioflags & kDisplayModeTelevisionFlag ?1:0,
                 ioflags & kDisplayModeValidForMirroringFlag ?1:0 );
 #endif
     }
     CFRelease(allModes);
     return returncode;
 }

 unsigned int parseStringConfig(const char *string, struct config *out) {
     unsigned int rc;
     size_t w;
     size_t h;
     size_t d;
     double r;
     int numConverted = sscanf(string, "%lux%lux%lu@%lf", &w, &h, &d, &r);
     if (numConverted != 4) {
         rc = 0;
         NSLog(CFSTR("Error: the mode '%s' couldn't be parsed"), string);
     } else {
         out->w = w;
         out->h = h;
         out->d = d;
         out->r = r;
         rc = 1;
     }
     return rc;
 }
