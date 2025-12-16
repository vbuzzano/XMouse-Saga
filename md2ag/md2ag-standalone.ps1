<#
.SYNOPSIS
    MD2AG - Markdown to AmigaGuide Converter (Standalone Version)

.DESCRIPTION
    Convert Markdown documents to AmigaGuide format for classic Amiga systems.
    This is a standalone version with all modules merged into a single file.
    
    Version: 0.6.0
    Build Date: 2025-12-15 18:00:54
    
.PARAMETER Input
    Path to the input Markdown file (.md). Required.

.PARAMETER Output
    Path to the output AmigaGuide file (.guide). Required.

.PARAMETER Mode
    Linked document conversion mode: Merge, Separate, Optimized, or Interactive.
    Default: Merge

.PARAMETER MaxDepth
    Maximum traversal depth for linked documents.
    Default: 10

.PARAMETER Encoding
    Output character encoding: Latin1 (Amiga 8-bit), ASCII (strict 7-bit), or UTF8.
    Default: Latin1

.PARAMETER Verbose
    Display detailed conversion progress.

.PARAMETER WhatIf
    Show what would be converted without generating output.

.PARAMETER Force
    Overwrite output file without prompting.

.PARAMETER ValidateOnly
    Validate input syntax without generating output.

.PARAMETER Strict
    Strict validation mode - abort on any syntax error.

.EXAMPLE
    .\md2ag-standalone.ps1 -Input README.md -Output README.guide

.EXAMPLE
    .\md2ag-standalone.ps1 -Input docs/manual.md -Output manual.guide -Mode Merge -Verbose

.NOTES
    Version: 0.6.0
    Author: MD2AG Project
    Website: https://github.com/your-username/md2ag
#>


[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$false, Position=0)]
    [Alias('I', 'Source', 'File', 'Input')]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter(Mandatory=$false, Position=1)]
    [Alias('O', 'Destination', 'Out', 'Output')]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [Alias('M', 'ConversionMode')]
    [ValidateSet('Merge', 'Separate', 'Optimized', 'Interactive')]
    [string]$Mode = 'Merge',

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 100)]
    [int]$MaxDepth = 10,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Latin1', 'ASCII', 'UTF8')]
    [string]$Encoding = 'Latin1',

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly,

    [Parameter(Mandatory=$false)]
    [switch]$Strict,

    [Parameter(Mandatory=$false)]
    [switch]$Version
)

#region Embedded Configuration

# command-mappings.json embedded as here-string
$script:CommandMappingsJson = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "MD2AG Command Mappings",
  "description": "Markdown to AmigaGuide command mapping rules and [:AG](@command) specifications",
  "version": "0.5.0",
  
  "globalCommands": {
    "database": {
      "description": "Database name (required, must be first command)",
      "arguments": 1,
      "argType": "string",
      "required": true,
      "example": "@database \"MyDoc\""
    },
    "author": {
      "description": "Document author",
      "arguments": 1,
      "argType": "string",
      "required": false,
      "example": "@author \"John Doe\""
    },
    "master": {
      "description": "Master file path",
      "arguments": 1,
      "argType": "path",
      "required": false,
      "example": "@master \"main.guide\""
    },
    "wordwrap": {
      "description": "Enable word wrapping at specified column",
      "arguments": 1,
      "argType": "integer",
      "required": false,
      "example": "@wordwrap 72"
    },
    "smartwrap": {
      "description": "Enable smart word wrapping",
      "arguments": 0,
      "argType": "none",
      "required": false,
      "example": "@smartwrap"
    },
    "font": {
      "description": "Default font and size",
      "arguments": 2,
      "argType": "font",
      "required": false,
      "example": "@font \"topaz\" 8",
      "syntax": "[:AG](@font \"name::#size\")"
    },
    "width": {
      "description": "Display width in characters",
      "arguments": 1,
      "argType": "integer",
      "required": false,
      "example": "@width 80"
    },
    "height": {
      "description": "Display height in lines",
      "arguments": 1,
      "argType": "integer",
      "required": false,
      "example": "@height 24"
    },
    "xref": {
      "description": "Cross-reference file",
      "arguments": 1,
      "argType": "path",
      "required": false,
      "example": "@xref \"other.guide\""
    },
    "$VER": {
      "description": "Version string",
      "arguments": 1,
      "argType": "string",
      "required": false,
      "example": "@$VER: MyDoc 1.0 (13.12.2025)"
    },
    "remark": {
      "description": "Comment (ignored by viewer)",
      "arguments": 1,
      "argType": "string",
      "required": false,
      "example": "@remark \"Internal notes\""
    }
  },
  
  "nodeCommands": {
    "node": {
      "description": "Define a node (required for each section)",
      "arguments": 2,
      "argType": "node",
      "required": true,
      "example": "@node \"id\" \"Title\""
    },
    "endnode": {
      "description": "End of node (required)",
      "arguments": 0,
      "argType": "none",
      "required": true,
      "example": "@endnode"
    },
    "toc": {
      "description": "Table of contents node reference",
      "arguments": 1,
      "argType": "noderef",
      "required": false,
      "example": "@toc \"main\""
    },
    "help": {
      "description": "Help node reference",
      "arguments": 1,
      "argType": "noderef",
      "required": false,
      "example": "@help \"help_node\""
    },
    "index": {
      "description": "Index node reference",
      "arguments": 1,
      "argType": "noderef",
      "required": false,
      "example": "@index \"index_node\""
    },
    "prev": {
      "description": "Previous node reference",
      "arguments": 1,
      "argType": "noderef",
      "required": false,
      "example": "@prev \"previous\""
    },
    "next": {
      "description": "Next node reference",
      "arguments": 1,
      "argType": "noderef",
      "required": false,
      "example": "@next \"next_page\""
    },
    "title": {
      "description": "Node title (alternative to second node argument)",
      "arguments": 1,
      "argType": "string",
      "required": false,
      "example": "@title \"Page Title\""
    },
    "keywords": {
      "description": "Search keywords for node",
      "arguments": 1,
      "argType": "string",
      "required": false,
      "example": "@keywords \"search, index, find\""
    }
  },
  
  "textCommands": {
    "b": {
      "description": "Bold text start",
      "paired": "ub",
      "example": "@{b}text@{ub}"
    },
    "ub": {
      "description": "Bold text end",
      "paired": "b",
      "example": "@{b}text@{ub}"
    },
    "i": {
      "description": "Italic text start",
      "paired": "ui",
      "example": "@{i}text@{ui}"
    },
    "ui": {
      "description": "Italic text end",
      "paired": "i",
      "example": "@{i}text@{ui}"
    },
    "u": {
      "description": "Underline text start",
      "paired": "uu",
      "example": "@{u}text@{uu}"
    },
    "uu": {
      "description": "Underline text end",
      "paired": "u",
      "example": "@{u}text@{uu}"
    },
    "code": {
      "description": "Monospace code start",
      "paired": "plain",
      "example": "@{code}code@{plain}"
    },
    "plain": {
      "description": "Monospace code end",
      "paired": "code",
      "example": "@{code}code@{plain}"
    },
    "fg": {
      "description": "Foreground color",
      "argument": "color",
      "example": "@{fg shine}",
      "colors": ["text", "shine", "shadow", "fill", "filltext", "background", "highlight"]
    },
    "bg": {
      "description": "Background color",
      "argument": "color",
      "example": "@{bg fill}",
      "colors": ["text", "shine", "shadow", "fill", "filltext", "background", "highlight"]
    },
    "line": {
      "description": "Line break",
      "example": "@{line}"
    },
    "par": {
      "description": "Paragraph break",
      "example": "@{par}"
    },
    "lindent": {
      "description": "Left indent (pixels)",
      "argument": "integer",
      "example": "@{lindent 20}"
    },
    "pari": {
      "description": "Paragraph indent",
      "argument": "integer",
      "example": "@{pari 10}"
    },
    "link": {
      "description": "Hyperlink",
      "arguments": 2,
      "example": "@{\"text\" link \"target\"}"
    },
    "system": {
      "description": "Execute system command",
      "arguments": 1,
      "example": "@{\"text\" system \"command\"}"
    }
  }
}

'@

$script:CommandMappings = $script:CommandMappingsJson | ConvertFrom-Json

#endregion

#region Module Functions

# ==============================================
# Module: ValidationHelper.psm1
# ==============================================

#region Markdown Validation

function Test-MarkdownSyntax {
    <#
    .SYNOPSIS
        Validate Markdown file syntax.
    
    .DESCRIPTION
        Checks for common errors: unclosed bold tags, unclosed italic tags, malformed links.
        Returns validation result with errors and warnings.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$false)]
        [string]$FilePath = ""
    )
    
    $errors = @()
    $warnings = @()
    $lines = $Content -split "`n"
    $lineNumber = 0
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Check for unclosed bold tags
        $boldCount = ([regex]::Matches($line, '\*\*')).Count
        if ($boldCount % 2 -ne 0) {
            $errors += @{
                Line = $lineNumber
                Message = "Unclosed bold tag (**)"
                Context = $line.Trim()
                Suggestion = "Ensure all ** markers are paired"
            }
        }
        
        # Check for unclosed italic tags (single *)
        $italicCount = ([regex]::Matches($line, '(?<!\*)\*(?!\*)')).Count
        if ($italicCount % 2 -ne 0) {
            $errors += @{
                Line = $lineNumber
                Message = "Unclosed italic tag (*)"
                Context = $line.Trim()
                Suggestion = "Ensure all * markers are paired"
            }
        }
        
        # Check for malformed links
        if ($line -match '\[([^\]]+)\](?!\()') {
            $warnings += @{
                Line = $lineNumber
                Message = "Link text without URL: [$($matches[1])]"
                Context = $line.Trim()
                Suggestion = "Add URL like [text](url)"
            }
        }
        
        # Check for broken links (files that don't exist)
        if ($line -match '\[([^\]]+)\]\(([^)]+)\)') {
            $linkText = $matches[1]
            $linkTarget = $matches[2]
            
            # Only check local .md files (not URLs, not anchors only)
            if ($linkTarget -match '^[^#]+\.md' -and $linkTarget -notmatch '^https?://') {
                # Extract file path (before # if anchor present)
                $targetFile = $linkTarget -replace '#.*$', ''
                
                # Resolve relative to source file
                if ($FilePath) {
                    $baseDir = Split-Path -Path $FilePath -Parent
                    $resolvedPath = Join-Path -Path $baseDir -ChildPath $targetFile
                    
                    if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
                        $warnings += @{
                            Line = $lineNumber
                            Message = "Broken link: target file not found"
                            Context = "[$linkText]($linkTarget)"
                            Suggestion = "Create the file or update the link path"
                        }
                    }
                }
            }
        }
        
        # Check for non-ASCII characters (Amiga compatibility)
        if ($line -match '[^\x00-\x7F]') {
            $nonAsciiChars = [regex]::Matches($line, '[^\x00-\x7F]') | ForEach-Object { $_.Value } | Select-Object -Unique
            $warnings += @{
                Line = $lineNumber
                Message = "Non-ASCII characters detected: $($nonAsciiChars -join ', ')"
                Context = $line.Trim().Substring(0, [Math]::Min(60, $line.Trim().Length))
                Suggestion = "Use Latin1 encoding or replace with ASCII equivalents"
            }
        }
    }
    
    return @{
        IsValid = $errors.Count -eq 0
        Errors = $errors
        Warnings = $warnings
        FilePath = $FilePath
    }
}

#endregion

#region AmigaGuide Validation

function Test-AmigaGuideOutput {
    <#
    .SYNOPSIS
        Validate generated AmigaGuide output.
    
    .DESCRIPTION
        Verifies @database present, all @node blocks properly closed with @endnode.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    $errors = @()
    $warnings = @()
    
    # Check @database command present
    if ($Content -notmatch '@database') {
        $errors += @{
            Message = "Missing @database command"
            Suggestion = "AmigaGuide files must start with @database header"
        }
    }
    
    # Count @node and @endnode commands
    $nodeCount = ([regex]::Matches($Content, '@node')).Count
    $endnodeCount = ([regex]::Matches($Content, '@endnode')).Count
    
    if ($nodeCount -ne $endnodeCount) {
        $errors += @{
            Message = "Mismatched @node and @endnode commands"
            Context = "Found $nodeCount @node but $endnodeCount @endnode"
            Suggestion = "Each @node must be closed with @endnode"
        }
    }
    
    # Check for unescaped @ symbols (should be @@)
    $lines = $Content -split "`n"
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++
        
        # Skip AmigaGuide commands
        if ($line -match '^@(database|node|endnode|prev|next|toc|help|index)') {
            continue
        }
        
        # Check for single @ not followed by another @ or {
        if ($line -match '(?<!@)@(?![@{])') {
            $warnings += @{
                Line = $lineNumber
                Message = "Potentially unescaped @ character"
                Context = $line.Trim()
                Suggestion = "@ should be escaped as @@ in content"
            }
        }
    }
    
    return @{
        IsValid = $errors.Count -eq 0
        Errors = $errors
        Warnings = $warnings
    }
}

#endregion



#region Warning Helpers

function Write-ValidationWarning {
    <#
    .SYNOPSIS
        Display validation warning with context.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Warning
    )
    
    Write-Host "WARNING: $($Warning.Message)" -ForegroundColor Yellow
    
    if ($Warning.Line) {
        Write-Host "  Line: $($Warning.Line)" -ForegroundColor Gray
    }
    
    if ($Warning.Context) {
        Write-Host "  Context: $($Warning.Context)" -ForegroundColor Gray
    }
    
    if ($Warning.Suggestion) {
        Write-Host "  Suggestion: $($Warning.Suggestion)" -ForegroundColor Cyan
    }
}

#endregion

#region Linked Document Validation
# Test-BrokenLinks removed - broken links now generate warnings only
#endregion

#region Header Validation

