MD2AG - Markdown to AmigaGuide Converter
==========================================

Version: 0.6.0
Release: Standalone

DESCRIPTION
-----------
Single-file PowerShell script to convert Markdown documents 
to AmigaGuide format for classic Amiga systems.

REQUIREMENTS
------------
- PowerShell 7+ (Windows, Linux, macOS)
  Download: https://aka.ms/powershell

USAGE
-----
Basic conversion:
  pwsh md2ag-standalone.ps1 -Input README.md -Output README.guide

With options:
  pwsh md2ag-standalone.ps1 -Input docs/manual.md -Output manual.guide -Verbose

Multi-file mode:
  pwsh md2ag-standalone.ps1 -Input main.md -Output main.guide -Mode Merge

PARAMETERS
----------
-Input      : Input Markdown file (.md) [REQUIRED]
-Output     : Output AmigaGuide file (.guide) [REQUIRED]
-Mode       : Merge, Separate, Optimized, Interactive (default: Merge)
-MaxDepth   : Max link depth (default: 10)
-Encoding   : Latin1, ASCII, UTF8 (default: Latin1)
-Verbose    : Show detailed progress
-WhatIf     : Preview without writing file
-Force      : Overwrite without prompting

EXAMPLES
--------
1. Simple conversion:
   pwsh md2ag-standalone.ps1 -Input README.md -Output README.guide

2. Multi-file project (merge all linked docs):
   pwsh md2ag-standalone.ps1 -Input main.md -Output main.guide -Mode Merge

3. Validation only:
   pwsh md2ag-standalone.ps1 -Input README.md -ValidateOnly

FEATURES
--------
✓ All Markdown syntax (headers, bold, italic, lists, blockquotes, code)
✓ Tables, footnotes, external links
✓ Multi-file projects with 4 conversion modes
✓ Circular dependency detection
✓ Cross-platform (Windows/Linux/macOS)
✓ Latin1 encoding for Amiga compatibility

TESTING ON AMIGA
-----------------
1. Transfer the .guide file to your Amiga (floppy, CF card, network)
2. Open with MultiView or AmigaGuide viewer:
   MultiView README.guide
   AmigaGuide README.guide

DOCUMENTATION
-------------
Full documentation: https://github.com/your-username/md2ag

LICENSE
-------
See LICENSE file in source repository

SUPPORT
-------
Issues: https://github.com/your-username/md2ag/issues
