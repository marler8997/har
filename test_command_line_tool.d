import std.path;
import std.file;
import std.stdio;

import std.format : format;
import std.process : spawnShell, wait;

class SilentException : Exception
{
    this()
    {
        super(null);
    }
}

auto quit()
{
    return new SilentException();
}

int main(string[] args)
{
    try
    {
        return tryMain(args);
    }
    catch (SilentException)
    {
        return 1;
    }
}

int tryMain(string[] args)
{
    // TODO: move to std.path
    version (Windows)
        string exeExtention = ".exe";
    else
        string exeExtention;

    auto rootDir = __FILE_FULL_PATH__.dirName;
    auto outDir = rootDir.buildPath("out");
    auto harExe = outDir.buildPath("har" ~ exeExtention);

    auto testDir = rootDir.buildPath("test"); // workaround https://issues.dlang.org/show_bug.cgi?id=6138 : we need absolutePath
    auto outTestDir = outDir.buildPath("test");
    mkdirRecurse(outTestDir);
    foreach (entry; dirEntries(testDir, "*.har", SpanMode.shallow))
    {
        auto file = entry.name;
        auto name = file.baseName.setExtension(".expected");
        run(format("%s %s --dir=%s", harExe, file, outTestDir.buildPath(name)));
        auto expected = file.setExtension(".expected");
        auto actual = outTestDir.buildPath(name);
        run(format("diff --brief -r %s %s", expected, actual));
    }
    return 0;
}

void run(string command)
{
    writefln("[SHELL] %s", command);
    auto pid = spawnShell(command);
    auto exitCode = wait(pid);
    writeln("--------------------------------------------------------------------------------");
    if (exitCode != 0)
    {
        writefln("last command exited with code %s", exitCode);
        throw quit;
    }
}
