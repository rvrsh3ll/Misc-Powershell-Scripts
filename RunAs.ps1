
function Invoke-RunAs {
<#
.DESCRIPTION

Runas knockoff. Will bypass GPO path restrictions.

.PARAMETER UserName
Provide a user

.PARAMETER Password
Provide a password

.PARAMETER Domain
Provide optional domain

.Example
Invoke-RunAs -username administrator -password "P@$$word!" -domain CORPA
#>
    [CmdletBinding()]Param (
    [Parameter(
        ValueFromPipeline=$True,
        Mandatory=$True)]
        [String]$username,
    [Parameter(
        ValueFromPipeline=$True,
        Mandatory=$True)]
        [String]$password,
    [Parameter(
        ValueFromPipeline=$True,
        Mandatory=$False)]
        [String]$domain,
    [Parameter(
        ValueFromPipeline=$True,
        Mandatory=$False)]
        [String]$command,
     [Parameter(
        ValueFromPipeline=$True,
        Mandatory=$False)]
        [String]$arguments   
    )
    PROCESS {
    $sec_password = convertto-securestring $password -asplaintext -force
    $startinfo = new-object System.Diagnostics.ProcessStartInfo
    $startinfo.UserName = $username
    $startinfo.Password = $sec_password
    $startinfo.Domain = $domain
    $startinfo.FileName = $command
    $startinfo.Arguments = $arguments
    $startinfo.CreateNoWindow = $true
    $startinfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::hidden
    $startinfo.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($startinfo)
    }
}