function Test-HeaderStructure {
    <#
    .SYNOPSIS
        Validate Markdown header structure (exactly 1 H1).
    
    .PARAMETER FilePath
        Path to Markdown file (for error reporting).
    
    .PARAMETER Content
        Markdown file content to validate.
    
    .OUTPUTS
        PSCustomObject with validation result.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    
    # Parse headers
    $doc = Parse-MarkdownHeaders -Content $Content -FilePath $FilePath
    
    # Count H1 and H2
    $h1Count = ($doc.Nodes | Where-Object { $_.Level -eq 1 }).Count
    $h2Count = ($doc.Nodes | Where-Object { $_.Level -eq 2 }).Count
    
    # Validate exactly 1 H1
    $isValid = $true
    $errorMessage = ""
    
    if ($h1Count -eq 0) {
        $isValid = $false
        $errorMessage = "No H1 header found. Add a title with # at the top of your document"
    }
    elseif ($h1Count -gt 1) {
        $isValid = $false
        $errorMessage = "Multiple H1 headers found ($h1Count). Use only one # for the document title, and ## for sections"
    }
    
    return [PSCustomObject]@{
        IsValid = $isValid
        ErrorMessage = $errorMessage
        H1Count = $h1Count
        H2Count = $h2Count
        FilePath = $FilePath
    }
}

#endregion


# ==============================================
# Module: CommandMapper.psm1
# ==============================================

#region Configuration Loading

$script:CommandMappings = $null

function Initialize-CommandMappings {
    <#
    .SYNOPSIS
        Load command mappings from JSON configuration.
    #>
    if (-not $script:CommandMappings) {
        $configPath = Join-Path $PSScriptRoot "..\config\command-mappings.json"
        if (Test-Path $configPath) {
            $script:CommandMappings = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        }
        else {
            Write-Warning "Command mappings file not found: $configPath"
            $script:CommandMappings = @{
                globalCommands = @{}
                nodeCommands = @{}
                textCommands = @{}
            }
        }
    }
    return $script:CommandMappings
}

#endregion

#region [:AG](@command) Parsing

function Find-AGCommands {
    <#
    .SYNOPSIS
        Find all [:AG](@command) occurrences in Markdown content.
    
    .DESCRIPTION
        Parses content for [:AG](@command) syntax using regex.
        Returns array of command objects with name, arguments, and line number.
    
    .PARAMETER Content
        Markdown content string.
    
    .PARAMETER FilePath
        Source file path (for error reporting).
    
    .OUTPUTS
        Array of AG command objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath = ""
    )
    
    $commands = [System.Collections.ArrayList]::new()
    $lines = $Content -split "`n"
    $lineNumber = 0
    
    # Regex: [:AG](@command args)
    # Captures: command name and optional arguments
    $pattern = '\[:AG\]\(@(\w+)(?:\s+(.+?))?\)'
    
    foreach ($line in $lines) {
        $lineNumber++
        
        $matchResults = [regex]::Matches($line, $pattern)
        
        foreach ($match in $matchResults) {
            $cmdName = $match.Groups[1].Value
            $cmdArgs = if ($match.Groups[2].Success) { $match.Groups[2].Value } else { "" }
            
            $command = [PSCustomObject]@{
                Name = $cmdName
                Arguments = $cmdArgs
                RawSyntax = $match.Value
                LineNumber = $lineNumber
                FilePath = $FilePath
                Type = "Unknown"  # Will be determined later
            }
            
            [void]$commands.Add($command)
        }
    }
    
    return $commands
}

function ConvertTo-AmigaGuideCommand {
    <#
    .SYNOPSIS
        Convert [:AG](@command) to proper AmigaGuide syntax.
    
    .DESCRIPTION
        Takes parsed AG command and converts to valid AmigaGuide output.
        Validates command exists and arguments are correct.
    
    .PARAMETER Command
        AG command object from Find-AGCommands.
    
    .OUTPUTS
        AmigaGuide command string or $null if invalid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Command
    )
    
    $mappings = Initialize-CommandMappings
    $cmdName = $Command.Name.ToLower()
    
    # Determine command type
    if ($mappings.globalCommands.PSObject.Properties.Name -contains $cmdName) {
        $Command.Type = "Global"
        $spec = $mappings.globalCommands.$cmdName
    }
    elseif ($mappings.nodeCommands.PSObject.Properties.Name -contains $cmdName) {
        $Command.Type = "Node"
        $spec = $mappings.nodeCommands.$cmdName
    }
    else {
        Write-Warning "Unknown AmigaGuide command: @$cmdName (line $($Command.LineNumber))"
        return $null
    }
    
    # Parse arguments based on type
    $parsedArgs = ConvertFrom-CommandArguments -Arguments $Command.Arguments -Spec $spec -CommandName $cmdName
    
    if ($null -eq $parsedArgs) {
        Write-Warning "Invalid arguments for @$cmdName`: $($Command.Arguments) (line $($Command.LineNumber))"
        return $null
    }
    
    # Format output
    $output = Format-AmigaGuideCommand -CommandName $cmdName -Arguments $parsedArgs -Spec $spec
    
    return $output
}

#endregion

#region Argument Parsing

function ConvertFrom-CommandArguments {
    <#
    .SYNOPSIS
        Parse command arguments according to specification.
    
    .DESCRIPTION
        Handles different argument types: string, integer, font, path, noderef.
    
    .PARAMETER Arguments
        Argument string from [:AG](@command ...).
    
    .PARAMETER Spec
        Command specification from mappings.
    
    .PARAMETER CommandName
        Command name for error reporting.
    
    .OUTPUTS
        Parsed arguments array or $null if invalid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Arguments,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Spec,
        
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )
    
    # No arguments expected
    if ($Spec.arguments -eq 0) {
        if ($Arguments) {
            Write-Warning "Command @$CommandName does not accept arguments"
            return $null
        }
        return @()
    }
    
    # Special handling for font command
    if ($Spec.argType -eq "font") {
        return ConvertFrom-FontArguments -Arguments $Arguments
    }
    
    # Parse quoted strings and other arguments
    $parsed = @()
    
    # Regex to match quoted strings or unquoted tokens
    $argPattern = '"([^"]+)"|(\S+)'
    $argMatches = [regex]::Matches($Arguments, $argPattern)
    
    foreach ($match in $argMatches) {
        if ($match.Groups[1].Success) {
            # Quoted string
            $parsed += $match.Groups[1].Value
        }
        elseif ($match.Groups[2].Success) {
            # Unquoted token
            $value = $match.Groups[2].Value
            
            # Type conversion
            if ($Spec.argType -eq "integer") {
                try {
                    $parsed += [int]$value
                }
                catch {
                    Write-Warning "Expected integer argument for @$CommandName, got: $value"
                    return $null
                }
            }
            else {
                $parsed += $value
            }
        }
    }
    
    # Validate argument count
    if ($parsed.Count -ne $Spec.arguments -and $Spec.arguments -ne -1) {
        Write-Warning "Command @$CommandName expects $($Spec.arguments) argument(s), got $($parsed.Count)"
        return $null
    }
    
    return $parsed
}

function ConvertFrom-FontArguments {
    <#
    .SYNOPSIS
        Parse font specification: "name::#size" or "name" size.
    
    .DESCRIPTION
        Handles [:AG](@font "topaz::#8") syntax.
        Extracts font name and size.
    
    .PARAMETER Arguments
        Font argument string.
    
    .OUTPUTS
        Array with [name, size] or $null if invalid.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Arguments
    )
    
    # Format 1: "name::#size"
    if ($Arguments -match '"([^"]+)::(\d+)"' -or $Arguments -match '"([^"]+)::#(\d+)"') {
        $fontName = $matches[1]
        $fontSize = [int]$matches[2]
        return @($fontName, $fontSize)
    }
    
    # Format 2: "name" size
    if ($Arguments -match '"([^"]+)"\s+(\d+)') {
        $fontName = $matches[1]
        $fontSize = [int]$matches[2]
        return @($fontName, $fontSize)
    }
    
    # Format 3: name size (no quotes)
    if ($Arguments -match '(\S+)\s+(\d+)') {
        $fontName = $matches[1]
        $fontSize = [int]$matches[2]
        return @($fontName, $fontSize)
    }
    
    Write-Warning "Invalid font specification: $Arguments"
    return $null
}

#endregion

#region Command Formatting

