#!/usr/bin/env make -f
# Makefile to build and test screenresolution
# Monday August 29, 2011
# John Ford <john@johnford.info>
# ToDo:
#   -find a standard way to check on resolution that *isn't* screenresolution
#   -use program from above to figure out original resolution
#   -convert test target to a shell script
#   -figure out of lipo is the best way to make a universal binary on cmdline

PREFIX=/usr/local

ORIG_RES=1920x1200x32
TEST_RES=800x600x32
VERSION=1.6

CC=clang
LIPO=lipo
PACKAGE_MAKER=/Developer/usr/bin/packagemaker

build: screenresolution prefpane

screenresolution: screenresolution32 screenresolution64
	$(LIPO) -arch i386 screenresolution32 -arch x86_64 screenresolution64 \
		-create -output screenresolution
		
%.o32: %.mm version.h screenresolution.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -m32 -o $@ $<

%.o64: %.mm version.h screenresolution.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -m64 -o $@ $<

screenresolution32: main.o32 screenresolution.o32
	$(CC) $(CPPFLAGS) $(CFLAGS) -framework Foundation -framework ApplicationServices $^ -m32 -o $@

screenresolution64: main.o64 screenresolution.o64
	$(CC) $(CPPFLAGS) $(CFLAGS) -framework Foundation -framework ApplicationServices $^ -m64 -o $@

version.h:
	sed -e "s/@VERSION@/\"$(VERSION)\"/" < version-tmpl.h > version.h

clean:
	rm -f screenresolution screenresolution32 screenresolution64 \
		screenresolution-$(VERSION).pkg screenresolution-$(VERSION).dmg \
		version.h *.o32 *.o64 *.o
	rm -rf ScreenResolution.prefPane
	rm -rf pkgroot dmgroot

reallyclean: clean
	rm -f *.pkg *.dmg

test: screenresolution
	@echo Going to set screen resolutions between $(ORIG_RES) and $(TEST_RES)
	./screenresolution get | wc -l | grep 2
	./screenresolution get
	./screenresolution set $(TEST_RES) $(TEST_RES)
	sleep 1
	./screenresolution get | grep "Display 0: $(TEST_RES)"
	./screenresolution get | grep "Display 1: $(TEST_RES)"
	./screenresolution set $(ORIG_RES) $(ORIG_RES)
	sleep 1
	./screenresolution get | grep "Display 0: $(ORIG_RES)"
	./screenresolution get | grep "Display 1: $(ORIG_RES)"
	./screenresolution set skip $(TEST_RES)
	sleep 1
	./screenresolution get | grep "Display 0: $(ORIG_RES)"
	./screenresolution get | grep "Display 1: $(TEST_RES)"
	./screenresolution set $(ORIG_RES) $(ORIG_RES)
	sleep 1
	./screenresolution get | grep "Display 0: $(ORIG_RES)"
	./screenresolution get | grep "Display 1: $(ORIG_RES)"
	./screenresolution set $(TEST_RES)
	sleep 1
	./screenresolution get | grep "Display 0: $(TEST_RES)"
	./screenresolution get | grep "Display 1: $(ORIG_RES)"
	@echo If you got this far, I think it works!
	./screenresolution set $(ORIG_RES) $(ORIG_RES)
	@echo resolution back to normal

install: screenresolution
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	install -s -m 0755 screenresolution \
		$(DESTDIR)/$(PREFIX)/bin/

prefpane: screenresolution
	xcodebuild -project ScreenResolutionPreferencePane/ScreenResolutionPreferencePane.xcodeproj clean build TARGET_BUILD_DIR=".."

pkg: screenresolution
	mkdir -p pkgroot/$(PREFIX)/bin
	install -s -m 0755 screenresolution \
		pkgroot/$(PREFIX)/bin
	$(PACKAGE_MAKER) --root pkgroot/  --id com.johnhford.screenresolution \
		--out "screenresolution-$(VERSION).pkg" --target 10.5 \
		--title "screenresolution $(VERSION)" \
		--version $(VERSION)
	rm -f screenresolution.pkg
	ln -s screenresolution-$(VERSION).pkg screenresolution.pkg

dmg: pkg
	mkdir -p dmgroot
	cp screenresolution-$(VERSION).pkg dmgroot/
	rm -f screenresolution-$(VERSION).dmg
	hdiutil makehybrid -hfs -hfs-volume-name "screenresolution $(VERSION)" \
		-o "screenresolution-$(VERSION).dmg" dmgroot/
	rm -f screenresolution.dmg
	ln -s screenresolution-$(VERSION).dmg screenresolution.dmg

.PHONY: test pkg dmg install build clean reallyclean
