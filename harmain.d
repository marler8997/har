import std.typecons : Nullable, nullable;
import std.string : startsWith, endsWith;
import std.file : exists, isDir, mkdirRecurse;
import std.stdio;

import archive.har;

void help()
{
    writeln(
`Extracts and creates HAR archive files

Examples:
  har foo/archive.har       # Extracts files to foo/archive
  har foo bar > archive.har # Create archive from foo and bar

Options
  --dir=<dir>       Set output directory for extracted files
  --quiet           Quiet mode (do not list extracted files)
  --verbose         Verbose mode (print details)
  --dry-run         Dry run, process the HAR file but don't extract it
`);  
}

class SilentException : Exception { this() { super(null); } }
auto quit() { return new SilentException(); }

int main(string[] args)
{
    try { return tryMain(args); }
    catch (SilentException) { return 1; }
    catch (HarException e)
    {
        stderr.writefln("Error: %s(%s) %s", e.file, e.line, e.msg);
        return 1;
    }
}
int tryMain(string[] args)
{
    args = args[1 .. $];
    if (args.length == 0)
    {
        help();
        return 1;
    }

    string outputDirOption = null;
    bool quietMode = false;
    bool verbose = false;
    bool dryRun = false;

    {
        size_t newArgsLength = 0;
        scope(exit) args.length = newArgsLength;
        for (size_t i = 0; i < args.length; i++)
        {
            auto arg = args[i];
            if (!arg.startsWith("-"))
            {
                args[newArgsLength++] = arg;
            }
            else if (arg.startsWith("--dir="))
                outputDirOption = arg[6 .. $];
            else if (arg == "--quiet")
                quietMode = true;
            else if (arg == "--verbose")
                verbose = true;
            else if (arg == "--dry-run")
                dryRun = true;
            else
            {
                stderr.writefln("Error: unknown option '%s'", arg);
                return 1;
            }
        }
    }

    if (args.length == 0)
    {
        help();
        return 1;
    }

    size_t harFileCount = 0;
    foreach (file; args)
    {
        if (file.endsWith(".har"))
        {
            harFileCount++;
        }
        if (file.length == 0)
        {
            stderr.writefln("Error: filenames cannot be empty");
            return 1;
        }
    }
    if (harFileCount == 0)
        return archiveFiles(args);

    if (harFileCount < args.length)
    {
        stderr.writefln("Error: cannot create a har file with other har files");
        return 1;
    }

    void handleNewOutputDir(string outputDir)
    {
        if (exists(outputDir))
        {
            if (!isDir(outputDir))
            {
                stderr.writefln("Error: cannot extract files to non-directory %s", outputDir.formatDir);
                throw quit;
            }
            if (verbose)
                writefln("output directory %s already exists", outputDir.formatDir);
        }
        else
        {
            if (verbose)
                writefln("mkdir %s", outputDir.formatDir);
            if (!dryRun)
                mkdirRecurse(outputDir);
        }
    }

    if (outputDirOption)
    {
        handleNewOutputDir(outputDirOption);
    }

    foreach(harFilename; args)
    {
        auto extractor = HarExtractor();

        extractor.dryRun = dryRun;
        if (outputDirOption)
            extractor.outputDir = outputDirOption;
        else
        {
            extractor.outputDir = harFilename[0 .. $ - ".har".length];
            if (verbose)
                writefln("Using default output directory %s", extractor.outputDir.formatDir);
            handleNewOutputDir(extractor.outputDir);
        }

        if (verbose)
            extractor.enableVerbose(stdout);

        extractor.extractFromFile(harFilename, delegate(string fullFileName, FileProperties fileProps) {
            if (!quietMode)
            {
                writeln(fullFileName);
            }
        });
    }
    return 0;
}

int archiveFiles(string[] files)
{
    stderr.writeln("Error: creating har archives is not implemented");
    return 1;
}

