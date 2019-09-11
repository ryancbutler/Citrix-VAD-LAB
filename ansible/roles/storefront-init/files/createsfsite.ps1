<#
 .SYNOPSIS
   Deploy the first member of a remote access StoreFront group with a single XenDesktop farm with one of more servers.
   Wait for a joiner to join to the newly created server and publishes the configuration to it.

 .PARAMETER HostbaseUrl
   The the URL that is used as the root of the URLs for the stores and other StoreFront services hosted on a deployment.

 .PARAMETER SiteId
   The IIS Site that should be used for creating the new StoreFront deployment in.

 .PARAMETER Farmtype
   The type of farm that the resources are published from. Acceptable values are ("XenDesktop","XenApp","AppController","AppController").

 .PARAMETER FarmServers
   The farm servers that applications and/or desktops will be published from

 .PARAMETER StoreVirtualPath
   Optionally specify the IIS virtual path to be used for the Store service.
   Defaults to /Citrix/Store

 .PARAMETER LoadbalanceServers
   If more than one server is used for published resources then loadbalance requests rather than failover.

 .PARAMETER Port
   The port used to communicate with the Xml service on the DDC/Farm.

 .PARAMETER SSLRelayPort
   The port to use for ssl relay.

 .PARAMETER TransportType
   The transport type to use when communicating with the Xml service. Acceptable values are ("HTTP","HTTPS","SSL").

 .PARAMETER GatewayName
   The friendly name for identifying the gateway.

 .PARAMETER GatewayUrl
   The Gateway Url.

 .PARAMETER GatewayCallbackUrl
   The Gateway authentication NetScaler call-back Url.

 .PARAMETER GatewaySTAUrls
   Secure Ticket Authority server Urls. The Secure Ticket Authority (STA) is responsible for issuing session tickets in response to connection requests for published resources on XenApp. These session tickets form the basis of authentication and authorization for access to published resources.

 .PARAMETER GatewaySubnetIP
   IP address.

 .EXAMPLE
   .\MultiServerFirstGroupMember.ps1 -HostbaseUrl "http://storefront.example.com" -SiteId 1 -Farmtype XenApp -FarmServers "XDServer1","XDServer2" -StoreVirtualPath "/Citrix/Store" -LoadbalanceServers $true `
   -GatewayUrl https://mygateway.com -GatewayCallbackUrl https://mygateway.com/CitrixAuthService/AuthService.asmx -GatewaySTAUrls https://xdc01.com/scripts/ctxa.dll -GatewayName "NSG1"

   The example creates a new deployment using the host name of the local server. A single store will be created with resources from XDServer1 and XDServer2.
   The servers will be load balanced and remote access will be enabled via "mygateway.com". The server will start the server group joining process and wait for the second server.
#>

Param(
    #[Parameter(Mandatory=$false)][Uri]$HostbaseUrl=$env:HostbaseUrl,
    [Parameter(Mandatory=$false)][long]$SiteId = 1,
    [string]$Farmtype = "XenDesktop",
    #[Parameter(Mandatory=$false)][string[]]$FarmServers= @($env:FarmServer),
    #[string]$StoreVirtualPath = "/Citrix/Store",
    [bool]$LoadbalanceServers = $true,
    [int]$Port = 80,
    [int]$SSLRelayPort = 443,
    #[ValidateSet("HTTP","HTTPS","SSL")][string]$TransportType = $env:TransportType,
    #[Parameter(Mandatory=$false)][Uri]$GatewayUrl=$env:GatewayUrl,
    ##[Parameter(Mandatory=$false)][Uri]$GatewayCallbackUrl= "$env:HostbaseUrl/CitrixAuthService/AuthService.asmx",
    #[Parameter(Mandatory=$false)][string[]]$GatewaySTAUrls=@($env:GatewaySTAUrls),
    [string]$GatewaySubnetIP,
    [Parameter(Mandatory=$false)][string]$GatewayName=$env:GatewayName
)
Start-Transcript -Path "C:\Logs\transcript0.txt"

#Import ENV vars created
$importedsf = Import-Clixml "C:\Logs\sf-vars.xml"
$HostbaseUrl = $importedsf.HostbaseUrl
$FarmServers = $importedsf.FarmServers -split ","
$StoreVirtualPath = $importedsf.StoreVirtualPath
$TransportType = $importedsf.TransportType
$GatewayUrl = $importedsf.GatewayUrl
$GatewaySTAUrls = $importedsf.GatewaySTAUrls -split ","
$GatewayName = $importedsf.GatewayName

Set-StrictMode -Version 2.0

# Any failure is a terminating failure.
$ErrorActionPreference = 'Stop'
$ReportErrorShowStackTrace = $true
$ReportErrorShowInnerException = $true

# Import StoreFront modules. Required for versions of PowerShell earlier than 3.0 that do not support autoloading
Import-Module Citrix.StoreFront

# Create a remote access deployment using the RemoteAccessDeployment example
$scriptDirectory = "C:\Program Files\Citrix\Receiver StoreFront\PowerShellSDK\Examples"
$scriptPath = Join-Path $scriptDirectory "RemoteAccessDeployment.ps1"
& $scriptPath -HostbaseUrl $HostbaseUrl -SiteId $SiteId -FarmServers $FarmServers -StoreVirtualPath $StoreVirtualPath -Farmtype $Farmtype `
    -LoadbalanceServers $LoadbalanceServers -Port $Port  -SSLRelayPort $SSLRelayPort -TransportType $TransportType -GatewayUrl $GatewayUrl `
    -GatewaySTAUrls $GatewaySTAUrls -GatewayName $GatewayName -GatewayCallbackUrl ("$GatewayUrl/CitrixAuthService/AuthService.asmx")
write-output "Local store configuration complete"

write-output "Starting customizations"
$Rfw = Get-STFWebReceiverService -SiteId $SiteId -VirtualPath "/Citrix/StoreWeb"
write-output "Enabling loopback for SSL offload"
Set-STFWebReceiverCommunication -WebReceiverService $Rfw -Loopback "OnUsingHttp"
write-output "Workspace actions"
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlLogoffAction "None"
Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlAutoReconnectAtLogon $False
write-output "Sets default IIS page"
Set-STFWebReceiverService -WebReceiverService $Rfw -DefaultIISSite:$True

write-output "Trusted Domain"
$AuthService = Get-STFAuthenticationService -SiteId $SiteId -VirtualPath "/Citrix/StoreAuth"
Set-STFExplicitCommonOptions -AuthenticationService $AuthService -Domains (Get-WmiObject Win32_ComputerSystem).Domain -DefaultDomain (Get-WmiObject Win32_ComputerSystem).Domain -HideDomainField $true -AllowUserPasswordChange "Always"

write-output "Enable Session Reliability"
$gateway = Get-STFRoamingGateway -Name $GatewayName
Set-STFRoamingGateway -Gateway $gateway -SessionReliability $true

write-output "Checking cluster"
# Get the hostname to use from the server group (there should be only one cluter member - the local server)
$serverGroup = Get-STFServerGroup
if ($serverGroup.ClusterMembers.Count -gt 1)
{
	throw "This script is only intended to be run on the first member of a server group. The current server group already contains $($serverGroup.ClusterMembers.Count) members."
}
$localHostname = $serverGroup.ClusterMembers[0].Hostname

# Start the joining process and get the required passcode
$status = Start-STFServerGroupJoin -IsAuthorizingServer -Confirm:$false
$passcode = $status.Passcode
write-output "Passcode: $passcode"
#$passcode | Out-File -encoding UTF8 "C:\Windows\Temp\passcode.txt" -NoNewline
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::AppendAllLines("C:\Logs\passcode.txt",[string[]]$passcode,$Utf8NoBomEncoding)
write-output "Enter the passcode: $($passcode) and hostname $($localHostname) on the joining server when executing .\MultiServerJoinGroup.ps1"

# Wait for the joining server to join
write-output "Waiting for the joining server, cancel using CTRL+C"
$joinStatus = Wait-STFServerGroupJoin -Confirm:$false
if ($joinStatus -eq "Success")
{
	# End the joining process
	Stop-STFServerGroupJoin
	write-output "Server join complete. Publishing store configuration to the server group ..."
    
	# Join completed publish the configuration to the new server (Use -AsBackgroundJob to continue without waiting for completion)
	Publish-STFServerGroupConfiguration -Confirm:$false
	write-output "Configuration published successfully"
}
elseif (@("DeploymentError", "Failure", "PasscodeExpired", "PasscodeMismatch") -contains $joinStatus)
{
	# Report that the join failed
	Write-Error "Server join failed: $($joinStatus)"
}
else
{
	# Report that the join is still proceeding but this script will exit and not monitor progress  
	write-output "Server join ongoing ..."
}
Stop-Transcript