function Format-AmigaGuideCommand {
    <#
    .SYNOPSIS
        Format AmigaGuide command with arguments.
    
    .DESCRIPTION
        Generates proper AmigaGuide syntax: @command args.
    
    .PARAMETER CommandName
        Command name (lowercase).
    
    .PARAMETER Arguments
        Parsed arguments array.
    
    .PARAMETER Spec
        Command specification.
    
    .OUTPUTS
        Formatted AmigaGuide command string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        
        [Parameter(Mandatory = $true)]
        [array]$Arguments,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Spec
    )
    
    # No arguments
    if ($Arguments.Count -eq 0) {
        return "@$CommandName"
    }
    
    # Format arguments
    $formattedArgs = @()
    
    foreach ($arg in $Arguments) {
        if ($arg -is [string] -and $arg -notmatch '^\d+$') {
            # String argument - add quotes if not already present
            if ($arg -notmatch '^".*"$') {
                $formattedArgs += "`"$arg`""
            }
            else {
                $formattedArgs += $arg
            }
        }
        else {
            # Integer or other
            $formattedArgs += $arg
        }
    }
    
    return "@$CommandName $($formattedArgs -join ' ')"
}

#endregion

#region Command Classification

function Get-GlobalCommands {
    <#
    .SYNOPSIS
        Filter commands to get only global commands.
    
    .PARAMETER Commands
        Array of AG command objects.
    
    .OUTPUTS
        Array of global commands.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Commands
    )
    
    return $Commands | Where-Object { $_.Type -eq "Global" }
}

function Get-NodeCommands {
    <#
    .SYNOPSIS
        Filter commands to get only node commands.
    
    .PARAMETER Commands
        Array of AG command objects.
    
    .OUTPUTS
        Array of node commands.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Commands
    )
    
    return $Commands | Where-Object { $_.Type -eq "Node" }
}

#endregion

#region Validation

function Test-AGCommandSyntax {
    <#
    .SYNOPSIS
        Validate [:AG](@command) syntax.
    
    .DESCRIPTION
        Checks if commands are valid, have correct arguments.
    
    .PARAMETER Commands
        Array of AG command objects.
    
    .OUTPUTS
        Validation result with errors and warnings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Commands
    )
    
    $mappings = Initialize-CommandMappings
    $errors = @()
    $warnings = @()
    
    foreach ($cmd in $Commands) {
        $cmdName = $cmd.Name.ToLower()
        
        # Check if command exists
        $isGlobal = $mappings.globalCommands.PSObject.Properties.Name -contains $cmdName
        $isNode = $mappings.nodeCommands.PSObject.Properties.Name -contains $cmdName
        
        if (-not $isGlobal -and -not $isNode) {
            $errors += @{
                Line = $cmd.LineNumber
                Message = "Unknown command: @$cmdName"
                Context = $cmd.RawSyntax
                Suggestion = "Check spelling or see command-mappings.json for valid commands"
            }
            continue
        }
        
        # Validate arguments
        $spec = if ($isGlobal) { $mappings.globalCommands.$cmdName } else { $mappings.nodeCommands.$cmdName }
        $parsed = ConvertFrom-CommandArguments -Arguments $cmd.Arguments -Spec $spec -CommandName $cmdName
        
        if ($null -eq $parsed) {
            $errors += @{
                Line = $cmd.LineNumber
                Message = "Invalid arguments for @$cmdName"
                Context = $cmd.RawSyntax
                Suggestion = $spec.example
            }
        }
    }
    
    return @{
        IsValid = $errors.Count -eq 0
        Errors = $errors
        Warnings = $warnings
    }
}

#endregion


# ==============================================
# Module: MarkdownParser.psm1
# ==============================================

# Import CommandMapper for [:AG] support
$commandMapperPath = Join-Path $PSScriptRoot "CommandMapper.psm1"
if (Test-Path $commandMapperPath) {
    Import-Module $commandMapperPath -Force -ErrorAction SilentlyContinue
}

#region Data Structures

class MarkdownNode {
    [string]$Id
    [string]$Title
    [int]$Level
    [string]$Content
    [int]$LineNumber
    [System.Collections.ArrayList]$AGCommands
    
    MarkdownNode([string]$id, [string]$title, [int]$level, [int]$lineNumber) {
        $this.Id = $id
        $this.Title = $title
        $this.Level = $level
        $this.LineNumber = $lineNumber
        $this.Content = ""
        $this.AGCommands = [System.Collections.ArrayList]::new()
    }
}

class MarkdownDocument {
    [string]$FilePath
    [string]$Content
    [System.Collections.ArrayList]$Nodes
    [hashtable]$Metadata
    [System.Collections.ArrayList]$GlobalAGCommands
    
    MarkdownDocument([string]$filePath, [string]$content) {
        $this.FilePath = $filePath
        $this.Content = $content
        $this.Nodes = [System.Collections.ArrayList]::new()
        $this.Metadata = @{}
        $this.GlobalAGCommands = [System.Collections.ArrayList]::new()
    }
}

#endregion

#region Header Parsing

function Parse-MarkdownHeaders {
    <#
    .SYNOPSIS
        Parse Markdown headers to create document structure (Phase 4A extended).
    
    .DESCRIPTION
        Extracts headers with support for:
        - ATX style: # to ###### (T014)
        - Custom IDs: # [](#id) Title (T040)
        - Pandoc style: # Title {#id} (T041)
        - Setext H1: Title\n==== (T042)
        - Setext H2: Title\n---- (T043)
        
        Generates node IDs from titles or uses custom IDs.
        Per markdown-amigaguide-mapping-v3.md Tier 1 Headers section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$false)]
        [string]$FilePath = ""
    )
    
    $doc = [MarkdownDocument]::new($FilePath, $Content)
    $lines = $Content -split "`n"
    $currentNode = $null
    $lineNumber = 0
    $i = 0
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $lineNumber = $i + 1
        $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { "" }
        
        $matched = $false
        $level = 0
        $title = ""
        $customId = $null
        
        # T042: Setext H1 (Title followed by ====)
        if (-not $matched -and $nextLine -match '^=+\s*$' -and $line -match '\S') {
            $level = 1
            $title = $line.Trim()
            $matched = $true
            $i++ # Skip underline
        }
        
        # T043: Setext H2 (Title followed by ----)
        if (-not $matched -and $nextLine -match '^-+\s*$' -and $line -match '\S') {
            $level = 2
            $title = $line.Trim()
            $matched = $true
            $i++ # Skip underline
        }
        
        # T040: ATX with custom ID at start: # [](#custom-id) Title
        if (-not $matched -and $line -match '^(#{1,6})\s+\[\]\(#([a-z0-9\-_]+)\)\s+(.+)$') {
            $level = $matches[1].Length
            $customId = $matches[2]
            $title = $matches[3].Trim()
            $matched = $true
        }
        
        # T041: ATX with Pandoc style ID at end: # Title {#custom-id}
        if (-not $matched -and $line -match '^(#{1,6})\s+(.+?)\s+\{#([a-z0-9\-_]+)\}\s*$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            $customId = $matches[3]
            $matched = $true
        }
        
        # Standard ATX: # Title
        if (-not $matched -and $line -match '^(#{1,6})\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            $matched = $true
        }
        
        # If header matched, create node
        if ($matched) {
            # Save previous node content
            if ($currentNode) {
                $doc.Nodes.Add($currentNode) | Out-Null
            }
            
            # Use custom ID or generate from title
            $nodeId = if ($customId) { $customId } else { ConvertTo-NodeId -Title $title -LineNumber $lineNumber }
            
            # Create new node
            $currentNode = [MarkdownNode]::new($nodeId, $title, $level, $lineNumber)
        }
        elseif ($currentNode) {
            # Add line to current node content
            $currentNode.Content += $line + "`n"
        }
        
        $i++
    }
    
    # Add final node
    if ($currentNode) {
        $doc.Nodes.Add($currentNode) | Out-Null
    }
    
    # If no headers found, create single default node
    if ($doc.Nodes.Count -eq 0) {
        $defaultNode = [MarkdownNode]::new("main", "Main", 1, 1)
        $defaultNode.Content = $Content
        $doc.Nodes.Add($defaultNode) | Out-Null
    }
    
    # Parse [:AG](@command) syntax (Phase 4C - T091)
    if (Get-Command Find-AGCommands -ErrorAction SilentlyContinue) {
        try {
            $agCommands = Find-AGCommands -Content $Content -FilePath $FilePath
            
            if ($agCommands -and $agCommands.Count -gt 0) {
                # Classify commands
                foreach ($cmd in $agCommands) {
                    # Convert to AmigaGuide format
                    $agOutput = ConvertTo-AmigaGuideCommand -Command $cmd
                    
                    if ($agOutput) {
                        # Add to appropriate collection
                        if ($cmd.Type -eq "Global") {
                            [void]$doc.GlobalAGCommands.Add($agOutput)
                        }
                        elseif ($cmd.Type -eq "Node") {
                            # Find which node this command belongs to based on line number
                            $targetNode = $doc.Nodes | Where-Object { $_.LineNumber -le $cmd.LineNumber } | Select-Object -Last 1
                            if ($targetNode) {
                                [void]$targetNode.AGCommands.Add($agOutput)
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "[:AG] command parsing skipped: $($_.Exception.Message)"
        }
    }
    
    return $doc
}

function ConvertTo-NodeId {
    <#
    .SYNOPSIS
        Convert title to valid AmigaGuide node ID.
    
    .DESCRIPTION
        Generates node ID: lowercase, spaces→hyphens, remove special chars.
        Per T017 specification. Uses deterministic hash for empty titles (T166).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [int]$LineNumber = 0
    )
    
    $nodeId = $Title.ToLower()
    $nodeId = $nodeId -replace '\s+', '-'           # Spaces to hyphens
    $nodeId = $nodeId -replace '[^a-z0-9\-_]', ''   # Remove special chars
    $nodeId = $nodeId -replace '-+', '-'            # Collapse multiple hyphens
    $nodeId = $nodeId.Trim('-')                     # Remove leading/trailing hyphens
    
    if ([string]::IsNullOrWhiteSpace($nodeId)) {
        # T166: Deterministic output - use line number hash instead of random
        if ($LineNumber -gt 0) {
            $nodeId = "node-$LineNumber"
        }
        else {
            # Fallback for zero/negative line numbers
            $hash = [System.Math]::Abs($Title.GetHashCode())
            $nodeId = "node-$hash"
        }
    }
    
    return $nodeId
}

#endregion

#region Formatting Parsing

function Parse-BoldItalic {
    <#
    .SYNOPSIS
        Parse bold and italic formatting in text (Phase 4A - Tier 1).
    
    .DESCRIPTION
        Identifies all bold/italic variants with distinct rendering:
        - **bold** → @{b}@{ub} (standard)
        - __bold__ → @{fg highlight}@{fg text} (optional style)
        - *italic* → @{i}@{ui} (standard)
        - _italic_ → @{i}@{fg highlight}@{fg text}@{ui} (optional style)
        - ***bold+italic*** → @{b}@{i}@{ui}@{ub} (combined)
        - ___bold+italic___ → @{b}@{i}@{fg highlight}@{fg text}@{ui}@{ub} (combined + style)
        
        Per T037-T039 and markdown-amigaguide-mapping-v3.md Tier 1.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $markers = @()
    
    # T039: Combined bold+italic (must check BEFORE single markers)
    # ___text___ → combined with optional style
    $combinedUnderscorePattern = '___([^_]+)___'
    $matches = [regex]::Matches($Text, $combinedUnderscorePattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'BoldItalicStyled'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    # ***text*** → combined standard
    $combinedAsteriskPattern = '\*\*\*([^*]+)\*\*\*'
    $matches = [regex]::Matches($Text, $combinedAsteriskPattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'BoldItalic'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    # T037: __bold__ → optional style (distinct from **bold**)
    $boldUnderscorePattern = '(?<!_)__([^_]+)__(?!_)'
    $matches = [regex]::Matches($Text, $boldUnderscorePattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'BoldStyled'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    # Find bold (**text**) - standard
    $boldPattern = '(?<!\*)\*\*([^*]+)\*\*(?!\*)'
    $matches = [regex]::Matches($Text, $boldPattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'Bold'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    # T038: _italic_ → optional style (distinct from *italic*)
    $italicUnderscorePattern = '(?<!_)_([^_]+)_(?!_)'
    $matches = [regex]::Matches($Text, $italicUnderscorePattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'ItalicStyled'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    # Find italic (*text*) - standard, exclude bold/combined matches
    $italicPattern = '(?<!\*)\*([^*]+)\*(?!\*)'
    $matches = [regex]::Matches($Text, $italicPattern)
    foreach ($match in $matches) {
        $markers += @{
            Type = 'Italic'
            Text = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
        }
    }
    
    return $markers | Sort-Object -Property Start
}

#endregion

#region List Parsing

function Parse-Lists {
    <#
    .SYNOPSIS
        Parse multi-level Markdown lists (T047-T048).
    
    .DESCRIPTION
        Detects list items with proper indentation:
        - Level 1 (0-2 spaces): -, *, +, 1., 1) → 3 spaces indent
        - Level 2 (2-4 spaces): Same markers → 5 spaces + 'o'
        - Level 3 (4+ spaces): Same markers → 7 spaces + '*'
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 Listes section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $lines = $Text -split "`n"
    $result = [System.Text.StringBuilder]::new()
    
    foreach ($line in $lines) {
        $matched = $false
        $indent = 0
        $marker = ""
        $content = ""
        
        # Detect indentation level
        if ($line -match '^(\s*)([*+\-]|\d+[\.\)])\s+(.+)$') {
            $leadingSpaces = $matches[1].Length
            $marker = $matches[2]
            $content = $matches[3]
            
            # Determine list level based on indentation
            if ($leadingSpaces -le 2) {
                # Level 1: 3 spaces + original marker
                $indent = 3
                $finalMarker = $marker
            }
            elseif ($leadingSpaces -le 4) {
                # Level 2: 5 spaces + 'o'
                $indent = 5
                $finalMarker = if ($marker -match '^\d') { $marker } else { 'o' }
            }
            else {
                # Level 3+: 7 spaces + '*'
                $indent = 7
                $finalMarker = if ($marker -match '^\d') { $marker } else { '*' }
            }
            
            $result.AppendLine((' ' * $indent) + $finalMarker + ' ' + $content) | Out-Null
            $matched = $true
        }
        
        if (-not $matched) {
            $result.AppendLine($line) | Out-Null
        }
    }
    
    return $result.ToString().TrimEnd("`r`n")
}

#endregion

#region Blockquote and Separator Parsing

function Parse-Blockquotes {
    <#
    .SYNOPSIS
        Parse blockquote lines (T049-T050).
    
    .DESCRIPTION
        Converts > and >> prefixes to AmigaGuide indentation:
        - > Text → @{lindent 2}@{fg shadow}Text@{lindent 0}@{fg text}
        - >> Nested → @{lindent 4}@{fg shadow}Nested@{lindent 0}@{fg text}
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 Blockquotes section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $lines = $Text -split "`n"
    $result = [System.Text.StringBuilder]::new()
    
    foreach ($line in $lines) {
        if ($line -match '^>>\s+(.+)$') {
            # Nested blockquote (level 2)
            $content = $matches[1]
            $result.AppendLine("@{lindent 4}@{fg shadow}$content@{lindent 0}@{fg text}") | Out-Null
        }
        elseif ($line -match '^>\s+(.+)$') {
            # Single blockquote (level 1)
            $content = $matches[1]
            $result.AppendLine("@{lindent 2}@{fg shadow}$content@{lindent 0}@{fg text}") | Out-Null
        }
        else {
            $result.AppendLine($line) | Out-Null
        }
    }
    
    return $result.ToString().TrimEnd("`r`n")
}

function Parse-Separators {
    <#
    .SYNOPSIS
        Parse horizontal separators (T051-T052).
    
    .DESCRIPTION
        Converts Markdown separators to AmigaGuide visual separators:
        - --- → ~~~~~~~~~~~~~~~ (15 tildes)
        - ___ → _______________ (15 underscores)
        - *** NOT converted (reserved for bold+italic)
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 Séparateurs section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $lines = $Text -split "`n"
    $result = [System.Text.StringBuilder]::new()
    
    foreach ($line in $lines) {
        if ($line -match '^\s*---+\s*$') {
            # Triple dash → tildes
            $result.AppendLine("~~~~~~~~~~~~~~~") | Out-Null
        }
        elseif ($line -match '^\s*___+\s*$') {
            # Triple underscore → underscores
            $result.AppendLine("_______________") | Out-Null
        }
        else {
            $result.AppendLine($line) | Out-Null
        }
    }
    
    return $result.ToString().TrimEnd("`r`n")
}

#endregion

#region Paragraph and Code Block Parsing

function Parse-Paragraphs {
    <#
    .SYNOPSIS
        Handle paragraph spacing and line breaks (T053-T054).
    
    .DESCRIPTION
        - Double blank lines preserved (paragraph breaks)
        - Two spaces at line end → @{line} (if smartwrap active)
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 Paragraphes section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [bool]$SmartWrap = $true
    )
    
    # Convert two spaces at end of line to @{line}
    if ($SmartWrap) {
        $Text = $Text -replace '  $', '@{line}'
    }
    
    # Double blank lines are already preserved by PowerShell string handling
    return $Text
}

function Parse-CodeBlocks {
    <#
    .SYNOPSIS
        Parse fenced code blocks and indented code (T059-T060).
    
    .DESCRIPTION
        Converts code blocks to AmigaGuide format:
        - ``` or ```language → @{code}...@{plain} (tags on line start)
        - 4-space indentation → @{code}...@{plain}
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 Blocs Code section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $lines = $Text -split "`n"
    $result = [System.Text.StringBuilder]::new()
    $inCodeBlock = $false
    $codeContent = [System.Text.StringBuilder]::new()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Fenced code block (```)
        if ($line -match '^```') {
            if (-not $inCodeBlock) {
                # Start code block
                $inCodeBlock = $true
                $codeContent.Clear() | Out-Null
            }
            else {
                # End code block
                $result.AppendLine("@{code}") | Out-Null
                $result.Append($codeContent.ToString()) | Out-Null
                $result.AppendLine("@{plain}") | Out-Null
                $inCodeBlock = $false
                $codeContent.Clear() | Out-Null
            }
        }
        elseif ($inCodeBlock) {
            # Inside code block
            $codeContent.AppendLine($line) | Out-Null
        }
        # Indented code (4 spaces)
        elseif ($line -match '^    (.+)$') {
            $codeLine = $matches[1]
            # Check if we're starting a new code block
            $prevLine = if ($i -gt 0) { $lines[$i - 1] } else { "" }
            if ($prevLine -notmatch '^    ' -and $prevLine.Trim() -ne "") {
                $result.AppendLine("@{code}") | Out-Null
            }
            $result.AppendLine($codeLine) | Out-Null
            
            # Check if this is the end of the code block
            $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { "" }
            if ($nextLine -notmatch '^    ') {
                $result.AppendLine("@{plain}") | Out-Null
            }
        }
        else {
            $result.AppendLine($line) | Out-Null
        }
    }
    
    return $result.ToString().TrimEnd("`r`n")
}

function Parse-HTMLTags {
    <#
    .SYNOPSIS
        Parse minimal HTML tag support (T061-T062).
    
    .DESCRIPTION
        Only 4 tags supported:
        - <b>text</b> → @{b}text@{ub}
        - <i>text</i> → @{i}text@{ui}
        - <u>text</u> → @{u}text@{uu}
        - <code>text</code> → @{fg highlight}text@{fg text}
        
        All other HTML tags ignored.
        Per markdown-amigaguide-mapping-v3.md Tier 1 HTML Tags section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $result = $Text
    
    # Convert supported HTML tags
    $result = $result -replace '<b>([^<]+)</b>', '@{b}$1@{ub}'
    $result = $result -replace '<i>([^<]+)</i>', '@{i}$1@{ui}'
    $result = $result -replace '<u>([^<]+)</u>', '@{u}$1@{uu}'
    $result = $result -replace '<code>([^<]+)</code>', '@{fg highlight}$1@{fg text}'
    
    # Ignore all other HTML tags (remove them)
    $result = $result -replace '<[^>]+>', ''
    
    return $result
}

#endregion

#region Link Parsing

function Parse-Links {
    <#
    .SYNOPSIS
        Parse Markdown links with Tier 1 and Tier 2 extensions (T055-T058, T067-T076).
    
    .DESCRIPTION
        Handles multiple link formats:
        
        **Tier 1 (Internal/Basic)**:
        - [Text](target) → Standard link
        - [Text](#node) → Internal node reference
        - [Text](target "10") → Link with line number
        - <https://url> → Autolink
        
        **Tier 2 (External Files/URLs)**:
        - [Text](file.md) → External Markdown file
        - [Text](file.guide) → External AmigaGuide file
        - [Text](file.txt) → External text file (any text extension: .c, .h, .cpp, .py, .sh, .log, etc.)
        - [Text](file.md/node) → Specific node in external file
        - [Text](file.md/node "10") → External file + node + line
        - [Text](image.iff) → Image file (opens in viewer: .png, .iff, .jpg, .gif, etc.)
        - [Text](http://url) → HTTP URL (OpenURL)
        - [Text](https://url) → HTTPS URL (OpenURL)
        - [Text](ftp://url) → FTP URL (OpenURL)
        - [Text](mailto:email) → Email (OpenURL)
        - [Text](unknown:protocol) → Unsupported (convert to bold text)
        
        Per markdown-amigaguide-mapping-v3.md Tier 1 + Tier 2 Liens sections.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $links = @()
    
    # Priority 1: Match [label](target "line") - with line number
    # This must be first to avoid being caught by simpler patterns
    $linkWithLinePattern = '\[([^\]]+)\]\(([^)]+?)\s+"(\d+)"\)'
    $matches = [regex]::Matches($Text, $linkWithLinePattern)
    foreach ($match in $matches) {
        $target = $match.Groups[2].Value
        $linkType = Get-LinkType -Target $target
        
        $links += @{
            Label = $match.Groups[1].Value
            Target = $target
            LineNumber = $match.Groups[3].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
            Type = $linkType
            HasLineNumber = $true
        }
    }
    
    # Priority 2: Match [label](#node) - internal link
    $internalLinkPattern = '\[([^\]]+)\]\(#([^)]+)\)'
    $matches = [regex]::Matches($Text, $internalLinkPattern)
    foreach ($match in $matches) {
        # Skip if already matched as WithLine
        $alreadyMatched = $links | Where-Object { $_.Start -eq $match.Index }
        if (-not $alreadyMatched) {
            $links += @{
                Label = $match.Groups[1].Value
                Target = $match.Groups[2].Value
                Start = $match.Index
                Length = $match.Length
                Original = $match.Value
                Type = 'Internal'
                HasLineNumber = $false
            }
        }
    }
    
    # Priority 3: Standard [label](target)
    $linkPattern = '\[([^\]]+)\]\(([^)"\s]+)\)'
    $matches = [regex]::Matches($Text, $linkPattern)
    foreach ($match in $matches) {
        # Skip if already matched
        $alreadyMatched = $links | Where-Object { $_.Start -eq $match.Index }
        if (-not $alreadyMatched) {
            $target = $match.Groups[2].Value
            $linkType = Get-LinkType -Target $target
            
            $links += @{
                Label = $match.Groups[1].Value
                Target = $target
                Start = $match.Index
                Length = $match.Length
                Original = $match.Value
                Type = $linkType
                HasLineNumber = $false
            }
        }
    }
    
    # Priority 4: Autolinks <url>
    $autolinkPattern = '<(https?://[^>]+)>'
    $matches = [regex]::Matches($Text, $autolinkPattern)
    foreach ($match in $matches) {
        $links += @{
            Label = $match.Groups[1].Value
            Target = $match.Groups[1].Value
            Start = $match.Index
            Length = $match.Length
            Original = $match.Value
            Type = 'Autolink'
            HasLineNumber = $false
        }
    }
    
    return $links
}

function Get-LinkType {
    <#
    .SYNOPSIS
        Determine link type from target string (T067-T076).
    
    .DESCRIPTION
        Categorizes links based on protocol, file extension, and path structure.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Target
    )
    
    # Check for protocols
    if ($Target -match '^https?://') {
        return 'HTTP'
    }
    if ($Target -match '^ftp://') {
        return 'FTP'
    }
    if ($Target -match '^mailto:') {
        return 'Mailto'
    }
    if ($Target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') {
        return 'UnsupportedProtocol'
    }
    
    # Check for file paths with node references (file.ext/node)
    if ($Target -match '^(.+?)\.(md|guide|txt|[a-zA-Z0-9]+)(/[^/]+)$') {
        $extension = $matches[2].ToLower()
        switch ($extension) {
            'md' { return 'ExternalMarkdown' }
            'guide' { return 'ExternalGuide' }
            default { 
                # All other extensions = text files (.c, .h, .cpp, .py, .sh, .log, etc.)
                return 'ExternalText'
            }
        }
    }
    
    # Check for file extensions without node reference
    if ($Target -match '\.([a-zA-Z0-9]+)$') {
        $extension = $matches[1].ToLower()
        switch ($extension) {
            'md' { return 'ExternalMarkdown' }
            'guide' { return 'ExternalGuide' }
            { $_ -in @('png', 'iff', 'jpg', 'jpeg', 'gif', 'bmp', 'ico') } { 
                # Image files
                return 'NonTextFile'
            }
            default {
                # Everything else = text file (.c, .h, .cpp, .py, .sh, .txt, .log, .conf, etc.)
                return 'ExternalText'
            }
        }
    }
    
    # Default: standard internal link
    return 'Standard'
}

#endregion

#region Footnote Parsing

function Parse-Footnotes {
    <#
    .SYNOPSIS
        Parse footnote references and definitions (T077-T079).
    
    .DESCRIPTION
        Extracts footnote references [^1] and definitions [^1]: Content.
        Returns hashtable with:
        - References: Array of {Label, Start, Length, Original}
        - Definitions: Hashtable of footnote ID to content
        
        Per markdown-amigaguide-mapping-v3.md Tier 2 Footnotes section.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $result = @{
        References = @()
        Definitions = @{}
    }
    
    # Parse footnote references: Text[^1]
    $refPattern = '\[\^([0-9]+)\]'
    $matches = [regex]::Matches($Text, $refPattern)
    
    foreach ($match in $matches) {
        # Check if this is a definition (starts at line beginning with colon after)
        $isDefinition = $false
        if ($match.Index -eq 0 -or $Text[$match.Index - 1] -match '[\r\n]') {
            $afterMatch = $match.Index + $match.Length
            if ($afterMatch -lt $Text.Length -and $Text[$afterMatch] -eq ':') {
                $isDefinition = $true
            }
        }
        
        if (-not $isDefinition) {
            $result.References += @{
                Label = $match.Groups[1].Value
                Start = $match.Index
                Length = $match.Length
                Original = $match.Value
            }
        }
    }
    
    # Parse footnote definitions: [^1]: Content (multiline support)
    $defPattern = '(?m)^\[\^([0-9]+)\]:\s+(.+?)(?=\n\[\^[0-9]+\]:|$)'
    $matches = [regex]::Matches($Text, $defPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    foreach ($match in $matches) {
        $footnoteId = $match.Groups[1].Value
        $content = $match.Groups[2].Value.Trim()
        $result.Definitions[$footnoteId] = $content
    }
    
    return $result
}

function Remove-FootnoteDefinitions {
    <#
    .SYNOPSIS
        Remove footnote definition lines from text (T078).
    
    .DESCRIPTION
        Removes [^1]: Content lines as they will be placed at end of node.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    # Remove footnote definition lines (including multiline content)
    $result = $Text -replace '(?m)^\[\^[0-9]+\]:\s+.+?(?=\n\[\^[0-9]+\]:|$)', ''
    
    # Clean up extra blank lines
    $result = $result -replace '\n\n\n+', "`n`n"
    
    return $result
}

function Parse-Tables {
    <#
    .SYNOPSIS
        Parse Markdown tables (T080 - Tier 2 Advanced).
    
    .DESCRIPTION
        Detects table syntax with | column | separators.
        Returns table blocks with headers, separators, and rows.
        Simple approach: preserve as-is for @{code} block wrapping.
    
    .EXAMPLE
        Parse-Tables -Text $markdown
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text
    )
    
    $tables = [System.Collections.ArrayList]::new()
    
    # Find table blocks (header + separator + rows)
    # Pattern: lines starting with | and containing at least one more |
    $lines = $Text -split "`n"
    $i = 0
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i].Trim()
        
        # Check if this line looks like a table row (starts and ends with |)
        if ($line -match '^\|.+\|$') {
            $tableLines = [System.Collections.ArrayList]::new()
            $startIndex = $i
            
            # Collect consecutive table lines (preserving original formatting)
            while ($i -lt $lines.Count -and $lines[$i].Trim() -match '^\|.+\|$') {
                [void]$tableLines.Add($lines[$i].Trim())
                $i++
            }
            
            # Validate: must have at least 2 lines (header + separator minimum)
            if ($tableLines.Count -ge 2) {
                # Check if second line is a separator (contains only |, -, :, and spaces)
                # Pattern: starts with |, then any mix of -, :, spaces, and |, ends with |
                $secondLine = $tableLines[1]
                if ($secondLine -match '^\|[\s\-:|]+\|$') {
                    # Valid table found
                    $tableBlock = @{
                        StartLine = $startIndex
                        Lines = $tableLines
                        RawText = ($tableLines -join "`n")
                    }
                    [void]$tables.Add($tableBlock)
                }
            }
            
            continue
        }
        
        $i++
    }
    
    # Force return as array (prevent PowerShell from unwrapping)
    return ,$tables
}

#endregion


# ==============================================
# Module: AmigaGuideGenerator.psm1
# ==============================================

#region AmigaGuide Document Generation

function New-AmigaGuideDocument {
    <#
    .SYNOPSIS
        Generate complete AmigaGuide document from MarkdownDocument (Phase 4A extended).
    
    .DESCRIPTION
        Creates valid .guide file with:
        - @database header
        - Auto-generated navigation commands (T046)
        - @node blocks with level-based formatting (T044-T045)
        - @prev/@next/@toc/@help/@index/@smartwrap defaults
        - Proper @endnode closing
    #>
    param(
        [Parameter(Mandatory=$true)]
        $MarkdownDocument,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Encoding = 'Latin1'
    )
    
    $output = [System.Text.StringBuilder]::new()
    
    # Generate @database header (T018)
    $dbName = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)
    $output.AppendLine("@database `"$dbName`"") | Out-Null
    
    # T046: Global @smartwrap for automatic word wrapping (applies to all nodes)
    $output.AppendLine("@smartwrap") | Out-Null
    
    # Check if index node exists and add global @index command
    $indexNode = $MarkdownDocument.Nodes | Where-Object { $_.Id -eq 'index' -or $_.Id -eq 'index_node' } | Select-Object -First 1
    if ($indexNode) {
        $output.AppendLine("@index `"$($indexNode.Id)`"") | Out-Null
    }
    
    # T097: Add global [:AG] commands after @database (Phase 4C)
    if ($MarkdownDocument.GlobalAGCommands -and $MarkdownDocument.GlobalAGCommands.Count -gt 0) {
        foreach ($globalCmd in $MarkdownDocument.GlobalAGCommands) {
            $output.AppendLine($globalCmd) | Out-Null
        }
    }
    
    $output.AppendLine("") | Out-Null
    
    # Generate nodes with navigation and formatting
    for ($i = 0; $i -lt $MarkdownDocument.Nodes.Count; $i++) {
        $node = $MarkdownDocument.Nodes[$i]
        
        # Generate @node block (T019)
        $output.AppendLine("@node `"$($node.Id)`" `"$($node.Title)`"") | Out-Null
        
        # T046: Auto-generate default node commands (can be overridden by [:AG] syntax later)
        # Default @toc to first node (main)
        if ($MarkdownDocument.Nodes.Count -gt 0) {
            $mainNode = $MarkdownDocument.Nodes[0]
            $output.AppendLine("@toc `"$($mainNode.Id)`"") | Out-Null
        }
        
        # Default @help (if it exists as a node)
        $helpNode = $MarkdownDocument.Nodes | Where-Object { $_.Id -eq 'help' -or $_.Id -eq 'help_node' } | Select-Object -First 1
        if ($helpNode) {
            $output.AppendLine("@help `"$($helpNode.Id)`"") | Out-Null
        }
        
        # T046: Generate @prev/@next navigation
        if ($i -gt 0) {
            $prevNode = $MarkdownDocument.Nodes[$i - 1]
            $output.AppendLine("@prev `"$($prevNode.Id)`"") | Out-Null
        }
        
        if ($i -lt $MarkdownDocument.Nodes.Count - 1) {
            $nextNode = $MarkdownDocument.Nodes[$i + 1]
            $output.AppendLine("@next `"$($nextNode.Id)`"") | Out-Null
        }
        
        # T098: Add node-specific [:AG] command overrides AFTER defaults (Phase 4C)
        # MultiView/AmigaGuide uses the LAST value, so overrides come after defaults
        if ($node.AGCommands -and $node.AGCommands.Count -gt 0) {
            foreach ($nodeCmd in $node.AGCommands) {
                $output.AppendLine($nodeCmd) | Out-Null
            }
        }
        
        # T044-T045: Format header based on level
        $headerFormatted = Format-HeaderByLevel -Title $node.Title -Level $node.Level
        $output.Append($headerFormatted) | Out-Null
        
        # Convert node content (skip if empty)
        if (-not [string]::IsNullOrWhiteSpace($node.Content)) {
            # Trim leading/trailing whitespace to avoid excessive blank lines
            $trimmedContent = $node.Content.Trim()
            
            # T077-T079: Parse footnotes before conversion
            $footnotes = Parse-Footnotes -Text $trimmedContent
            
            # Remove footnote definitions from content (will be added at end)
            $contentWithoutDefs = Remove-FootnoteDefinitions -Text $trimmedContent
            
            # Skip if content became empty after removing footnote definitions
            if (-not [string]::IsNullOrWhiteSpace($contentWithoutDefs)) {
                # Convert main content
                $convertedContent = ConvertTo-AmigaGuideFormat -Text $contentWithoutDefs -Level $node.Level -Footnotes $footnotes
                $output.Append($convertedContent) | Out-Null
            }
            
            # T079: Add footnote definitions at end of node
            if ($footnotes.Definitions.Count -gt 0) {
                $output.AppendLine("") | Out-Null
                
                # Sort footnotes by ID
                $sortedFootnotes = $footnotes.Definitions.GetEnumerator() | Sort-Object Name
                
                foreach ($footnote in $sortedFootnotes) {
                    # Convert footnote content (inline formatting only, no block-level)
                    $convertedFootnoteContent = ConvertTo-AmigaGuideFormat -Text $footnote.Value -Level 0 -Footnotes @{}
                    $convertedFootnoteContent = $convertedFootnoteContent.Trim()
                    
                    $output.AppendLine("^$($footnote.Name): $convertedFootnoteContent") | Out-Null
                }
            }
        }
        
        # Close node (T024)
        $output.AppendLine("@endnode") | Out-Null
        $output.AppendLine("") | Out-Null
    }
    
    return $output.ToString()
}

#endregion

#region Content Conversion

function Format-HeaderByLevel {
    <#
    .SYNOPSIS
        Format header title based on level (T044-T045).
    
    .DESCRIPTION
        Applies AmigaGuide formatting per markdown-amigaguide-mapping-v3.md:
        - H1: @{fg shine}@{b}Title@{ub} + ~~~ separator + @{fg text}
        - H2: @{b}Title@{ub}
        - H3: @{b}Title@{ub}
        - H4-H6: Plain text (no formatting)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [int]$Level
    )
    
    $result = [System.Text.StringBuilder]::new()
    
    switch ($Level) {
        1 {
            # T044: H1 with shine color, bold, and separator
            $result.AppendLine("@{fg shine}@{b}$Title@{ub}") | Out-Null
            $separator = "~" * ($Title.Length)
            if ($separator.Length -lt 15) { $separator = "~" * 15 }
            $result.AppendLine("$separator@{fg text}") | Out-Null
        }
        2 {
            # T045: H2 with bold only
            $result.AppendLine("@{b}$Title@{ub}") | Out-Null
        }
        3 {
            # T045: H3 with bold
            $result.AppendLine("@{b}$Title@{ub}") | Out-Null
        }
        default {
            # T045: H4-H6 plain text
            $result.AppendLine($Title) | Out-Null
        }
    }
    
    return $result.ToString()
}

function ConvertTo-AmigaGuideFormat {
    <#
    .SYNOPSIS
        Convert Markdown content to AmigaGuide format (Phase 4A + 4B extended).
    
    .DESCRIPTION
        Applies formatting conversions:
        - Bold variants: **bold**, __bold__ (T037)
        - Italic variants: *italic*, _italic_ (T038)
        - Combined: ***bold+italic***, ___bold+italic___ (T039)
        - Links (T023, T055-T058, T067-T076)
        - Footnotes (T077-T079)
        - Special character escaping (T025)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]  # Allow empty strings (will be filtered earlier in New-AmigaGuideDocument)
        [string]$Text,
        
        [Parameter(Mandatory=$false)]
        [int]$Level = 0,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Footnotes = @{}
    )
    
    # Note: MarkdownParser functions are already imported by the main script
    # No need to reimport here (causes scope issues)
    
    # Handle empty/whitespace-only content
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return [string]::Empty
    }
    
    $result = $Text
    
    # T077-T079: Process footnote references FIRST (before escaping)
    if ($Footnotes.References) {
        # Sort by start position (descending) to avoid index shifts
        $sortedRefs = $Footnotes.References | Sort-Object -Property Start -Descending
        
        foreach ($ref in $sortedRefs) {
            # [^1] → ^1
            $replacement = "^$($ref.Label)"
            $result = $result.Remove($ref.Start, $ref.Length).Insert($ref.Start, $replacement)
        }
    }
    
    # T080-T081: Process tables FIRST (before other line-level processing)
    # Must be done BEFORE separators, lists, etc. to keep tables intact
    $tables = Parse-Tables -Text $result
    if ($tables.Count -gt 0) {
        # Sort by start position descending to avoid index shifts during replacement
        $tables = $tables | Sort-Object -Property StartLine -Descending
        
        foreach ($table in $tables) {
            # Create replacement with @{code} wrapper
            $tableContent = $table.RawText
            $tableReplacement = "@{code}`n$tableContent`n@{plain}"
            
            # Normalize line endings for matching (content may have \r\n, table has \n)
            $tableContentNormalized = $tableContent -replace "`r`n", "`n"
            $resultNormalized = $result -replace "`r`n", "`n"
            
            # Use simple string replacement (more reliable than regex for multiline)
            $resultNormalized = $resultNormalized.Replace($tableContentNormalized, $tableReplacement)
            
            # Restore line endings and update result
            $result = $resultNormalized -replace "`n", "`r`n"
        }
    }
    
    # T051-T052: Process separators (line-level transformations)
    $result = Parse-Separators -Text $result
    if ([string]::IsNullOrWhiteSpace($result)) { return [string]::Empty }
    
    # T049-T050: Process blockquotes (adds indentation commands)
    $result = Parse-Blockquotes -Text $result
    if ([string]::IsNullOrWhiteSpace($result)) { return [string]::Empty }
    
    # T047-T048: Process lists (preserve indentation)
    $result = Parse-Lists -Text $result
    if ([string]::IsNullOrWhiteSpace($result)) { return [string]::Empty }
    
    # T059-T062: Process code blocks (must be before inline formatting)
    $result = Parse-CodeBlocks -Text $result
    if ([string]::IsNullOrWhiteSpace($result)) { return [string]::Empty }
    
    # T053-T054: Process paragraph line breaks
    $result = Parse-Paragraphs -Text $result
    if ([string]::IsNullOrWhiteSpace($result)) { return [string]::Empty }
    
    # Protect @{code} and @{plain} tags from escaping (T080-T081)
    $result = $result -replace '@\{code\}', '___AMIGAGUIDE_CODE___'
    $result = $result -replace '@\{plain\}', '___AMIGAGUIDE_PLAIN___'
    
    # Escape special characters (T025)
    $result = $result -replace '@', '@@'
    $result = $result -replace '\\\\', '\\\\'
    
    # Restore protected tags
    $result = $result -replace '___AMIGAGUIDE_CODE___', '@{code}'
    $result = $result -replace '___AMIGAGUIDE_PLAIN___', '@{plain}'
    
    # T039: Combined formatting (must process BEFORE single markers)
    # ___text___ → combined with style
    $result = $result -replace '___([^_]+)___', '@{b}@{i}@{fg highlight}$1@{fg text}@{ui}@{ub}'
    
    # ***text*** → combined standard
    $result = $result -replace '\*\*\*([^*]+)\*\*\*', '@{b}@{i}$1@{ui}@{ub}'
    
    # T037: __bold__ → styled (distinct from **bold**)
    $result = $result -replace '(?<!_)__([^_]+)__(?!_)', '@{fg highlight}$1@{fg text}'
    
    # **bold** → standard (T021)
    $result = $result -replace '(?<!\*)\*\*([^*]+)\*\*(?!\*)', '@{b}$1@{ub}'
    
    # T038: _italic_ → styled (distinct from *italic*)
    $result = $result -replace '(?<!_)_([^_]+)_(?!_)', '@{i}@{fg highlight}$1@{fg text}@{ui}'
    
    # *italic* → standard (T022)
    $result = $result -replace '(?<!\*)\*([^*]+)\*(?!\*)', '@{i}$1@{ui}'
    
    # T060-T061: Process minimal HTML tags
    $result = Parse-HTMLTags -Text $result
    
    # T055-T058, T067-T076: Convert links with all variants (Tier 1 + Tier 2)
    $linkMatches = Parse-Links -Text $result
    
    # Sort by start position (descending) to avoid index shifts
    $linkMatches = $linkMatches | Sort-Object -Property Start -Descending
    
    foreach ($link in $linkMatches) {
        $replacement = ""
        
        switch ($link.Type) {
            'Internal' {
                # [Text](#node) → @{"Text" link "node"} (# stripped)
                if ($link.HasLineNumber) {
                    $replacement = "@{`"$($link.Label)`" link `"$($link.Target)`" $($link.LineNumber)}"
                } else {
                    $replacement = "@{`"$($link.Label)`" link `"$($link.Target)`"}"
                }
            }
            'ExternalMarkdown' {
                # [Text](file.md) or [Text](file.md/node)
                # Convert .md to .guide
                $targetPath = $link.Target -replace '\.md', '.guide'
                
                # Add /main if no node specified
                if ($targetPath -notmatch '/') {
                    $targetPath += '/main'
                }
                
                if ($link.HasLineNumber) {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`" $($link.LineNumber)}"
                } else {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`"}"
                }
            }
            'ExternalGuide' {
                # [Text](file.guide) or [Text](file.guide/node)
                $targetPath = $link.Target
                
                # Add /main if no node specified
                if ($targetPath -notmatch '/') {
                    $targetPath += '/main'
                }
                
                if ($link.HasLineNumber) {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`" $($link.LineNumber)}"
                } else {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`"}"
                }
            }
            'ExternalText' {
                # [Text](file.txt) → link to /main
                $targetPath = $link.Target
                if ($targetPath -notmatch '/') {
                    $targetPath += '/main'
                }
                
                if ($link.HasLineNumber) {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`" $($link.LineNumber)}"
                } else {
                    $replacement = "@{`"$($link.Label)`" link `"$targetPath`"}"
                }
            }
            'NonTextFile' {
                # [Text](image.iff) → link to /main (opens in viewer)
                $targetPath = $link.Target
                if ($targetPath -notmatch '/') {
                    $targetPath += '/main'
                }
                
                $replacement = "@{`"$($link.Label)`" link `"$targetPath`"}"
            }
            'HTTP' {
                # [Text](http://url) → @{"Text" system "OpenURL http://url"} + visible URL
                $replacement = "@{`"$($link.Label)`" system `"OpenURL $($link.Target)`"} : $($link.Target)"
            }
            'FTP' {
                # [Text](ftp://url) → @{"Text" system "OpenURL ftp://url"} + visible URL
                $replacement = "@{`"$($link.Label)`" system `"OpenURL $($link.Target)`"} : $($link.Target)"
            }
            'Mailto' {
                # [Text](mailto:email) → @{"Text" system "OpenURL mailto:email"} + visible email
                $emailAddress = $link.Target -replace '^mailto:', ''
                $replacement = "@{`"$($link.Label)`" system `"OpenURL $($link.Target)`"} : $emailAddress"
            }
            'UnsupportedProtocol' {
                # [Text](unknown:protocol) → bold colored text (no underline possible)
                $replacement = "@{b}@{fg highlight}$($link.Label)@{fg text}@{ub}"
            }
            'Autolink' {
                # <https://url> → preserve as plain text
                $replacement = $link.Label
            }
            default {
                # [Text](target) → @{"Text" link "target"}
                if ($link.HasLineNumber) {
                    $replacement = "@{`"$($link.Label)`" link `"$($link.Target)`" $($link.LineNumber)}"
                } else {
                    $replacement = "@{`"$($link.Label)`" link `"$($link.Target)`"}"
                }
            }
        }
        
        # Replace in reverse order to preserve indices
        $result = $result.Remove($link.Start, $link.Length).Insert($link.Start, $replacement)
    }
    
    # Preserve line breaks and paragraphs (T026)
    # Already preserved by default in PowerShell string handling
    
    return $result
}

