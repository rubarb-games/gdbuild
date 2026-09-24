# gdbuild

Build pipeline for Godot projects

# Usage

`.\gdbuild.exe path/to/script.lua -dry:true/false -version:1.2.3`

# TODO
[] Create a build.bat/sh which builds the project, then runs it, and passes args to the pipeline

# Setup Sublime Text

The easiest way is to follow the tutorials by Karl Zylinski: https://zylinski.se/posts/gamedev-for-beginners-using-odin-and-raylib-1/

## Terminus

Install the Terminus package to be able to open a terminal within Sublime.

Ensure that it opens a 64 bit compatible terminal. Default Command Line in Windows is apparently not compatible. Open Preferences > Package Settings > Terminus > Settings and make the changes.

```
{
    "default_config": {
        "windows": "PowerShell Core"
    },
}
```

When you open Terminus, it will by default open as a horizontal panel at the bottom of the screen. To make it open in a vertical panel, you can change the key binding to this:

```
{ 
    "keys": ["ctrl+alt+t"], 
    "command": "terminus_open", 
    "args": { 
        "config_name": "Default",
        "pre_window_hooks": [ 
            ["set_layout", { "cols": [0.0, 0.5, 1.0], "rows": [0.0, 1.0], "cells": [[0, 0, 1, 1], [1, 0, 2, 1]] }], 
            ["focus_group", {"group": 1}] 
        ] 
    } 
},
```

This goes into Sublime's key binding setup. With this, you must first split your view, navigate to the new pane, then press Ctrl+Alt+T. 

# Setup CLion

Add the odin toolchain to project settings. It seems like CLion wants to use platform specific file locations in its config files. That will break between platforms, and therefore every developer has to configure the toolchain settings per environment.
