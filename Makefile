run:
	swift run MadMachineCli build --name DemoProgram --binary-type executable --input /Users/tib/DemoProgram/ --output /Users/tib/DemoProgram/dist

test:
	swift test --enable-test-discovery

install:
	swift package update
	swift build -c release
	install .build/Release/MadMachineCli /usr/local/bin/mm

uninstall:
	rm /usr/local/bin/mm
