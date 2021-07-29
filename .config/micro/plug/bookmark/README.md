# Bookmarks for micro

A plugin for the micro text editor. Bookmark lines to quickly jump between saved positions.

## Installation

```
# option 1: bash
$ micro -plugin install bookmark

# option 2: micro
> plugin install bookmark
```

## Usage

```
# mark/unmark current line (Ctrl-F2)
> toggleBookmark

# clear all bookmarks (CtrlShift-F2)
> clearBookmarks

# jump to next bookmark (F2)
> nextBookmark

# jump to previous bookmark (Shift-F2)
> prevBookmark
```

## Troubleshooting

If the default keyboard shortcuts do not work, it is most likely because it is already in use by another program.

Keyboard shortcuts can be changed in `~/.config/micro/bindings.json`.

```json
{
    "Ctrl-F2": "command:toggleBookmark",
    "CtrlShift-F2": "command:clearBookmarks",
    "F2": "command:nextBookmark",
    "Shift-F2": "command:prevBookmark"
}
```
