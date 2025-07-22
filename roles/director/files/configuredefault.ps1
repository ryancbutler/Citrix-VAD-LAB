#From https://dennisspan.com/citrix-director-unattended-installation/#CompleteScriptConfigDirector
#Configures default page\redirection

$IISRootDir = "$env:SystemDrive\inetpub\wwwroot"
$DirectorRedirectFileName = "Director.html"
$IISSiteName = "Default Web Site"

# The following PowerShell "here-string" contains the text to be added to the redirection file
$Text = @"
<script type="text/javascript">
<!--
window.location="http://$env:computername.$env:userdnsdomain/Director";
// -->
</script>
"@
  
# Create the redirection file in the IIS root directory of Director
$DirectorRedirectFile = Join-Path $IISRootDir $DirectorRedirectFileName

try {
    Set-Content $DirectorRedirectFile -value ("$Text") -Encoding Default
} catch {
    write-output "An error occurred trying to write the redirection file '$DirectorRedirectFile' (error: $($Error[0]))"
}
 
try {
    if ( Get-WebConfigurationProperty -Filter "//defaultDocument" -PSPath "IIS:\sites\$IISSiteName" -Name files.collection | Where-Object { $_.value -eq $DirectorRedirectFileName } ) { 
        try {
            Remove-WebConfigurationProperty -Filter "//defaultDocument" -PSPath "IIS:\sites\$IISSiteName" -Name files -atElement @{value=$DirectorRedirectFileName} -ErrorAction Stop
        } catch {
            write-output "An error occurred trying to remove the file '$DirectorRedirectFileName' from the default documents (error: $($Error[0]))"
        }
    } else {
        write-output "The file '$DirectorRedirectFileName' is not listed in the default documents"
    }
} catch {
    write-output "An error occurred trying to check and remove the file '$DirectorRedirectFileName' from the default documents (error: $($Error[0]))"
    Exit 1
}
 
# Add the redirection file to the top of the list of default documents in IIS (first remove the entry from the default documents if it exists)
try {
    Add-WebConfiguration -Filter "//defaultDocument/files" -PSPath "IIS:\sites\$IISSiteName" -AtIndex 0 -Value @{value=$DirectorRedirectFileName}
} catch {
    write-output "An error occurred trying add the file '$DirectorRedirectFileName' to the top of the default documents (error: $($Error[0]))"
}
"completed" >> "C:\Logs\directordefault.txt"
