# Samples

## Path Configuration

Add local 'bin' directory to the PATH environment variable
This allows executables in the local 'bin' directory to be found and run.
The PATH:+ construct ensures the variable is appended only if PATH exists.

    ```bash
    export PATH="${PWD}/bin${PATH:+:${PATH}}"
    ```

## Swift Configuration

Specify the Swift toolchain to be used
This tells the build system which Swift toolchain to utilize.
Valid values include: "swift", "swift-latest", or a specific version identifier.

    ```bash
    export TOOLCHAINS="swift"
    ```

## Zephyr Target Configuration

Specify the Zephyr build target architecture
This defines the target architecture for the Zephyr RTOS build.
Format: <arch>-<vendor>-<os>-<abi>

    ```bash
    export ZEPHYR_BUILD_TARGET="riscv32-none-none-eabi"
    ```

Specify the Zephyr toolchain variant (e.g., cross-compile)
This determines which toolchain is used for compiling Zephyr code.
Common values: "zephyr", "gnuarmemb", "xtools", "cross-compile"

    ```bash
    export ZEPHYR_TOOLCHAIN_VARIANT="cross-compile"
    ```

## Cross-Compiler Configuration

Define the path to the cross-compiler toolchain
This should point to the bin directory of the toolchain with prefix included.
Uncomment the appropriate line based on your setup.

    ```bash
    export CROSS_COMPILE="/opt/zephyrproject/sdk/zephyr-sdk-0.17.0/riscv64-zephyr-elf/bin/riscv64-zephyr-elf-"
    ```

## Board Configuration

Set the Zephyr board identifier (board/family/core)
This specifies the target board for the Zephyr build.
Must match a board definition in Zephyr's board directory.

    ```bash
    export ZEPHYR_BOARD="qemu_riscv32/qemu_virt_riscv32/smp"
    ```

## Load Environment

Load Swift development environment variables and tools
This includes paths to Swift compilers, libraries, and other required tools

    ```bash
    . /usr/local/swiftly/env.sh
    ```

Set up the Zephyr RTOS development environment
This adds Zephyr tools to PATH and sets ZEPHYR_BASE and other required variables

    ```bash
    . /opt/zephyrproject/zephyr/zephyr-env.sh
    ```

Activate the Python virtual environment for Zephyr development
This ensures python dependencies for Zephyr tools are available

    ```bash
    . /opt/zephyrproject/.venv/bin/activate
    ```
