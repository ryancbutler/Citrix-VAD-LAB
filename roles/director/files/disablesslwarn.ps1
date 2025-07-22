#From https://dennisspan.com/citrix-director-unattended-installation/#CompleteScriptConfigDirector
#Disables SSL warning on login page
$IISRootDir = "$env:SystemDrive\inetpub\wwwroot"
$WebConfigFile = Join-Path $IISRootDir "Director\web.config" 
$xml = [xml](Get-Content $WebConfigFile)
$node = $xml.configuration.appSettings.add | where {$_.Key -eq 'UI.EnableSslCheck'}
$node.value = "false"   # Change an existing value
$xml.Save($WebConfigFile)
 
"completed" >> "C:\Logs\diablesslwarn.txt"