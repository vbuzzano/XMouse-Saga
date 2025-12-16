# AmigaGuide reference

AmigaGuide is a mark-up language for hypertext documents, introduced by [Commodore International](https://en.wikipedia.org/wiki/Commodore_International) in 1992 as part of Workbench 2.1 and later extended in Workbench 3.0 and 3.1.

## On this page

1. [Comparing AmigaGuide and HTML](https://iamkate.com/code/amigaguide-reference/#html)
2. [Version history](https://iamkate.com/code/amigaguide-reference/#history)
3. [The structure of an AmigaGuide document](https://iamkate.com/code/amigaguide-reference/#structure)
4. [Whitespace handling](https://iamkate.com/code/amigaguide-reference/#whitespace)
5. [Global commands](https://iamkate.com/code/amigaguide-reference/#global)
6. [Node commands](https://iamkate.com/code/amigaguide-reference/#node)
7. [Text commands](https://iamkate.com/code/amigaguide-reference/#text)

## Comparing AmigaGuide and HTML

AmigaGuide and HTML were both developed in the early 1990s, but have different goals and take different approaches to representing hypertext.

### Linking

HTML was designed to be used on the internet. Each HTML document is located at a specific URL and usually represents a single page. An HTML hyperlink points to a URL, which may end with a fragment identifier (a string starting with `#`) to target a named location within the target document; a link URL consisting only of a fragment identifier targets a location within the current document. Related documents can be specified using the `rel` attribute of links, but this information is usually not exposed in browsers.

AmigaGuide was designed to be used on the local filesystem. Each AmigaGuide file consists of one or more nodes, which represent the pages within the file. An AmigaGuide hyperlink points to a file, and may specify a node and line number within the target file if it is an AmigaGuide document; the file name may be omitted to link to a node within the current file. Nodes can specify previous, next, content, index, and help nodes, and these can be accessed through a toolbar displayed at the top of the viewing application.

### Mark-up

HTML documents are marked up using tags consisting of an element name contained within angle brackets (`<` and `>`), with closing tags having `/` before the element name. Attributes for an element may be specified within the opening tag. The document represents a tree structure, so tags must be correctly nested: `<b><i>text</i></b>` represents text within an `i` element within a `b` element, whereas `<b>text</i>` is not valid HTML. Consecutive whitespace characters within an HTML document are usually collapsed to a single space, but finer control of whitespace handling is possible.

AmigaGuide documents are marked up using commands consisting of a command name preceded by `@`. Some commands occur on their own line, and may have options specified after the command name. Other commands occur within text, have the command name contained within braces (`{` and `}`), and may have options specified within the braces. Formatting commands exist in pairs to turn on and off formatting, but do not need to be correctly nested: `@{b}text@{ui}` is valid, with the `@{ui}` command having no effect if italic text is not currently turned on. Whitespace within nodes is preserved by default, but later versions of AmigaGuide introduced commands to change this behaviour.

### Scripting

HTML documents can use JavaScript to add interactive functionality. JavaScript is executed in a sandbox: it can modify the current document but is isolated from other documents and the rest of the operating system.

AmigaGuide documents can contain commands to execute AmigaDOS commands and ARexx scripts. AmigaDOS commands and ARexx scripts have full access to the operating system and may carry out malicious actions.

## Version history

The AmigaGuide format and a viewing application with the same name were introduced as part of Workbench 2.1. The AmigaGuide application could only display AmigaGuide files and plain text files, so hyperlinks were limited to documents in these formats. The major structural commands were present in this original release, but formatting commands were limited to changing the font and selecting from a limited range of foreground and background colours.

Workbench 3.0 introduced the datatypes system and the associated viewing application Multiview, which can display any file for which a datatype has been installed. The standard datatypes include AmigaGuide and various image formats, giving AmigaGuide documents the ability to link to other file types. The AmigaGuide datatype introduced several new commands, including formatting commands for bold, italic, and underlined text.

Workbench 3.1 introduced further new AmigaGuide commands, including event handlers allowing ARexx scripts to be executed when nodes are opened or closed, and commands for more advanced handling of whitespace.

## The structure of an AmigaGuide document

An AmigaGuide document is a text file marked up using commands consisting of a command name preceded by `@`. To include a literal `@` it must be escaped with a backslash (`\@`), and as a result a literal `\` must also be escaped (`\\`). There are three types of command:

[Global commands](https://iamkate.com/code/amigaguide-reference/#global)

Global commands occur outside of any node, and are used to define nodes and specify global metadata and formatting

[Node commands](https://iamkate.com/code/amigaguide-reference/#node)

Node commands occur inside a node, and are used to specify node metadata and formatting

[Text commands](https://iamkate.com/code/amigaguide-reference/#text)

Text commands occur within text, and are used to specify text formatting and to create hyperlinks and buttons

Global and node commands appear on their own line, and may have options specified after the command name. Text commands have the command name contained within braces (`{` and `}`), and may have options specified within the braces. Options containing spaces must be written in quotation marks (`"`), except for global and node commands that have only one option.

Every AmigaGuide document starts with the global `database` command, which must occur on the first line and allows MultiView to identify the file as an AmigaGuide document:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@database<br>```|

### Nodes

Nodes are defined using the `node` command, which has two options specifying a node name (used to link to the node) and node title (shown in the window title bar). All text and commands until the following `endnode` command are part of the node. For example:

|   |   |
|---|---|
|```<br>1<br>2<br>3<br>4<br>5<br>6<br>7<br>```|```<br>@node node1 "First node"<br>This text is in the first node<br>@endnode<br><br>@node node2 "Second node"<br>This text is in the second node<br>@endnode<br>```|

When the file is loaded, the first node in the document is displayed. The example above does not include navigation between the nodes, but we can do this using the `next` and `prev` commands, which take a node name as an option:

|   |   |
|---|---|
|```<br>1<br>2<br>3<br>4<br>5<br>6<br>7<br>8<br>9<br>```|```<br>@node node1 "First node"<br>@next node2<br>This text is in the first node<br>@endnode<br><br>@node node2 "Second node"<br>@prev node1<br>This text is in the second node<br>@endnode<br>```|

### Formatting text

We can format text using text commands such as `b` and `i` to turn on bold and italic, and `ub` and `ui` to turn them off:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{b}Bold, @{i}bold and italic,@{ub} italic,@{ui} and unformatted<br>```|

Hypertext links are created using the text `link` command. The link label, which appears as a button, is an option before the command name, while the link target and optionally a line number are options after the command name:

|   |   |
|---|---|
|```<br>1<br>2<br>3<br>4<br>```|```<br>A link to @{"another node" link "node name"}<br>A link to @{"a specific line in another node" link "node name" 10}<br>A link to @{"a node in another file" link "Documents:AmigaGuide/another.guide/node name"}<br>A link to @{"a different file type, using a dummy node name" link "image.iff/main"}<br>```|

When creating a vertical list of links, different button widths can look messy. Some authors add spaces around the link label to ensure the buttons are all the same width. Other authors use two spaces as a link label, creating a column of identical square buttons, and then describe each link in the text following its button.

## Whitespace handling

By default AmigaGuide viewers display whitespace exactly as it appears within the source text. If lines are too long to fit in the window, a horizontal scroll bar is displayed. Authors usually break lines so that a horizontal scroll bar is not needed when the document is viewed using the default Topaz font on a 640-pixel-wide screen.

Workbench 3.0 introduced the `wordwrap` command, as both a global command (applying to all nodes) and a node command. When the `wordwrap` command is used, lines will automatically wrap to prevent a horizontal scroll bar being displayed. Line breaks in the source text are preserved, so paragraphs must be written as a single line to prevent unwanted line breaks. This causes problems for viewers on old versions of Workbench, as paragraphs will then have no line breaks at all.

Workbench 3.1 introduced the `smartwrap` command, as both a global command (applying to all nodes) and a node command. When the `smartwrap` command is used, lines will automatically wrap to prevent a horizontal scroll bar being displayed. Single line breaks in the source text are ignored, while double line breaks or the text command `par` are used to create manual line breaks. The `smartwrap` command can be used without causing problems for viewers on old versions of Workbench by including line breaks in the source text as if `smartwrap` is unavailable, and using two line breaks instead of the `par` command to create a new paragraph.

## Global commands

### $VER: [information]

Specifies version information accessed through the AmigaDOS `version` command:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@$VER: example.guide 1.0 (2021-12-30)<br>```|

### (c) [information]

[Unused] Specifies copyright information:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@(c) 2021 Kate Morley<br>```|

### amigaguide

[3.1] Displays `Amigaguide(R)` in bold text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@amigaguide<br>```|

### author [name]

[Unused] Specifies the name of the author:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@author Kate Morley<br>```|

### database

Identifies the file as an AmigaGuide document:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@database<br>```|

### endnode

Marks the end of a node definition:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@endnode<br>```|

### font [name] [size]

Specifies the font to use:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@font Example.font 12<br>```|

### height [rows]

[Unused] Specifies the number of rows in the tallest node:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@height 100<br>```|

### help [node]

Specifies the node to show when the Help button is clicked:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@help "help node"<br>```|

If this command is not used, the Help button provides general help about browsing AmigaGuide documents.

### index [node]

Specifies the node to show when the Index button is clicked:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@index "index node"<br>```|

### macro [definition]

[3.1] Defines a macro. The definition consists of a macro name followed by a substitution, which may include substitutions using `$1`, `$2`, and so on. The macro is then used like a text command:

|   |   |
|---|---|
|```<br> 1<br> 2<br> 3<br> 4<br> 5<br> 6<br> 7<br> 8<br> 9<br>10<br>11<br>12<br>```|```<br>@rem Define the macro:<br>@macro mylink @{"  " link $2} $1<br><br>@node node "A node"<br><br>@rem Use the macro:<br>@{mylink "Another node" "node2"}<br><br>@rem This is equivalent to:<br>@{"  " link "node2"} Another node<br><br>@endnode<br>```|

### master [path]

[Unused] Specifies the master document on which this document is based:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@master Documents:AmigaGuide/master.guide<br>```|

### node [name] [title]

Marks the start of a node definition:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@node "node name" "Node title"<br>```|

The name is used to link to the node. The title is shown in the window title bar.

### onclose [path]

[3.1] Specifies an ARexx script to execute when the document is closed:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@onclose script.rexx<br>```|

### onopen [path]

[3.1] Specifies an ARexx script to execute when the document is opened:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@onopen script.rexx<br>```|

### rem [comment]  
remark [comment]

Specifies a comment that is not displayed to viewers:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@rem Do not delete this node; it is referenced by other guides<br>```|

### smartwrap

[3.1] Turns on [smartwrap](https://iamkate.com/code/amigaguide-reference/#whitespace):

|   |   |
|---|---|
|```<br>1<br>```|```<br>@smartwrap<br>```|

### tab [spaces]

[3.1] Specifies the number of spaces generated by the `tab` command:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@tab 2<br>```|

### width [columns]

[Unused] Specifies the number of columns in the widest node:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@width 100<br>```|

### wordwrap

[3.0] Turns on [wordwrap](https://iamkate.com/code/amigaguide-reference/#whitespace):

|   |   |
|---|---|
|```<br>1<br>```|```<br>@wordwrap<br>```|

### xref [path]

[3.0, Unused] Specifies another document to refer to:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@xref Documents:AmigaGuide/another.guide<br>```|

## Node commands

### embed [path]

[3.0] Specifies a text file to be included at the location of the command:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@embed Documents:Text/text.txt<br>```|

### font [name] [size]

A node-specific version of the global `font` command.

### help [node]

A node-specific version of the global `help` command.

### index [node]

A node-specific version of the global `index` command.

### keywords [keywords]

[Unused] Specifies keywords for the node:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@keywords AmigaGuide hypertext hyperlink<br>```|

### macro [definition]

[3.1] A node-specific version of the global `macro` command.

### next [node]

Specifies the node to show when the Browse > button is clicked:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@next "next node"<br>```|

If this command is not used, the Browse > button leads to the next node defined in the document.

### onclose [path]

[3.1] A node-specific version of the global `onclose` command; the script is executed when the node is closed.

### onopen [path]

[3.1] A node-specific version of the global `onopen` command; the script is executed when the node is opened.

### prev [node]

Specifies the node to show when the < Browse button is clicked:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@prev "previous node"<br>```|

If this command is not used, the < Browse button leads to the previous node defined in the document.

### proportional

[3.0] Specifies that a proportional font should be used for this node:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@proportional<br>```|

### smartwrap

[3.1] A node-specific version of the global `smartwrap` command.

### tab [spaces]

[3.1] A node-specific version of the global `tab` command.

### title [title]

Specifies the node title, overriding the title specified with the `node` command:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@title "Node title"<br>```|

### toc [node]

Specifies the node to show when the Contents button is clicked:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@toc "contents node"<br>```|

### wordwrap

[3.0] A node-specific version of the global `wordwrap` command.

## Text commands

### [label] alink [path] [line?]

A version of the `link` command that opens a new window. From Workbench 3.0 onwards, the link does not open in a new window and this command behaves identically to the `link` command.

### apen [pen]

[3.1] Specifies the foreground colour pen number to use from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{apen 1}<br>```|

### b

[3.0] Turns on bold text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{b}This text is bold@{ub}<br>```|

### [label] beep

[3.0] Creates a button that, when clicked, issues a system beep (usually consisting of a beep sound and a flash of the screen):

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Make a beep" beep}<br>```|

### bg [colour]

Specifies the background colour to use from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{bg background}<br>```|

Possible colours are `back`, `background`, `fill`, `filltext`, `highlight`, `shadow`, `shine`, and `text`.

### body

[3.1] Restores default formatting from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{body}<br>```|

### bpen [pen]

[3.1] Specifies the background colour pen number to use from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{bpen 1}<br>```|

### cleartabs

[3.1] Restores default tab stops from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{cleartabs}<br>```|

### [label] close

Creates a button that, when clicked, closes the window:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Close this window" close}<br>```|

This command is useful in documents opened through the `alink` command. From Workbench 3.0 onwards, the button has no effect.

### code

[3.1] Turns off [wrapping](https://iamkate.com/code/amigaguide-reference/#whitespace) other than when line breaks occur in the source text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{code}This text will not wrap onto multiple lines<br>```|

### fg [colour]

Specifies the foreground colour to use from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{fg text}<br>```|

Possible colours are `back`, `background`, `fill`, `filltext`, `highlight`, `shadow`, `shine`, and `text`.

### [label] guide [path] [line?]

[3.0] A version of the `link` command that may only link to an AmigaGuide document.

### i

[3.0] Turns on italic text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{i}This text is italic@{ui}<br>```|

### jcenter

[3.1] Turns on centred text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{jcenter}This text is centred<br>```|

### jleft

[3.1] Turns on left-aligned text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{jleft}This text is left-aligned<br>```|

### jright

[3.1] Turns on right-aligned text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{jright}This text is right-aligned<br>```|

### lindent [spaces]

[3.1] Specifies the indentation, in spaces, to apply from the next line onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{lindent 2}<br>```|

By default no indentation is applied.

### line

[3.1] Outputs a line break:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{line}<br>```|

This command is useful when [smartwrap](https://iamkate.com/code/amigaguide-reference/#whitespace) is used.

### [label] link [path] [line?]

Creates a hypertext link:

|   |   |
|---|---|
|```<br>1<br>2<br>3<br>4<br>```|```<br>A link to @{"another node" link "node name"}<br>A link to @{"a specific line in another node" link "node name" 10}<br>A link to @{"a node in another file" link "Documents:AmigaGuide/another.guide/node name"}<br>A link to @{"a different file type, using a dummy node name" link "image.iff/main"}<br>```|

### par

[3.1] Outputs two line breaks:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{par}<br>```|

This command is useful when [smartwrap](https://iamkate.com/code/amigaguide-reference/#whitespace) is used.

### pard

[3.1] Restores default paragraph formatting from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{pard}<br>```|

### pari [spaces]

[3.1] Specifies the indentation, in spaces, to apply to the first line of paragraphs from the next paragraph onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{pari 2}<br>```|

This value is added to any indentation specified with the `indent` command, and may be negative.

### plain

[3.1] Restores default text formatting from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{plain}<br>```|

### [label] rx [path]

Creates a button that, when clicked, executes an ARexx script:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Execute script" rx "script.rexx"}<br>```|

### [label] rxs [string]

Creates a button that, when clicked, executes an ARexx string:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Execute string" rxs "Say 'hello'"}<br>```|

### settabs [spaces+]

[3.1] Specifies the tab stops, in spaces, to apply from the next character onwards:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{settabs 2 4 6 8}<br>```|

### [label] system [path]

Creates a button that, when clicked, executes an AmigaDOS command:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Format floppy disk" system "Format DF0:"}<br>```|

### [label] quit

Creates a button that, when clicked, closes the window:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{"Close this window" quit}<br>```|

This command is useful in documents opened through the alink command. From Workbench 3.0 onwards, the button has no effect.

### tab

[3.1] Outputs a tab:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{tab}<br>```|

This command is affected by the tab and settabs commands. If neither is used, the tab is displayed as 8 spaces.

### u

[3.0] Turns on underlined text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{u}This text is underlined@{uu}<br>```|

### ub

[3.0] Turns off bold text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{b}Only this text is bold@{ub}<br>```|

### ui

[3.0] Turns off italic text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{i}Only this text is italic@{ui}<br>```|

### uu

[3.0] Turns off underlined text:

|   |   |
|---|---|
|```<br>1<br>```|```<br>@{u}Only this text is underlined@{uu}<br>```|