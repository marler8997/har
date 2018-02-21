import std.format : format;
import std.path : setExtension;
import std.file : dirEntries, SpanMode;
import std.stdio;
import std.process : spawnShell, wait;

class SilentException : Exception { this() { super(null); } }
auto quit() { return new SilentException(); }

int main(string[] args)
{
    try { return tryMain(args); }
    catch(SilentException) { return 1; }
}
int tryMain(string[] args)
{
    foreach (entry; dirEntries("test", "*.har", SpanMode.shallow))
    {
        run(format("./har %s", entry.name));
        auto expected = entry.name.setExtension(".expected");
        auto actual = entry.name.setExtension("");
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
