import std.typecons: tuple;
import std.array : appender;
import std.format : format;
import std.string : lineSplitter;
import std.stdio;
import archive.har;

void main()
{
    testError("", 1, "file is empty");
    testError(" ", 1, "first line does not start with a delimiter ending with a space");
    testError("a", 1, "first line does not start with a delimiter ending with a space");
    testError("a ", 1, "missing filename");
    testError("a  ", 1, "missing filename");
    testError("a  \r", 1, "missing filename");
    testError("a  \n", 1, "missing filename");
    testError("a /", 1, "absolute filenames are invalid");
    testError("a /a", 1, "absolute filenames are invalid");

    test("a a", ["a"]);
    test("a a\r", ["a"]);
    test("a a\r\n", ["a"]);
    test("a a\n", ["a"]);
    test("a a/", ["a/"]);
    testError("a a//", 1, "invalid filename, contains double slash '//'");
    testError("a a/..", 1, "invalid filename, contains double dot '..' parent directory");
    testError("a a/../", 1, "invalid filename, contains double dot '..' parent directory");
    test("a a \n", ["a"]);
    test("--- a/b", ["a/b"]);
    test("--- a/b/", ["a/b/"]);
    testError("--- a/b/\na", 2, "expected delimiter after empty directory");

    //
    // Quoted Filenames
    //
    testError("--- \"", 1, "filename missing end-quote");
    testError("--- \"\"", 1, "empty filename");
    testError("--- \"/", 1, "absolute filenames are invalid");
    test("--- \"a a\"", ["a a"]);

    //
    // Extra delimiters
    //
    test("--- a --------\n", ["a"]);
    test("a a a\n", ["a"]);
    test("a a aaaa\n", ["a"]);
    test("--- \"a a\" --------\n", ["a a"]);

    //
    // UTF8 Tests
    //
    foreach(s; [tuple("- ", ""), tuple("- \"", "\"")])
    {
        test     (s[0] ~ "\xc3\xb1"     ~ s[1], ["\xc3\xb1"]);
        testError(s[0] ~ "\xc3\x28"     ~ s[1], 1, "invalid utf8 sequence");
        testError(s[0] ~ "\xa0\xa1"     ~ s[1], 1, "invalid utf8 sequence");
        test     (s[0] ~ "\xe2\x82\xa1" ~ s[1], ["\xe2\x82\xa1"]);
        testError(s[0] ~ "\xa0\xa1"     ~ s[1], 1, "invalid utf8 sequence");
        testError(s[0] ~ "\xe2\x28\xa1" ~ s[1], 1, "invalid utf8 sequence");
        testError(s[0] ~ "\xe2\x82\x28" ~ s[1], 1, "invalid utf8 sequence");
        test     (s[0] ~ "\xf0\x90\x8c\xbc" ~ s[1], ["\xf0\x90\x8c\xbc"]);
    }

    // Test summaries
`--- base.d
This is some text.

And some more!

--- lib.d
Here's some more.

--- view/foo.txt
Hello, World!
`.testSummary([
    FileProperties("base.d", 2),
    FileProperties("lib.d", 7),
    FileProperties("view/foo.txt", 10),
]);
}

void testError(string text, size_t lineOfError, string error, size_t testLine = __LINE__)
{
    auto extractor = HarExtractor();
    extractor.filenameForErrors = format("%s_line_%s", __FILE__, testLine);
    extractor.dryRun = true;
    try
    {
        extractor.extract(text.lineSplitter, delegate(string fileFullName, FileProperties props) {
        });
        assert(0, extractor.filenameForErrors);
    }
    catch(HarException e)
    {
        writefln("got exception: %s", e.msg);
        assert(e.msg == error);
        assert(e.line == lineOfError);
    }
}

void testImpl(T)(string text, T[] expected, size_t testLine = __LINE__)
{
    auto extractor = HarExtractor();
    extractor.filenameForErrors = format("%s_line_%s", __FILE__, testLine);
    extractor.dryRun = true;
    auto extractedFiles = appender!(T[]);
    extractor.extract(text.lineSplitter, delegate(string fileFullName, FileProperties props)
    {
        static if (is(T == string))
        {
            extractedFiles.put(fileFullName);
        }
        else
        {
            extractedFiles.put(props);
        }

    });
    assert(expected == extractedFiles.data);
}

alias test = testImpl!string;
alias testSummary = testImpl!FileProperties;
