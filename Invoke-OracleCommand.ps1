function Invoke-OracleCommand {
<#
.Synopsis
    Invoke a command on an oracle database. 
.Description
    This script connects to an a oracle database and runs a command.
.Parameter User
    The user ID
.Parameter Password
    The password
.Parameter Source
    Location/IP of Data source
.Parameter Source
    Command to run. SELECT user FROM dual

.Example

#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [string]$Path = "C:\Oracle\Oracle.ManagedDataAccess.dll",
        [Parameter(Mandatory = $True)]
        [string]$User,
        [Parameter(Mandatory = $True)]
        [string]$Password,
        [Parameter(Mandatory = $True)]
        [string]$Source,
        [Parameter(Mandatory = $True)]
        [string]$Command

    )


    Add-Type -Path "$Path"

    $con = New-Object Oracle.ManagedDataAccess.Client.OracleConnection("User Id=$User;Password=$Password;Data Source=$Source")

    $cmd=$con.CreateCommand()

    $cmd.CommandText="$Command"

    $con.Open()

    $rdr=$cmd.ExecuteReader()

    if ($rdr.Read()) {

        $rdr.GetString(0)

    }

$con.Close()

}