#endregion

#region Helper Functions

function Format-BoldText {
    <#
    .SYNOPSIS
        Convert bold Markdown to AmigaGuide @{b}/@{ub}.
    #>
    param([string]$Text)
    return "@{b}$Text@{ub}"
}

function Format-ItalicText {
    <#
    .SYNOPSIS
        Convert italic Markdown to AmigaGuide @{i}/@{ui}.
    #>
    param([string]$Text)
    return "@{i}$Text@{ui}"
}

function Format-Link {
    <#
    .SYNOPSIS
        Convert Markdown link to AmigaGuide @{link}.
    #>
    param(
        [string]$Label,
        [string]$Target
    )
    return "@{`"$Label`" link `"$Target`"}"
}

#endregion


# ==============================================
# Module: LinkedDocHandler.psm1
# ==============================================

#region Data Structures

class LinkedDocument {
    [string]$SourceFile
    [string]$TargetFile
    [string]$ResolvedPath
    [string]$NodeId
    [int]$LineNumber
    [string]$LinkLabel
    [string]$InclusionMode
    [bool]$Exists
    
    LinkedDocument([string]$sourceFile, [string]$targetFile) {
        $this.SourceFile = $sourceFile
        $this.TargetFile = $targetFile
        $this.ResolvedPath = ""
        $this.NodeId = ""
        $this.LineNumber = 0
        $this.LinkLabel = ""
        $this.InclusionMode = "Ask"
        $this.Exists = $false
    }
}

