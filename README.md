# MadMachine SDK & CLI

This project contains eveything you need to build  & deploy a MadMachine project, either a library or an executable.


## The mm cli app

### Install

You can install the `mm` command by running:

```sh
git clone https://github.com/EmbeddedSwift/MadMachine.git
cd MadMachine
make install
mm toolchain --upgrade
```

You can also remove `mm` by running `make uninstall` inside the MadMachine folder.

### Commands

The following commands are available. [wip]

#### Toolchain

Manages the system toolchain located in the `~/.MadMachine/` folder.

```sh
# check system toolchain version
mm toolchain --version

# install latest version
mm toolchain --upgrade

# install specific version
mm toolchain --set 0.0.1

# remove system toolchain
mm toolchain --destroy
```


#### Library

Manages installed system libraries.

```sh
# check system toolchain version
mm library --list

# install an pre-built library from a given location
mm library --install ./SwiftIO

# uninstall a given system library by name (see list)
mm library --uninstall SwiftIO
```


#### Build

Builds a library or an executable.

```sh
mm build \
    --name SwiftIO \
    --binary-type library \
    --input ../SwiftIO \
    --output ./SwiftIO \
    --import-headers ../SwiftIO/Sources/CHal/include/SwiftHalWrapper.h\
    --import-search-paths ./,../ \
    --verbose
```

The `--binary-type` option can be `library` or `executable`.

#### Board

MadMachine board management utilities

```sh
# print the path of the mounted volume 
mm board --volume 

# deploy an app to the board (without restarting or running)
mm board --deploy ./swiftio.bin

# runs an app on the board
mm board --run ./swiftio.bin

# removes the app from the board
mm board --clean

# eject (restart) the board
mm board --eject
```

The `--binary-type` option can be `library` or `executable`.


