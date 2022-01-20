# ImageViewer Metal App Makefile

ImageViewer = build/ImageViewer.app/Contents/MacOS/ImageViewer

Source = Mac_Hello_Window.mm AppDelegate.mm Create_App_Menu.mm \
	Hello_Window_MetalView_Delegate.mm OptionSelectorControl.mm TestView.mm Utilities.mm \
	OptionSelectorControlDropDownPanel.mm

SourceObjects = $(patsubst %, build_files/source_objects/%, Mac_Hello_Window.o AppDelegate.o Create_App_Menu.o \
	Hello_Window_MetalView_Delegate.o OptionSelectorControl.o TestView.o Utilities.o \
	OptionSelectorControlDropDownPanel.o)

MetalLibrary = build/ImageViewer.app/Contents/Resources/Hello_Window_Shaders.metallib

InfoDotPlist = build/ImageViewer.app/Contents/Info.plist

AppImages = $(patsubst %, build/ImageViewer.app/Contents/Resources/%.png, dropdownArrow open_image_placeholder)

app: $(ImageViewer) $(InfoDotPlist) $(MetalLibrary) $(AppImages)
	echo "Building app.."

bundle:
	echo "Building bundle..."
	cd build; mkdir -p "ImageViewer.app"; cd "ImageViewer.app"; mkdir -p "Contents"; \
	cd Contents; mkdir -p MacOS; mkdir -p Resources;
.PHONY: bundle

$(ImageViewer): $(SourceObjects) | bundle
	clang++ -Wall -target x86_64-apple-macos11.3 -ObjC++ $(SourceObjects) \
	-framework Cocoa \
	-framework Metal \
	-framework MetalKit \
	-framework CoreGraphics \
	-framework CoreFoundation \
	-framework QuartzCore \
	-o "build/ImageViewer.app/Contents/MacOS/ImageViewer";

build_files/source_objects/%.o: src/%.mm
	clang++ -Wall -fobjc-arc -x objective-c++ $< -c -o $@


$(InfoDotPlist): build_files/Info.plist | bundle
	cp build_files/Info.plist "build/ImageViewer.app/Contents/Info.plist";

build/ImageViewer.app/Contents/Resources/%.png: build_files/%.png | bundle
	cp $< $@

$(MetalLibrary): ./src/Hello_Window_Shaders.metal | bundle
	cd src; xcrun -sdk macosx metal -c Hello_Window_Shaders.metal -o ../build_files/Hello_Window_Shaders.air;
	cd build_files; xcrun -sdk macosx metallib Hello_Window_Shaders.air -o "../build/ImageViewer.app/Contents/Resources/Hello_Window_Shaders.metallib";

# Debug
#debug: Mac_Hello_Window.mm AppDelegate.mm Create_App_Menu.mm Hello_Window_MetalView_Delegate.mm OptionSelectorControl.mm TestView.mm Utilities.mm OptionSelectorControlDropDownPanel.mm
#	echo "Debug..."
#	clang++ -Wall -g -fobjc-arc -x objective-c++ -target x86_64-apple-macos11.3 -ObjC++ Mac_Hello_Window.mm HWButton.mm AppDelegate.mm Create_App_Menu.mm Hello_Window_MetalView_Delegate.mm OptionSelectorControl.mm TestView.mm Utilities.mm OptionSelectorControlDropDownPanel.mm -framework Cocoa -framework Metal -framework MetalKit -framework CoreGraphics -framework CoreFoundation -framework QuartzCore -o ExampleMetalApp