$outputObj = @{
    "HostbaseUrl" = $env:HostbaseUrl
    "FarmServers" = $env:FarmServers
    "StoreVirtualPath" = $env:StoreVirtualPath
    "TransportType" = $env:TransportType
    "GatewayUrl" = $env:GatewayUrl
    "GatewaySTAUrls"= $env:GatewaySTAUrls
    "GatewayName" = $env:GatewayName
}
    
$outputObj|Export-Clixml "C:\Logs\sf-vars.xml" -Force