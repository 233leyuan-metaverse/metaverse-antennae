// In-process stdio forwarding and child lifetime ownership. No extra server/runtime.
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

public static class AntennaeCursorHost
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32.dll")] static extern bool SetInformationJobObject(IntPtr job, int type, IntPtr info, uint length);
    [DllImport("kernel32.dll")] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
    [StructLayout(LayoutKind.Sequential)] struct BasicLimits {
        public long ProcessTime, JobTime; public uint Flags; public UIntPtr MinWorkingSet, MaxWorkingSet;
        public uint ActiveProcesses; public UIntPtr Affinity; public uint PriorityClass, SchedulingClass;
    }
    [StructLayout(LayoutKind.Sequential)] struct IoCounters { public ulong A, B, C, D, E, F; }
    [StructLayout(LayoutKind.Sequential)] struct ExtendedLimits {
        public BasicLimits Basic; public IoCounters Io; public UIntPtr ProcessMemory, JobMemory, PeakProcessMemory, PeakJobMemory;
    }
    static IntPtr Own(Process process) {
        var job = CreateJobObject(IntPtr.Zero, null);
        var limits = new ExtendedLimits(); limits.Basic.Flags = 0x2000; // KILL_ON_JOB_CLOSE
        int size = Marshal.SizeOf(limits); var ptr = Marshal.AllocHGlobal(size);
        try {
            Marshal.StructureToPtr(limits, ptr, false);
            if (job == IntPtr.Zero || !SetInformationJobObject(job, 9, ptr, (uint)size) || !AssignProcessToJobObject(job, process.Handle))
                throw new IOException("Cannot establish MCP child process ownership");
            return job;
        } catch { if (job != IntPtr.Zero) CloseHandle(job); if (!process.HasExited) process.Kill(); throw; }
        finally { Marshal.FreeHGlobal(ptr); }
    }
    static async Task Forward(Stream source, Stream destination) {
        var buffer = new byte[65536]; int count;
        while ((count = await source.ReadAsync(buffer, 0, buffer.Length).ConfigureAwait(false)) != 0) {
            await destination.WriteAsync(buffer, 0, count).ConfigureAwait(false);
            // Interactive MCP requests must reach the child before stdin closes.
            await destination.FlushAsync().ConfigureAwait(false);
        }
    }
    public static int Run(string exe, string cwd) {
        // .NET Framework's Process.StandardInput writer inherits Console input
        // encoding and can emit its BOM even when we use BaseStream. Keep both
        // console encodings BOM-free before creating the byte-protocol child.
        Console.InputEncoding = new System.Text.UTF8Encoding(false);
        Console.OutputEncoding = new System.Text.UTF8Encoding(false);
        using (var process = new Process()) {
            process.StartInfo = new ProcessStartInfo(exe) { WorkingDirectory = cwd, UseShellExecute = false,
                CreateNoWindow = true, RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true };
            process.Start(); var job = Own(process);
            try {
                var input = Forward(Console.OpenStandardInput(), process.StandardInput.BaseStream);
                input.ContinueWith(t => { try { process.StandardInput.Close(); } catch { } });
                var output = Forward(process.StandardOutput.BaseStream, Console.OpenStandardOutput());
                var error = Forward(process.StandardError.BaseStream, Console.OpenStandardError());
                process.WaitForExit(); Task.WaitAll(output, error); return process.ExitCode;
            } finally { CloseHandle(job); }
        }
    }
    static string Quote(string value) {
        var result = new System.Text.StringBuilder("\""); int slashes = 0;
        foreach (char c in value) {
            if (c == '\\') { slashes++; continue; }
            if (c == '"') { result.Append('\\', slashes * 2 + 1); result.Append(c); }
            else { result.Append('\\', slashes); result.Append(c); }
            slashes = 0;
        }
        result.Append('\\', slashes * 2); result.Append('"'); return result.ToString();
    }
    public static int Install(string node, string[] args, string cwd, string log) {
        using (var process = new Process()) {
            process.StartInfo = new ProcessStartInfo(node, string.Join(" ", Array.ConvertAll(args, Quote))) {
                WorkingDirectory = cwd, UseShellExecute = false, CreateNoWindow = true,
                RedirectStandardOutput = true, RedirectStandardError = true };
            foreach (string key in new System.Collections.Generic.List<string>(process.StartInfo.EnvironmentVariables.Keys.CastStrings())) {
                if (key.StartsWith("NPM_CONFIG_", StringComparison.OrdinalIgnoreCase) ||
                    Array.IndexOf(new [] { "NODE_OPTIONS", "NODE_AUTH_TOKEN", "NPM_TOKEN", "NPM_AUTH_TOKEN" }, key.ToUpperInvariant()) >= 0)
                    process.StartInfo.EnvironmentVariables.Remove(key);
            }
            process.Start(); var job = Own(process);
            try {
                var output = process.StandardOutput.ReadToEndAsync(); var error = process.StandardError.ReadToEndAsync();
                if (!process.WaitForExit(120000)) throw new IOException("npm extraction timed out");
                File.WriteAllText(log, output.Result + "\n" + error.Result); return process.ExitCode;
            } finally { CloseHandle(job); }
        }
    }
    static System.Collections.Generic.IEnumerable<string> CastStrings(this System.Collections.ICollection keys) {
        foreach (object key in keys) yield return (string)key;
    }
}
