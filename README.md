# HAR - Human Archive Format

A human readable-writeable format for representing multiple files, named
after the popular `tar` format. The format is meant to be simple, intuitive,
and copy-pasteable allowing a single block of text (like a forum post) to
represent multiple files.

### Example:
```
--- hello.txt
Hello, this is a file currently archived in a HAR file.

--- other.txt
This is another file also archived within the same HAR file.

--- yetanother.txt
This is yet another file also archived within the same HAR file.

--- dir1/
--- dir2/
```

### Format
```
<delimiter> <single-space> <filename> (<one-or-more-spaces> <property>)* [<extra-delimiters>]
<contents>
<delimiter> <single-space> <filename> (<one-or-more-spaces> <property>)* [<extra-delimiters>]
<contents>
...
```

## What HAR doesn't do

* Does not support binary files (use tar for that, har is meant for humans)

# Details

## Directory Separators

For now, HAR only supports the foward slash `/` as a directory separator, regardless of platform.

Correct:
```
--- foo/bar.txt
```
Incorrect:
```
--- foo\bar.txt
```

## Filenames with Spaces

Use quotes if the filename contains whitespace:
```
--- "i like spaces/in my filenames"
```

## Properties

The format allows files to specify properties, i.e.
```
--- file1.txt owner=root
A file owed by root

--- file2.txt permissions=0772
A file with custom permissions

```
Properties may only be separated by 1 or more space characters (ascii 0x20).

## Empty Directories

Use a trailing slash in the filename to create an empty directory.
```
--- mydir/
--- anotherdir/ owner=root
--- dir3/ readonly
--- "dir with spaces/"
```

Note that this is only necessary for empty directories.  All the parent directories for a file do not need to be explicitly declared. i.e. if you have a HAR file like this:
```
--- foo/bar/baz.d
My cool file
```
you DO NOT need to include it's parent directories:
```
--- foo/
--- foo/bar/
```

## Obvious File Breaks

Extra deliimters can be used after a file to help distinguish where files begin/end, i.e.
```
--- myfile.txt -----------------------------------------
This is my file
...lots of text

--- anotherfile.txt -----------------------------------------
This is another file.  The extra '-' characters after the filename
should make it easier to spot the end/beginning of files.
```

The only requirement is that these extra characters start with the first character in the delimiter.  For example, the following file has an odd delimiter `#!ab$`, so as soon as a `#` character is found, the rest of the line is ignored, i.e.
```
#!ab$ myfile.txt #0a09fa00asdfj
```

## Custom Delimiters

The delimiter is used to mark the end of a file and the beginning of a new one.  The standard delimiter is `---`, however, any set of characters not containing a spaces or newlines can be used as a delimiter.  Also, since a HAR file always begins with a delimiter, there's no need to declare what your delimiter is, simply use it and the parser will pull it from the first line, i.e.

```
### showCustomBoundary.txt
This file uses a different type of delimiter.
### another.txt
Another file to show that the previous file boundary has worked correctly.
```

This being said, using the standard delimiter is encouraged to promote uniformity and familiarity with the format.

## Newlines

All standard newlines sequences are supported, `\n`, `\r\n` or `\r`.

## Which Newlines belong to the file?

When a delimiter is found marking the end of a file, the preceding newline is removed from the file.

> NOTE: the reason for this is so that files with and without "ending newlines" can be represented.

### Example:
```
--- empty_file.txt
--- no_newline_file.txt
this file has no newline
--- one_newline_file.txt
this file has one newline

--- two_newlines_file.txt
this file has two newlines


--- another_empty_file.txt
```

#### empty_file.txt
```
EOF
```
#### no_newline_file.txt
```
this file has no newlineEOF
```
#### one_newline_file.txt
```
this file has one newline\n
EOF
```
#### two_newlines_file.txt
```
this file has two newlines\n
\n
EOF
```

## Using ".."

HAR doesn't support using `..` to create files in parent directories.  This guarantees that if you extract a HAR file, it can only create files in the given output directory, it cannot extract files outside of that.

## Absolute filenames

Absolute filenames aren't supported, i.e.

```
--- /myfile.txt
This isn't valid
```

## Double slashes

Double slashes are considered an error, i.e.
```
--- foo//bar.txt
```
