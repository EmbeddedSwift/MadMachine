# MadMachine SDK & CLI

A description of this package.

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

Builds a library or an executable ([wip]: currently the mm command only supports building libz)

```sh
mm build \
    --name SwiftIO \
    --input ../SwiftIO \
    --output ./SwiftIO \
    --import-headers ../SwiftIO/Sources/CHal/include/SwiftHalWrapper.h\
    --import-search-paths ./,../ \
    --verbose
```