class NodeInfo {
    [string]$Id
    [string]$Document
    [bool]$IsReferenced
    [System.Collections.ArrayList]$References
    
    NodeInfo([string]$id, [string]$document) {
        $this.Id = $id
        $this.Document = $document
        $this.IsReferenced = $false
        $this.References = [System.Collections.ArrayList]::new()
    }
}

class NodeReferenceGraph {
    [hashtable]$Nodes
    [hashtable]$Edges
    [System.Collections.ArrayList]$EntryPoints
    
    NodeReferenceGraph() {
        $this.Nodes = @{}
        $this.Edges = @{}
        $this.EntryPoints = [System.Collections.ArrayList]::new()
    }
    
    [void]AddNode([string]$id, [string]$document) {
        if (-not $this.Nodes.ContainsKey($id)) {
            $this.Nodes[$id] = [NodeInfo]::new($id, $document)
        }
    }
    
    [void]AddEdge([string]$fromId, [string]$toId) {
        if (-not $this.Edges.ContainsKey($fromId)) {
            $this.Edges[$fromId] = [System.Collections.ArrayList]::new()
        }
        if ($this.Edges[$fromId] -notcontains $toId) {
            [void]$this.Edges[$fromId].Add($toId)
        }
        if ($this.Nodes.ContainsKey($toId)) {
            $this.Nodes[$toId].IsReferenced = $true
        }
        if ($this.Nodes.ContainsKey($fromId)) {
            [void]$this.Nodes[$fromId].References.Add($toId)
        }
    }
    
