#From https://dennisspan.com/citrix-director-unattended-installation/#CompleteScriptConfigDirector
#Configures pre-populated domain

$IISRootDir = "$env:SystemDrive\inetpub\wwwroot"
$LogonASPXFile = Join-Path $IISRootDir "Director\logon.aspx"
$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain
 
$OldText = "TextBox ID=""Domain"" runat=""server"""
$NewText = "TextBox ID=""Domain"" runat=""server"" Text=""$DomainName"" readonly=""true"""
 
# Read each line of the file and pre-populate the domain name
$Content = Get-Content $LogonASPXFile

if ( ([string]$Content).Contains($NewText) ) { 
    write-out "Skipping"
} else {
    Foreach ( $Line in $Content ) {
        $Line = ( $Line -replace $OldText, $NewText) + "`r`n"
        $ContentNew = $ContentNew + $Line
    }

    Set-Content $LogonASPXFile -value $ContentNew -Encoding UTF8
    "completed" >> "C:\Logs\directordomain.txt"

}