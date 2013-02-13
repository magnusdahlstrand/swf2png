# swf2png

swf2png is a tool to convert SWF animations to PNG image sequences. It's meant to be run from the command-line, but can also be used by dragging a SWF on to the application's icon. Nested looping movie clips are supported, while AS2 SWFs are not.

## Setup

Using [brew](http://mxcl.github.com/homebrew/) it's easy to set up!
`adobe-air-sdk` and `flex_sdk` is everything you need to compile and package the project. (Make sure to follow the "Caveats" steps for the Flex SDK install.)

To package the app you'll need a certificate.
It's easy to generate the certificate with `adt` (comes with the Air SDK):
`adt -certificate -cn 'certificateName' -o 'Organisation/Company' 2048-RSA cert.pfx 'password'`

## Compile

While the project can be set up to be compiled with Flash Builder, I'm using the command-line utilities that come with the Air and Flex SDKs for compilation and packaging of the application.

When in the project root, running
`./tools/compile.sh`
compiles the project into a swf (`bin/swf2png.swf`), which then can be packaged into an air app.

You might have to change the path to the Air SDK's library, but if you're running version 3.5 it should work as is.

## Package

Packaging is almost as easy as compiling the app:
`./tools/package.sh`
You'll then be prompted to enter the password you chose while creating the certificate, and then you're done.
The packaging process with create a file called `swf2png.air` in the `bin` folder, this is the installer.

## Installation

You'll have to manually double-click the installer created by the package script to install the app. If you then want access to the command-line interface (CLI), run the `./tools/install.sh` script while in the project root. You'll also have to make sure you've got `~/bin` in your PATH variable, as that's where the script shortcut to swf2png is created.

Simply symlinking to the swf2png executable (found in `/Applications/swf2png.app/Contents/MacOS/swf2png`) does not work, but one must create a script that runs the executable, forwarding the input to the application executable. This is what the `install.sh` script does.

## Usage

### GUI

When you've installed the Air app, using it is as simple as dragging an animated SWF to the app's icon. A PNG will be output for every frame on the main timeline, and they'll appear next to the swf you dragged in.

Just opening the app without dragging a swf to it won't work, and there are no plans for a more advanced interface.

### CLI

swf2png's strenght and main purpose is to be run from the command-line. If you've got it in your path, it's as easy as typing `swf2png` followed by the name of the SWF you want to convert. Images will be written to your current working directory. If you want the output images to be written to somewhere else, an optional second parameter can be given, and should be the path (relative or absolute) to an existing directory.

Example A, write to CWD:
`swf2png animation.swf`

Example B, write to home directory:
`swf2png animation.swf ~`

Example C, write to parent directory:
`swf2png animation.swf ../`

There is also a simple bash script in `/bin` called **swfs2pngs** (notice the pluralisation) that takes a file glob (such as `*.swf`) and processes all matching files. It does not support sending in an output directory, but the directory will be selected the same as for only sending in one parameter to swf2png.

The install script doesn't copy the `swfs2pngs` script to `~/bin`, so if you're interested in using it you have to do that yourself.

## Compatibility/Testing

The tool is written to work with AS3 SWFs (AVM2 SWFs) containing looped, nested movie clips. It's tested with a few different SWFs on Mac OSX 10.8.2, but might work on other platforms with other SWFs as well. There is no support for Actionscript 2 (AVM1) SWFs.

Air SDK 3.5 and Flex SDK 4.6.0 were used for development, but other versions might work as well.

## Error codes

When running on the command-line, a few error codes are used to indicate what's not working:
1. App opened without any arguments.
2. Input file name not valid (must match the regex pattern found in the function `getInputFile` in swf2png.as).
3. Input file not found.
4. Output directory is not a directory/doesn't exist.

## Contributing

If you find any bugs in this program, or want to expand upon its functionality, create an issue or make a pull request. I will do my best to fix issues as they arise, but there's no guarentee I will do so. Same with pull requests, I may or may not merge them in.

Please use the coding style already established when submitting pull requests. I'm not an Actionscript developer, so the style might differ from common AS3 style.

## License

The tools is licensed under the permissive MIT License, which can be found in the LICENSE file in the root of the repository.