    [System.Collections.ArrayList]GetReachableNodes() {
        $reachable = [System.Collections.ArrayList]::new()
        $visited = @{}
        $queue = [System.Collections.Queue]::new()
        
        foreach ($entry in $this.EntryPoints) {
            [void]$queue.Enqueue($entry)
        }
        
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            if ($visited.ContainsKey($current)) {
                continue
            }
            $visited[$current] = $true
            [void]$reachable.Add($current)
            
            if ($this.Edges.ContainsKey($current)) {
                foreach ($target in $this.Edges[$current]) {
                    if (-not $visited.ContainsKey($target)) {
                        [void]$queue.Enqueue($target)
                    }
                }
            }
        }
        
        return $reachable
    }
    
    [hashtable]DetectCycles() {
        $result = @{
            HasCycles = $false
            Cycles = [System.Collections.ArrayList]::new()
        }
        
        $visited = @{}
        $recStack = @{}
        
        foreach ($nodeId in $this.Nodes.Keys) {
            if (-not $visited.ContainsKey($nodeId)) {
                $cycle = $this.DetectCyclesDFS($nodeId, $visited, $recStack, [System.Collections.ArrayList]::new())
                if ($cycle) {
                    $result.HasCycles = $true
                    [void]$result.Cycles.Add($cycle)
                }
            }
        }
        
        return $result
    }
    
    hidden [System.Collections.ArrayList]DetectCyclesDFS([string]$nodeId, [hashtable]$visited, [hashtable]$recStack, [System.Collections.ArrayList]$path) {
        $visited[$nodeId] = $true
        $recStack[$nodeId] = $true
        [void]$path.Add($nodeId)
        
        if ($this.Edges.ContainsKey($nodeId)) {
            foreach ($neighbor in $this.Edges[$nodeId]) {
                if (-not $visited.ContainsKey($neighbor)) {
                    $cycle = $this.DetectCyclesDFS($neighbor, $visited, $recStack, $path)
                    if ($cycle) {
                        return $cycle
                    }
                }
                elseif ($recStack.ContainsKey($neighbor)) {
                    # Found a cycle
                    $cycleStart = $path.IndexOf($neighbor)
                    $cyclePath = [System.Collections.ArrayList]::new()
                    for ($i = $cycleStart; $i -lt $path.Count; $i++) {
                        [void]$cyclePath.Add($path[$i])
                    }
                    [void]$cyclePath.Add($neighbor)
                    return $cyclePath
                }
            }
        }
        
        $recStack.Remove($nodeId)
        $path.RemoveAt($path.Count - 1)
        return $null
    }
}

class ConversionContext {
    [string]$Mode
    [string]$RootDocument
    [System.Collections.Generic.HashSet[string]]$ProcessedDocuments
    [hashtable]$GlobalNodeRegistry
    [hashtable]$NodeIdMapping
    [System.Collections.Queue]$LinkResolutionQueue
    [int]$MaxDepth
    [int]$CurrentDepth
    [System.Collections.ArrayList]$Warnings
    [System.Collections.ArrayList]$Errors
    
    ConversionContext([string]$mode, [string]$rootDocument, [int]$maxDepth) {
        $this.Mode = $mode
        $this.RootDocument = $rootDocument
        $this.ProcessedDocuments = [System.Collections.Generic.HashSet[string]]::new()
        $this.GlobalNodeRegistry = @{}
        $this.NodeIdMapping = @{}
        $this.LinkResolutionQueue = [System.Collections.Queue]::new()
        $this.MaxDepth = $maxDepth
        $this.CurrentDepth = 0
        $this.Warnings = [System.Collections.ArrayList]::new()
        $this.Errors = [System.Collections.ArrayList]::new()
    }
}

#endregion

#region Link Parsing

function Find-LinkedDocuments {
    <#
    .SYNOPSIS
        Discover linked documents using BFS traversal.
    
    .DESCRIPTION
        Traverses Markdown files starting from root document, discovering all linked .md files.
        Detects circular dependencies and enforces MaxDepth limit.
    
    .PARAMETER FilePath
        Path to the root Markdown file.
    
    .PARAMETER MaxDepth
        Maximum traversal depth (default: 10).
    
    .PARAMETER Mode
        Conversion mode: Merge, Separate, Optimized, or Interactive.
    
    .OUTPUTS
        ConversionContext with discovered documents and link graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Merge', 'Separate', 'Optimized', 'Interactive')]
        [string]$Mode = 'Separate'
    )
    
    $context = [ConversionContext]::new($Mode, $FilePath, $MaxDepth)
    $queue = [System.Collections.Queue]::new()
    
    # Start with root document
    $rootResolved = Resolve-Path -Path $FilePath -ErrorAction Stop
    [void]$queue.Enqueue(@{
        Path = $rootResolved.Path
        Depth = 0
    })
    
    while ($queue.Count -gt 0) {
        $item = $queue.Dequeue()
        $currentFile = $item.Path
        $currentDepth = $item.Depth
        
        # Check if already processed
        if ($context.ProcessedDocuments.Contains($currentFile)) {
            continue
        }
        
        # Check depth limit
        if ($currentDepth -gt $MaxDepth) {
            [void]$context.Warnings.Add("Max depth ($MaxDepth) reached at: $currentFile")
            continue
        }
        
        # Mark as processed
        [void]$context.ProcessedDocuments.Add($currentFile)
        
        # Read file content
        if (-not (Test-Path -Path $currentFile -PathType Leaf)) {
            [void]$context.Errors.Add("File not found: $currentFile")
            continue
        }
        
        $content = Get-Content -Path $currentFile -Raw -ErrorAction SilentlyContinue
        if (-not $content) {
            [void]$context.Warnings.Add("Empty or unreadable file: $currentFile")
            continue
        }
        
        # Find all Markdown links in current file
        $links = Find-MarkdownLinks -Content $content -SourceFile $currentFile
        
        foreach ($link in $links) {
            if ($link.TargetFile -match '\.md$') {
                # Resolve relative path
                $baseDir = Split-Path -Path $currentFile -Parent
                $targetPath = Join-Path -Path $baseDir -ChildPath $link.TargetFile
                
                if (Test-Path -Path $targetPath -PathType Leaf) {
                    $resolvedTarget = (Resolve-Path -Path $targetPath).Path
                    $link.ResolvedPath = $resolvedTarget
                    $link.Exists = $true
                    
                    # Add to queue if not yet processed
                    if (-not $context.ProcessedDocuments.Contains($resolvedTarget)) {
                        [void]$queue.Enqueue(@{
                            Path = $resolvedTarget
                            Depth = $currentDepth + 1
                        })
                    }
                }
                else {
                    $link.Exists = $false
                    [void]$context.Warnings.Add("Broken link in $currentFile`: $($link.TargetFile) (will create external link anyway)")
                }
                
                # Store link for resolution
                [void]$context.LinkResolutionQueue.Enqueue($link)
            }
        }
    }
    
    return $context
}

function Find-MarkdownLinks {
    <#
    .SYNOPSIS
        Parse Markdown content to extract all links.
    
    .DESCRIPTION
        Extracts links from Markdown using regex pattern for cross-file references.
        Pattern: [label](file.md#node/line)
    
    .PARAMETER Content
        Markdown content string.
    
    .PARAMETER SourceFile
        Path to source file (for context).
    
    .OUTPUTS
        Array of LinkedDocument objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceFile
    )
    
    $links = [System.Collections.ArrayList]::new()
    
    # Regex pattern: [label](target#node/line)
    # Captures: label, file path, node anchor, line number
    # Supports: .md, .guide, any text extensions (.c, .h, .py, .txt, etc.), images, URLs
    $pattern = '\[([^\]]+)\]\(([^)#]+?)(?:#([^/)]+))?(?:/(\d+))?\)'
    
    $matches = [regex]::Matches($Content, $pattern)
    
    foreach ($match in $matches) {
        $label = $match.Groups[1].Value
        $target = $match.Groups[2].Value
        $nodeId = if ($match.Groups[3].Success) { $match.Groups[3].Value } else { "" }
        $lineNum = if ($match.Groups[4].Success) { [int]$match.Groups[4].Value } else { 0 }
        
        $linkedDoc = [LinkedDocument]::new($SourceFile, $target)
        $linkedDoc.LinkLabel = $label
        $linkedDoc.NodeId = $nodeId
        $linkedDoc.LineNumber = $lineNum
        
        [void]$links.Add($linkedDoc)
    }
    
    return $links
}

#endregion

#region Node Conflict Resolution

function Resolve-NodeIdConflicts {
    <#
    .SYNOPSIS
        Detect and resolve node ID conflicts across multiple documents.
    
    .DESCRIPTION
        In Merge mode, multiple documents may have nodes with the same ID.
        This function detects conflicts and renames duplicates with _2, _3, etc.
    
    .PARAMETER Context
        ConversionContext with processed documents.
    
    .PARAMETER Nodes
        Array of all nodes from all documents.
    
    .OUTPUTS
        Updated ConversionContext with NodeIdMapping populated.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ConversionContext]$Context,
        
        [Parameter(Mandatory = $true)]
        [array]$Nodes
    )
    
    $idCounts = @{}
    
    # First pass: count occurrences
    foreach ($node in $Nodes) {
        if (-not $idCounts.ContainsKey($node.Id)) {
            $idCounts[$node.Id] = 0
        }
        $idCounts[$node.Id]++
    }
    
    # Second pass: assign unique IDs
    $idCounters = @{}
    foreach ($node in $Nodes) {
        $originalId = $node.Id
        
        if ($idCounts[$originalId] -gt 1) {
            # Need to rename
            if (-not $idCounters.ContainsKey($originalId)) {
                $idCounters[$originalId] = 1
            }
            
            $counter = $idCounters[$originalId]
            $newId = if ($counter -eq 1) { $originalId } else { "${originalId}_${counter}" }
            
            $Context.NodeIdMapping[$originalId] = $newId
            $node.Id = $newId
            
            $idCounters[$originalId]++
            
            if ($counter -gt 1) {
                [void]$Context.Warnings.Add("Renamed duplicate node ID: $originalId -> $newId")
            }
        }
        else {
            $Context.NodeIdMapping[$originalId] = $originalId
        }
    }
    
    return $Context
}

function Update-LinkReferences {
    <#
    .SYNOPSIS
        Update link references to use renamed node IDs.
    
    .DESCRIPTION
        After node ID conflict resolution, updates all @{link} references to use new IDs.
    
    .PARAMETER Content
        Content string with links.
    
    .PARAMETER Mapping
        Hashtable of original ID -> new ID mappings.
    
    .OUTPUTS
        Updated content string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Mapping
    )
    
    $updated = $Content
    
    foreach ($originalId in $Mapping.Keys) {
        $newId = $Mapping[$originalId]
        if ($originalId -ne $newId) {
            # Update link references
            $pattern = "@\{`"([^`"]+)`"\s+link\s+`"$originalId`""
            $replacement = "@{`"`$1`" link `"$newId`""
            $updated = $updated -replace $pattern, $replacement
        }
    }
    
    return $updated
}

#endregion



#region Conversion Modes

function Invoke-MergeMode {
    <#
    .SYNOPSIS
        Merge all linked documents into single AmigaGuide file.
    
    .DESCRIPTION
        Combines all discovered documents into one, resolving node ID conflicts.
    
    .PARAMETER Context
        ConversionContext with discovered documents.
    
    .PARAMETER Parser
        MarkdownParser module instance.
    
    .OUTPUTS
        Merged document content array.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ConversionContext]$Context,
        
        [Parameter(Mandatory = $true)]
        [object]$Parser
    )
    
    $allNodes = [System.Collections.ArrayList]::new()
    $globalCommands = [System.Collections.ArrayList]::new()
    
    foreach ($docPath in $Context.ProcessedDocuments) {
        Write-Verbose "Processing $docPath for merge..."
        
        $content = Get-Content -Path $docPath -Raw
        $doc = & $Parser -FilePath $docPath -Content $content
        
        if ($doc.GlobalCommands) {
            foreach ($cmd in $doc.GlobalCommands) {
                [void]$globalCommands.Add($cmd)
            }
        }
        
        if ($doc.Nodes) {
            foreach ($node in $doc.Nodes) {
                $node | Add-Member -NotePropertyName 'SourceDocument' -NotePropertyValue $docPath -Force
                [void]$allNodes.Add($node)
            }
        }
    }
    
    # Resolve node ID conflicts
    $Context = Resolve-NodeIdConflicts -Context $Context -Nodes $allNodes
    
    return @{
        Nodes = $allNodes
        GlobalCommands = $globalCommands
        Context = $Context
    }
}

function Invoke-SeparateMode {
    <#
    .SYNOPSIS
        Generate separate AmigaGuide files for each linked document.
    
    .DESCRIPTION
        Creates individual .guide files with cross-file link syntax.
    
    .PARAMETER Context
        ConversionContext with discovered documents.
    
    .OUTPUTS
        Array of document/output path pairs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ConversionContext]$Context
    )
    
    $outputs = [System.Collections.ArrayList]::new()
    
    foreach ($docPath in $Context.ProcessedDocuments) {
        $outputPath = [System.IO.Path]::ChangeExtension($docPath, '.guide')
        [void]$outputs.Add(@{
            InputPath = $docPath
            OutputPath = $outputPath
        })
    }
    
    return $outputs
}

