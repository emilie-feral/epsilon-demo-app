# Sample C app for Epsilon

[![Build](https://github.com/numworks/epsilon-sample-app-c/actions/workflows/build.yml/badge.svg)](https://github.com/numworks/epsilon-sample-app-c/actions/workflows/build.yml)

This is a sample C app to use on a [NumWorks calculator](https://www.numworks.com).

```c
#include <eadk.h>

int main(int argc, char * argv[]) {
  eadk_display_draw_string("Hello, world!", (eadk_point_t){0, 0}, true, eadk_color_black, eadk_color_white);
  eadk_timing_msleep(3000);
}
```

## Run the app

To build this demo app on a simulator, you'll just need a C compiler (`gcc` is expected on Windows and Linux and `clang` is expected on MacOS).

TO build it for a NumWorks device, you'll additionally need [Node.js](https://nodejs.org/en/) ([Installation with package manager](https://nodejs.org/en/download/package-manager/)). The C SDK for Epsilon apps is shipped as an npm module called [nwlink](https://www.npmjs.com/package/nwlink) that will automatically be installed at compile time.

```shell
make clean && make run
make debug
```

This should launch a simulator running your application (or a debugger targeting your application).

## License

This sample app is distributed under the terms of the BSD License. See LICENSE for details.

## Trademarks

NumWorks is a registered trademark.
