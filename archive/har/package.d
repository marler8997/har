/**
HAR - Human Archive Format

https://github.com/marler8997/har

HAR is a simple format to represent multiple files in a single block of text, i.e.
---
--- main.d
import foo;
void main()
{
    foofunc();
}
--- foo.d
module foo;
void foofunc()
{
}
---
*/
module archive.har;

public import archive.har.extract;