function Invoke-OptimizedMode {
    <#
    .SYNOPSIS
        Include only reachable nodes in output.
    
    .DESCRIPTION
        Performs reachability analysis from entry points (@index, @help, first node).
        Only includes nodes that can be reached through navigation.
    
    .PARAMETER Context
        ConversionContext with discovered documents.
    
    .PARAMETER AllNodes
        All parsed nodes.
    
    .OUTPUTS
        Filtered array of reachable nodes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ConversionContext]$Context,
        
        [Parameter(Mandatory = $true)]
        [array]$AllNodes
    )
    
    $graph = [NodeReferenceGraph]::new()
    
    # Build reference graph
    foreach ($node in $AllNodes) {
        [void]$graph.AddNode($node.Id, $node.SourceDocument)
    }
    
    # Add entry points
    if ($AllNodes.Count -gt 0) {
        [void]$graph.EntryPoints.Add($AllNodes[0].Id)  # First node
    }
    
    # Parse links in content to build edges
    foreach ($node in $AllNodes) {
        $linkMatches = [regex]::Matches($node.Content, '@\{"[^"]+"\s+link\s+"([^"]+)"')
        foreach ($match in $linkMatches) {
            $targetId = $match.Groups[1].Value
            [void]$graph.AddEdge($node.Id, $targetId)
        }
    }
    
    # Get reachable nodes
    $reachableIds = $graph.GetReachableNodes()
    $filteredNodes = $AllNodes | Where-Object { $reachableIds -contains $_.Id }
    
    $removedCount = $AllNodes.Count - $filteredNodes.Count
    if ($removedCount -gt 0) {
        [void]$Context.Warnings.Add("Optimized mode removed $removedCount unreachable nodes")
    }
    
    return $filteredNodes
}

function Invoke-InteractiveMode {
    <#
    .SYNOPSIS
        Prompt user for each linked document inclusion.
    
    .DESCRIPTION
        Asks user whether to merge, separate, or ignore each discovered document.
    
    .PARAMETER Context
        ConversionContext with discovered documents.
    
    .OUTPUTS
        Updated ConversionContext with user choices.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ConversionContext]$Context
    )
    
    $choices = @{}
    $applyToAll = $false
    $defaultChoice = ""
    
    foreach ($docPath in $Context.ProcessedDocuments) {
        if ($docPath -eq $Context.RootDocument) {
            $choices[$docPath] = "Main"
            continue
        }
        
        if ($applyToAll) {
            $choices[$docPath] = $defaultChoice
            continue
        }
        
        Write-Host "`nLinked document found: $docPath" -ForegroundColor Cyan
        Write-Host "Choose action:" -ForegroundColor Yellow
        Write-Host "  [M] Merge into main document"
        Write-Host "  [S] Create Separate .guide file"
        Write-Host "  [I] Ignore (don't convert)"
        Write-Host "  [A] Apply choice to All remaining documents"
        
        $response = Read-Host "Your choice (M/S/I/A)"
        
        switch ($response.ToUpper()) {
            'M' { $choices[$docPath] = "Merge" }
            'S' { $choices[$docPath] = "Separate" }
            'I' { $choices[$docPath] = "Ignore" }
            'A' {
                Write-Host "Apply which choice to all remaining? (M/S/I)" -ForegroundColor Yellow
                $defaultChoice = Read-Host
                $applyToAll = $true
                
                switch ($defaultChoice.ToUpper()) {
                    'M' { $choices[$docPath] = "Merge"; $defaultChoice = "Merge" }
                    'S' { $choices[$docPath] = "Separate"; $defaultChoice = "Separate" }
                    'I' { $choices[$docPath] = "Ignore"; $defaultChoice = "Ignore" }
                    default { $choices[$docPath] = "Separate"; $defaultChoice = "Separate" }
                }
            }
            default { $choices[$docPath] = "Separate" }
        }
    }
    
    # Store choices in context
    foreach ($doc in $choices.Keys) {
        $Context.GlobalNodeRegistry[$doc] = $choices[$doc]
    }
    
    return $Context
}

#endregion

#region Cross-File Link Generation

function Format-CrossFileLink {
    <#
    .SYNOPSIS
        Generate AmigaGuide cross-file link syntax.
    
    .DESCRIPTION
        Creates @{link} command with file.guide/nodeid and optional line number.
        Format: @{"label" link "target.guide/nodeid" line}
    
    .PARAMETER Label
        Link display text.
    
    .PARAMETER TargetFile
        Target .guide file name.
    
    .PARAMETER NodeId
        Target node ID within file.
    
    .PARAMETER LineNumber
        Optional line number within node.
    
    .OUTPUTS
        Formatted AmigaGuide link string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetFile,
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [int]$LineNumber = 0
    )
    
    $guideName = [System.IO.Path]::GetFileNameWithoutExtension($TargetFile) + ".guide"
    
    if ($NodeId) {
        $target = "$guideName/$NodeId"
    }
    else {
        $target = $guideName
    }
    
    if ($LineNumber -gt 0) {
        return "@{`"$Label`" link `"$target`" $LineNumber}"
    }
    else {
        return "@{`"$Label`" link `"$target`"}"
    }
}

#endregion


#endregion

#region Main Script

# Exit codes (per contracts/cli-interface.md)
$ExitCodes = @{
    Success = 0
    NotFound = 2
    InvalidSyntax = 3
    UserCancelled = 6
    Warning = 98
    UnknownError = 99
}

# Script metadata
$script:MD2AG_VERSION = "0.6.0"
$script:SCRIPT_NAME = $MyInvocation.MyCommand.Name

#region Error Handling Functions

function Write-ConversionError {
    <#
    .SYNOPSIS
        Write detailed error message with file context.
    
    .DESCRIPTION
        Formats error messages with file path, line number, context, and suggestions
        per research.md error reporting format.
    #>
    param(
        [string]$FilePath,
        [int]$LineNumber = 0,
        [string]$Context = "",
        [string]$Message,
        [string]$Suggestion = "",
        [int]$ExitCode = $ExitCodes.UnknownError
    )

    Write-Host "ERROR: $Message" -ForegroundColor Red
    
    if ($FilePath) {
        Write-Host "  File: $FilePath" -ForegroundColor Yellow
    }
    
    if ($LineNumber -gt 0) {
        Write-Host "  Line: $LineNumber" -ForegroundColor Yellow
    }
    
    if ($Context) {
        Write-Host "  Context: $Context" -ForegroundColor Gray
    }
    
    if ($Suggestion) {
        Write-Host "  Suggestion: $Suggestion" -ForegroundColor Cyan
    }

    exit $ExitCode
}

#endregion

#region Parameter Validation

# -Version flag: display version and exit
if ($Version) {
    Write-Host "Version: $script:MD2AG_VERSION" -ForegroundColor White
    Write-Host "Author: Vincent Buzzano" -ForegroundColor Gray
    Write-Host "License: MIT" -ForegroundColor Gray
    exit $ExitCodes.Success
}

Write-Host ""
Write-Host "=============================================="
Write-Host "           MD2AG Converter v$script:MD2AG_VERSION             "
Write-Host "=============================================="
Write-Host ""

# Auto-generate output path if not provided
if (-not $OutputPath -and $InputPath) {
    $OutputPath = [System.IO.Path]::ChangeExtension($InputPath, '.guide')
    Write-Verbose "Output path not specified, using: $OutputPath"
}

# -ValidateOnly mode: -Output is optional (already set above)
if ($ValidateOnly) {
    # Output path already auto-generated if needed
}

# Validate InputPath is provided (unless -Version flag)
if (-not $InputPath -and -not $Version) {
    Write-Host "ERROR: InputPath parameter is required" -ForegroundColor Red
    Write-Host "Usage: $script:SCRIPT_NAME -Input <file.md> [-Output <file.guide>]" -ForegroundColor Yellow
    Write-Host "       $script:SCRIPT_NAME <file.md>  (Output defaults to <file.guide>)" -ForegroundColor Yellow
    Write-Host "       $script:SCRIPT_NAME -Version" -ForegroundColor Yellow
    exit $ExitCodes.NotFound
}

# Validate Input file exists
if ($InputPath -and -not (Test-Path -Path $InputPath -PathType Leaf)) {
    Write-ConversionError `
        -FilePath $InputPath `
        -Message "Input file not found: $InputPath" `
        -Suggestion "Check the file path and ensure the file exists." `
        -ExitCode $ExitCodes.NotFound
}

# Validate Input has .md extension (warning only)
if ($InputPath -notmatch '\.md$') {
    Write-Host "WARNING: Input file does not have .md extension: $InputPath" -ForegroundColor Yellow
}

# Validate Output has .guide extension (warning only)
if ($OutputPath -notmatch '\.guide$') {
    Write-Host "WARNING: Output file does not have .guide extension: $OutputPath" -ForegroundColor Yellow
}

# Validate Output directory exists or can be created
$outputDir = Split-Path -Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path -Path $outputDir)) {
    try {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Verbose "Created output directory: $outputDir"
    }
    catch {
        Write-ConversionError `
            -FilePath $OutputPath `
            -Message "Cannot create output directory: $outputDir" `
            -Suggestion "Ensure you have write permissions for the target location." `
            -ExitCode $ExitCodes.UnknownError
    }
}

# Check if output file exists (unless -Force)
if ((Test-Path -Path $OutputPath) -and -not $Force -and -not $WhatIf) {
    $response = Read-Host "Output file exists: $OutputPath. Overwrite? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Conversion cancelled by user." -ForegroundColor Yellow
        exit $ExitCodes.UserCancelled
    }
}

#endregion

#region Main Conversion Flow

# Import modules
$modulePath = Join-Path $PSScriptRoot "modules"

Write-Verbose "MD2AG Converter v0.1.0-dev"
Write-Verbose "Input: $InputPath"
Write-Verbose "Output: $OutputPath"
Write-Verbose "Mode: $Mode"
Write-Verbose "Encoding: $Encoding"

if ($WhatIf) {
    Write-Host "What if: Processing '$InputPath'"
    Write-Host "What if: Would create '$OutputPath'"
    Write-Host "What if: Mode = $Mode, MaxDepth = $MaxDepth, Encoding = $Encoding"
    
    # Preview analysis
    try {
        $content = Get-Content -Path $InputPath -Raw -Encoding UTF8
        $doc = Parse-MarkdownHeaders -Content $content -FilePath $InputPath
        Write-Host "What if: Would process $($doc.Nodes.Count) nodes"
        foreach ($node in $doc.Nodes) {
            Write-Host "  - Node: '$($node.Title)' (Level $($node.Level))" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "What if: Error analyzing input: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    exit $ExitCodes.Success
}

if ($ValidateOnly) {
    Write-Host "Validation mode: Checking input syntax..." -ForegroundColor Cyan
    
    try {
        $content = Get-Content -Path $InputPath -Raw -Encoding UTF8
        $validation = Test-MarkdownSyntax -Content $content -FilePath $InputPath
        
        if ($validation.IsValid) {
            Write-Host "✓ Validation passed - no errors detected" -ForegroundColor Green
        }
        else {
            Write-Host "✗ Validation failed - $($validation.Errors.Count) error(s) found" -ForegroundColor Red
            
            foreach ($err in $validation.Errors) {
                Write-Host ""
                Write-ConversionError `
                    -FilePath $InputPath `
                    -LineNumber $err.Line `
                    -Context $err.Context `
                    -Message $err.Message `
                    -Suggestion $err.Suggestion `
                    -ExitCode 0  # Don't exit yet
            }
            
            exit $ExitCodes.InvalidSyntax
        }
        
        # Display warnings
        if ($validation.Warnings.Count -gt 0) {
            Write-Host ""
            Write-Host "Warnings: $($validation.Warnings.Count)" -ForegroundColor Yellow
            foreach ($warning in $validation.Warnings) {
                Write-ValidationWarning -Warning $warning
            }
        }
        
        exit $ExitCodes.Success
    }
    catch {
        Write-ConversionError `
            -FilePath $InputPath `
            -Message "Validation error: $($_.Exception.Message)" `
            -Suggestion "Check file encoding and permissions" `
            -ExitCode $ExitCodes.UnknownError
    }
}

# Real conversion
Write-Host ""
Write-Host "Converting Markdown → AmigaGuide" -ForegroundColor Cyan
Write-Host "  Input:  $InputPath" -ForegroundColor Gray
Write-Host "  Output: $OutputPath" -ForegroundColor Gray
Write-Host ""

# T166: Performance monitoring
$perfTimings = @{}
$totalTimer = [System.Diagnostics.Stopwatch]::StartNew()
$inputWarnings = @()
$context = $null

try {
    # Read input file (T029 - integrate parser)
    Write-Verbose "Reading input file..."
    $readTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $content = Get-Content -Path $InputPath -Raw -Encoding UTF8
    $readTimer.Stop()
    $perfTimings['FileRead'] = $readTimer.Elapsed
    
    # Validate header structure (T181-T182)
    Write-Verbose "Validating header structure..."
    $headerValidation = Test-HeaderStructure -FilePath $InputPath -Content $content
    
    if (-not $headerValidation.IsValid) {
        Write-Host "✗ Invalid header structure:" -ForegroundColor Red
        Write-Host "  $($headerValidation.ErrorMessage)" -ForegroundColor Red
        Write-Host "  File: $InputPath" -ForegroundColor Gray
        Write-Host "  Found: $($headerValidation.H1Count) H1 header(s)" -ForegroundColor Gray
        exit 1
    }
    
    # Validate input syntax
    Write-Verbose "Validating Markdown syntax..."
    $validationTimer = [System.Diagnostics.Stopwatch]::StartNew()
    
    $validation = Test-MarkdownSyntax -Content $content -FilePath $InputPath
    
    $validationTimer.Stop()
    $perfTimings['Validation'] = $validationTimer.Elapsed
    
    if (-not $validation.IsValid) {
        if ($Strict) {
            # Strict mode: abort on errors
            Write-Host "✗ Invalid Markdown syntax detected (strict mode):" -ForegroundColor Red
            foreach ($er in $validation.Errors) {
                Write-ConversionError `
                    -FilePath $InputPath `
                    -LineNumber $er.Line `
                    -Context $er.Context `
                    -Message $er.Message `
                    -Suggestion $er.Suggestion `
                    -ExitCode 0  # Don't exit yet
            }
            exit $ExitCodes.InvalidSyntax
        }
        else {
            # Permissive mode: show warnings but continue
            Write-Host "⚠ Markdown syntax issues detected (permissive mode - auto-fixing):" -ForegroundColor Yellow
            foreach ($err in $validation.Errors) {
                Write-Host "  WARNING: Line $($err.Line) - $($err.Message)" -ForegroundColor Yellow
                if ($err.Context) {
                    Write-Host "    Context: $($err.Context)" -ForegroundColor Gray
                }
                if ($err.Suggestion) {
                    Write-Host "    Auto-fix: $($err.Suggestion)" -ForegroundColor Cyan
                }
            }
            Write-Host "  Continuing with automatic fixes..." -ForegroundColor Cyan
            Write-Host ""
        }
    }
    
    # Store input warnings for display before success message
    $inputWarnings = $validation.Warnings
    Write-Verbose "Found $($inputWarnings.Count) input warning(s)"
    
    # Discover linked documents (T152 - integrate LinkedDocHandler)
    $allDocuments = @($InputPath)
    
    # Always discover linked documents to build the document graph
    Write-Verbose "Discovering linked documents (Mode: $Mode, MaxDepth: $MaxDepth)..."
    
    try {
        $context = Find-LinkedDocuments -FilePath $InputPath -MaxDepth $MaxDepth -Mode $Mode
        
        # Validate header structure for all discovered documents (T182)
        Write-Verbose "Validating header structure for all documents..."
        foreach ($docPath in $context.ProcessedDocuments.Keys) {
            $docContent = Get-Content -Path $docPath -Raw -Encoding UTF8
            $headerValidation = Test-HeaderStructure -FilePath $docPath -Content $docContent
            
            if (-not $headerValidation.IsValid) {
                Write-Host "✗ Invalid header structure in linked document:" -ForegroundColor Red
                Write-Host "  $($headerValidation.ErrorMessage)" -ForegroundColor Red
                Write-Host "  File: $docPath" -ForegroundColor Gray
                Write-Host "  Found: $($headerValidation.H1Count) H1 header(s)" -ForegroundColor Gray
                exit 1
            }
        }
        
        # Store context warnings (broken links) for display before success message
        Write-Verbose "Found $($context.Warnings.Count) broken link warning(s)"
        
        $allDocuments = @($context.ProcessedDocuments)
        Write-Verbose "├─ Discovered: $($allDocuments.Count) document(s)"
        
        # Interactive mode prompts (T148-T149)
        if ($Mode -eq 'Interactive') {
            Write-Verbose "Running interactive mode..."
            $context = Invoke-InteractiveMode -Context $context
        }
    }
    catch {
        Write-ConversionError `
            -FilePath $InputPath `
            -Message "Error discovering linked documents: $($_.Exception.Message)" `
            -Suggestion "Check file paths and permissions. Stack trace: $($_.ScriptStackTrace)" `
            -ExitCode $ExitCodes.UnknownError
    }
    
    # Parse Markdown (T029 / T152 - single or multi-document)
    Write-Verbose "Parsing Markdown structure..."
    
    if ($Mode -eq 'Merge' -and $allDocuments.Count -gt 1) {
        # Merge mode (T140-T143)
        Write-Verbose "Merging $($allDocuments.Count) documents..."
        
        $mergeResult = Invoke-MergeMode -Context $context -Parser ${function:Parse-MarkdownHeaders}
        $doc = $mergeResult.Context
        $mergedNodes = $mergeResult.Nodes
        
        Write-Verbose "├─ Merged: $($mergedNodes.Count) nodes from $($allDocuments.Count) documents"
    }
    elseif ($Mode -eq 'Separate' -and $allDocuments.Count -gt 1) {
        # Separate mode (T144-T145) - process each document independently
        Write-Verbose "Separate mode: processing $($allDocuments.Count) documents..."
        
        $separateOutputs = Invoke-SeparateMode -Context $context
        
        foreach ($output in $separateOutputs) {
            $docContent = Get-Content -Path $output.InputPath -Raw -Encoding UTF8
            Write-Verbose "├─ Processing: $($output.InputPath) ($($docContent.Length) chars)"
            $docParsed = Parse-MarkdownHeaders -Content $docContent -FilePath $output.InputPath
            Write-Verbose "├─ Parsed: $($docParsed.Nodes.Count) nodes"
            $docGuide = New-AmigaGuideDocument -MarkdownDocument $docParsed -OutputPath $output.OutputPath -Encoding $Encoding
            
            # T109: Write output with correct encoding (Latin1/ASCII for Amiga, UTF8 for modern systems)
            if ($Encoding -eq 'Latin1') {
                # Convert UTF-8 → Latin1 (ISO-8859-1) for Amiga 8-bit support (accents: àáâãäåæçèé...)
                $latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
                $bytes = $latin1.GetBytes($docGuide)
                [System.IO.File]::WriteAllBytes($output.OutputPath, $bytes)
            }
            elseif ($Encoding -eq 'ASCII') {
                # Strict ASCII 7-bit (0-127) - safest but loses accents
                $ascii = [System.Text.Encoding]::ASCII
                $bytes = $ascii.GetBytes($docGuide)
                [System.IO.File]::WriteAllBytes($output.OutputPath, $bytes)
            }
            else {
                Set-Content -Path $output.OutputPath -Value $docGuide -Encoding UTF8 -NoNewline
            }
            Write-Verbose "├─ Created: $($output.OutputPath)"
        }
        
        Write-Host "✓ Separate mode conversion completed" -ForegroundColor Green
        Write-Host "├─ Generated $($separateOutputs.Count) .guide files" -ForegroundColor Gray
        exit $ExitCodes.Success
    }
    elseif ($Mode -eq 'Optimized' -and $allDocuments.Count -gt 1) {
        # Optimized mode (T146-T147)
        Write-Verbose "Optimized mode: filtering reachable nodes..."
        
        $mergeResult = Invoke-MergeMode -Context $context -Parser ${function:Parse-MarkdownHeaders}
        $mergedNodes = $mergeResult.Nodes
        
        $filteredNodes = Invoke-OptimizedMode -Context $context -AllNodes $mergedNodes
        $mergedNodes = $filteredNodes
        
        Write-Verbose "├─ Optimized: $($mergedNodes.Count) reachable nodes"
    }
    else {
        # Single document or default
        $doc = Parse-MarkdownHeaders -Content $content -FilePath $InputPath
        $mergedNodes = $doc.Nodes
    }
    
    Write-Verbose "├─ Parsed: $($content.Length) characters, $($mergedNodes.Count) nodes"
    
    # Continue with original single-document flow or use merged nodes
    if (-not $doc) {
        # Create a synthetic document for merged nodes
        $doc = [PSCustomObject]@{
            FilePath = $InputPath
            Content = $content
            Nodes = $mergedNodes
            Metadata = @{}
        }
    }
    
    # Parse Markdown (T029)
    Write-Verbose "Parsing Markdown structure..."
    $parseTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $doc = Parse-MarkdownHeaders -Content $content -FilePath $InputPath
    $parseTimer.Stop()
    $perfTimings['Parsing'] = $parseTimer.Elapsed
    Write-Verbose "├─ Parsed: $($doc.Content.Length) characters, $($doc.Nodes.Count) nodes"
    
    # Generate AmigaGuide (T030)
    Write-Verbose "Generating AmigaGuide output..."
    $generateTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $guideContent = New-AmigaGuideDocument -MarkdownDocument $doc -OutputPath $OutputPath -Encoding $Encoding
    $generateTimer.Stop()
    $perfTimings['Generation'] = $generateTimer.Elapsed
    
    # Validate output (T031)
    Write-Verbose "Validating AmigaGuide output..."
    $outputValidation = Test-AmigaGuideOutput -Content $guideContent
    
    if (-not $outputValidation.IsValid) {
        Write-Host "✗ Generated invalid AmigaGuide output:" -ForegroundColor Red
        foreach ($err in $outputValidation.Errors) {
            Write-Host "  ERROR: $($err.Message)" -ForegroundColor Red
            if ($err.Context) {
                Write-Host "    Context: $($err.Context)" -ForegroundColor Gray
            }
            if ($err.Suggestion) {
                Write-Host "    Suggestion: $($err.Suggestion)" -ForegroundColor Cyan
            }
        }
        exit $ExitCodes.InvalidSyntax
    }
    
    # Count lines in output
    $outputLines = ($guideContent -split "`n").Count
    
    # Write output file (T030 + T109: Latin1/ASCII encoding support)
    Write-Verbose "Writing output file with $Encoding encoding..."
    $writeTimer = [System.Diagnostics.Stopwatch]::StartNew()
    
    if ($Encoding -eq 'Latin1') {
        # T109: Convert UTF-8 → Latin1 (ISO-8859-1) for Amiga 8-bit support
        # Supports accents: àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ (128-255)
        $latin1 = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
        $bytes = $latin1.GetBytes($guideContent)
        [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
        Write-Verbose "├─ Written with Latin1 (ISO-8859-1) encoding"
    }
    elseif ($Encoding -eq 'ASCII') {
        # Strict ASCII 7-bit (0-127) - safest, as per AmigaGuide spec ("plain ASCII text")
        # Loses accents: café → caf?, naïve → na?ve
        $ascii = [System.Text.Encoding]::ASCII
        $bytes = $ascii.GetBytes($guideContent)
        [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
        Write-Verbose "├─ Written with ASCII (7-bit strict) encoding"
    }
    else {
        # UTF-8 for modern systems
        Set-Content -Path $OutputPath -Value $guideContent -Encoding UTF8 -NoNewline
        Write-Verbose "├─ Written with UTF-8 encoding"
    }
    
    $writeTimer.Stop()
    $perfTimings['FileWrite'] = $writeTimer.Elapsed
    $totalTimer.Stop()
    $perfTimings['Total'] = $totalTimer.Elapsed
    
    # Show success message FIRST
    Write-Host "✓ Conversion completed successfully" -ForegroundColor Green
    Write-Host "├─ Input: $InputPath" -ForegroundColor Gray
    Write-Host "├─ Output: $OutputPath" -ForegroundColor Gray
    Write-Host "├─ Nodes: $($doc.Nodes.Count)" -ForegroundColor Gray
    Write-Host "└─ Lines: $outputLines" -ForegroundColor Gray
    
    # T166: Performance report (only in Verbose mode)
    if ($VerbosePreference -eq 'Continue') {
        Write-Host ""
        Write-Host "Performance Metrics:" -ForegroundColor Cyan
        Write-Host "├─ File Read:    $($perfTimings['FileRead'].TotalMilliseconds.ToString('F2')) ms" -ForegroundColor Gray
        Write-Host "├─ Validation:   $($perfTimings['Validation'].TotalMilliseconds.ToString('F2')) ms" -ForegroundColor Gray
        Write-Host "├─ Parsing:      $($perfTimings['Parsing'].TotalMilliseconds.ToString('F2')) ms" -ForegroundColor Gray
        Write-Host "├─ Generation:   $($perfTimings['Generation'].TotalMilliseconds.ToString('F2')) ms" -ForegroundColor Gray
        Write-Host "├─ File Write:   $($perfTimings['FileWrite'].TotalMilliseconds.ToString('F2')) ms" -ForegroundColor Gray
        Write-Host "└─ Total:        $($perfTimings['Total'].TotalMilliseconds.ToString('F2')) ms ($($perfTimings['Total'].TotalSeconds.ToString('F3')) s)" -ForegroundColor Green
    }
    
    # Warning summary AFTER success message
    $contextWarnings = if ($context -and $context.Warnings) { $context.Warnings.Count } else { 0 }
    $importantWarnings = $inputWarnings | Where-Object { $_.Message -match "Non-ASCII|Broken link" }
    $nonAsciiCount = ($importantWarnings | Where-Object { $_.Message -match "Non-ASCII" }).Count
    $brokenLinkCount = $contextWarnings
    $technicalWarnings = $outputValidation.Warnings.Count
    $totalWarnings = $nonAsciiCount + $brokenLinkCount + $technicalWarnings
    
    if ($totalWarnings -gt 0) {
        Write-Host ""
        
        if ($VerbosePreference -eq 'Continue') {
            # Verbose mode: show all details
            if ($nonAsciiCount -gt 0 -or $brokenLinkCount -gt 0) {
                Write-Host "Important warnings:" -ForegroundColor Yellow
                foreach ($warning in $importantWarnings) {
                    Write-ValidationWarning -Warning $warning
                }
                if ($context -and $context.Warnings.Count -gt 0) {
                    foreach ($warning in $context.Warnings) {
                        Write-Host "WARNING: $warning" -ForegroundColor Yellow
                    }
                }
            }
            if ($technicalWarnings -gt 0) {
                Write-Host ""
                Write-Host "Technical warnings (output formatting):" -ForegroundColor Yellow
                foreach ($warning in $outputValidation.Warnings) {
                    Write-ValidationWarning -Warning $warning
                }
            }
        }
        else {
            # Normal mode: simple summary with clear breakdown
            if ($nonAsciiCount -gt 0) {
                Write-Host "⚠ $nonAsciiCount Non-ASCII character(s) detected (emojis, accents)" -ForegroundColor Yellow
            }
            if ($brokenLinkCount -gt 0) {
                Write-Host "⚠ $brokenLinkCount Broken link(s) detected (files will be created as external links)" -ForegroundColor Yellow
            }
            if ($technicalWarnings -gt 0) {
                Write-Host "⚠ $technicalWarnings Technical warning(s) (output formatting)" -ForegroundColor Yellow
            }
            
            Write-Host ""
            Write-Host "Run with -Verbose flag to see warning details" -ForegroundColor Gray
        }
    }
}
catch {
    Write-ConversionError `
        -FilePath $InputPath `
        -Message "Conversion failed: $($_.Exception.Message)" `
        -Suggestion "Check input file format and encoding. Stack trace: $($_.ScriptStackTrace)" `
        -ExitCode $ExitCodes.UnknownError
}

#endregion

exit $ExitCodes.Success

#endregion
