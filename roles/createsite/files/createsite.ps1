#==========================================================================
#
# Configure the Citrix XenDeskop Site
#
# AUTHOR: Dennis Span (https://dennisspan.com)
# DATE  : 05.04.2017
#
# COMMENT:
# This script has been prepared for Windows Server 2008 R2, 2012 R2 and 2016
# and Citrix XenDesktop 7.13 to 7.16
#
# This script creates the XenDesktop site and all its databases. It configures the site
# and it adds the first Delivery Controller to the site.
#
# Changes:
# 
# 23.05.2017: added join site routine. Improved create/join farm routine (read information directly
#             from the SQL site database). Updated function DS_WriteLog.
#
#==========================================================================

# Get the script parameters if there are any
param
(
    # The only parameter which is really required is 'Uninstall'
    # If no parameters are present or if the parameter is not
    # 'uninstall', an installation process is triggered
    [string]$Installationtype
)

# define Error handling
# note: do not change these values
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# FUNCTION DS_WriteLog
#==========================================================================
Function DS_WriteLog {
    <#
        .SYNOPSIS
        Write text to this script's log file
        .DESCRIPTION
        Write text to this script's log file
        .PARAMETER InformationType
        This parameter contains the information type prefix. Possible prefixes and information types are:
            I = Information
            S = Success
            W = Warning
            E = Error
            - = No status
        .PARAMETER Text
        This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
        .PARAMETER LogFile
        This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
        DS_WriteLog -InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing information to the log file
        .Example
        DS_WriteLog -InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing error information to the log file
        .Example
        DS_WriteLog -InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
        Writes an empty line to the log file
    #>
    [CmdletBinding()]
	Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$InformationType,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
    )

	$DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
	
    if ( $Text -eq "" ) {
        Add-Content $LogFile -value ("") # Write an empty line
    } Else {
        Add-Content $LogFile -value ($DateTime + " " + $InformationType + " - " + $Text)
        Write-Output ($DateTime + " " + $InformationType + " - " + $Text)
    }
}
#==========================================================================

################
# Main section #
################

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

# Custom variables [edit]
$BaseLogDir = "C:\Logs"                                         # [edit] add the location of your log directory here
$PackageName = "Citrix XenDesktop Site (configure)"             # [edit] enter the display name of the software (e.g. 'Arcobat Reader' or 'Microsoft Office')

# Global variables
$ComputerName = $env:ComputerName
$StartDir = $PSScriptRoot # the directory path of the script currently being executed
if (!($Installationtype -eq "Uninstall")) { $Installationtype = "Install" }
$LogDir = (Join-Path $BaseLogDir $PackageName).Replace(" ","_")
$LogFileName = "$($Installationtype)_$($PackageName).log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

DS_WriteLog "I" "START SCRIPT - $PackageName" $LogFile
DS_WriteLog "-" "" $LogFile

#################################################
# INSTALL CITRIX DELIVERY CONTROLLER            #
#################################################

DS_WriteLog "I" "Create and configure the XenDesktop site" $LogFile

DS_WriteLog "-" "" $LogFile

# Define the variables needed in this script:
DS_WriteLog "I" "Define the variables needed in this script:" $LogFile

# -----------------------------------
# CUSTOMIZE THE FOLLOWING VARIABLES TO YOUR REQUIREMENTS
# -----------------------------------
# $SiteName = "MyTestSite"                                                      # The name of your XenDesktop site. For example: "MySite".
# $DatabaseServer = ""SQLServer1.mycompany.com"                                           # The name of your SQL server or SQL server instance (e.g. "SQLServer1.mycompany.com" or "SQLCTX01.mycompany.com\InStance1").
# $DatabaseServerPort = "1433"                                              # The SQL port number (1433 by default)
# $DatabaseName_Site = "CTX_Site_DB"                                        # The name for the site database. For example: "CTX_Site_DB".
# $DatabaseName_Logging = "CTX_Logging_DB"                                  # The name for the logging database. For example: "CTX_Logging_DB".
# $DatabaseName_Monitoring = "CTX_Monitoring_DB"                            # The name for the monitoring database. For example: "CTX_Monitoring_DB".
# $LicenseServer = "mylic.mycompany.com"                                        # The name of your license server, for example: mylicserver.mycompany.com.
# $LicenseServerPort = 27000                                                # The port number for the initial contact, for example 27000 (this is the default value)
# $LicensingModel = "UserDevice"                                            # The licensing model. Possible values are UserDevice and Concurrent.
# $ProductCode = "XDT"                                                      # The product code. Possible values are XDT (for XenDesktop) or MPS (for the XenDesktop 7.x App Edition).
# $ProductEdition = "PLT"                                                   # The product edition. Possible values are STD (Standard), ENT (Enterprise) or PLT (Platinum). 
# $AdminGroup = "mydomain\domain admins"                                     # The name of the Active Directory user or group, for example "MyDomain\CTXAdmins".
# $Role ="Full Administrator"                                               # The role to assign to the new XenDesktop administrator. The following built-in roles are available:
# $Scope = "All"                                                            # The scope (the objects) to which the permissions (defined in the role) apply
# $GroomingDays = 365                                                       # The number of days you want to monitoring data to be saved in the database, for example 365 days.

$SiteName = $env:SiteName
$DatabaseServer = $env:DatabaseServer
$DatabaseServerPort = $env:DatabaseServerPort
$DatabaseName_Site = $env:DatabaseName_Site
$DatabaseName_Logging = $env:DatabaseName_Logging
$DatabaseName_Monitoring = $env:DatabaseName_Monitoring
$LicenseServer = $env:LicenseServer
$LicenseServerPort = $env:LicenseServerPort
$LicensingModel = $env:LicensingModel
$ProductCode = $env:ProductCode
$ProductEdition = $env:ProductEdition
$AdminGroup = $env:AdminGroup 
$Role = $env:Role
$Scope = $env:Scope
$GroomingDays = $env:GroomingDays
# -----------------------------------

# Log Variables
DS_WriteLog "I" "-Site name = $SiteName" $LogFile
DS_WriteLog "I" "-Database server (+ instance) = $DatabaseServer" $LogFile
DS_WriteLog "I" "-Database server port = $DatabaseServerPort" $LogFile
DS_WriteLog "I" "-Database name for site DB = $DatabaseName_Site" $LogFile
DS_WriteLog "I" "-Database name for logging DB = $DatabaseName_Logging" $LogFile
DS_WriteLog "I" "-Database name for monitoring DB = $DatabaseName_Monitoring" $LogFile
DS_WriteLog "I" "-License server = $DatabaseServer" $LogFile
DS_WriteLog "I" "-License server port = $LicenseServerPort" $LogFile
DS_WriteLog "I" "-Licensing model = $LicensingModel" $LogFile
DS_WriteLog "I" "-Product code = $ProductCode" $LogFile
DS_WriteLog "I" "-Product edition = $ProductEdition" $LogFile
DS_WriteLog "I" "-Administrator group name = $AdminGroup" $LogFile
DS_WriteLog "I" "-Administrator group role = $Role" $LogFile
DS_WriteLog "I" "-Administrator group scope = $Scope" $LogFile
DS_WriteLog "I" "-Grooming days = $GroomingDays" $LogFile

DS_WriteLog "-" "" $LogFile

# IMPORT MODULES AND SNAPINS
# --------------------------

# Import the XenDesktop Admin module
DS_WriteLog "I" "Import the XenDesktop Admin module" $LogFile
try {
    Import-Module Citrix.XenDesktop.Admin
    DS_WriteLog "S" "The XenDesktop Admin module was imported successfully" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to import the XenDesktop Admin module (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Load the Citrix snap-ins
DS_WriteLog "I" "Load the Citrix snap-ins" $LogFile
try {
    asnp citrix.*
    DS_WriteLog "S" "The Citrix snap-ins were loaded successfully" $LogFile
} catch {
    DS_WriteLog "E"  "An error occurred trying to load the Citrix snap-ins (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# CREATE DATABASES
# ----------------

# Create the site database (the classical try / catch statement does not work for some reason, so I had to use an "uglier" method for error handling)
DS_WriteLog "I" "Create the site database" $LogFile
try {
    New-XDDatabase -AdminAddress $ComputerName -SiteName $SiteName -DataStore Site -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Site -ErrorAction Stop | Out-Null
    DS_WriteLog "S" "The site database '$DatabaseName_Site' was created successfully" $LogFile
} catch {
    [string]$ErrorText = $Error[0]
    If ( $ErrorText.Contains("already exists")) {
        DS_WriteLog "I" "The site database '$DatabaseName_Site' already exists. Nothing to do." $LogFile
    } else {
        DS_WriteLog "E" "An error occurred trying to create the site database '$DatabaseName_Site' (error: $($Error[0]))" $LogFile
        Exit 1
    }
}

DS_WriteLog "-" "" $LogFile

# Create the logging database
DS_WriteLog "I" "Create the logging database" $LogFile
try {
    New-XDDatabase -AdminAddress $ComputerName -SiteName $SiteName -DataStore Logging -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Logging -ErrorAction Stop | Out-Null
    DS_WriteLog "S" "The logging database '$DatabaseName_Logging' was created successfully" $LogFile
} catch {
    [string]$ErrorText = $Error[0]
    If ( $ErrorText.Contains("already exists")) {
        DS_WriteLog "I" "The logging database '$DatabaseName_Logging' already exists. Nothing to do." $LogFile
    } else {
        DS_WriteLog "E" "An error occurred trying to create the logging database '$DatabaseName_Logging' (error: $($Error[0]))" $LogFile
        Exit 1
    }
}

DS_WriteLog "-" "" $LogFile

# Create the monitoring database
DS_WriteLog "I" "Create the monitoring database" $LogFile
try {
    New-XDDatabase -AdminAddress $ComputerName -SiteName $SiteName -DataStore Monitor -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Monitoring -ErrorAction Stop | Out-Null
    DS_WriteLog "S" "The monitoring database '$DatabaseName_Monitoring' was created successfully" $LogFile
} catch {
    [string]$ErrorText = $Error[0]
    If ( $ErrorText.Contains("already exists")) {
        DS_WriteLog "I" "The monitoring database '$DatabaseName_Monitoring' already exists. Nothing to do." $LogFile
    } else {
        DS_WriteLog "E" "An error occurred trying to create the monitoring database '$DatabaseName_Monitoring' (error: $($Error[0]))" $LogFile
        Exit 1
    }
}

DS_WriteLog "-" "" $LogFile


# CREATE OR JOIN XENDESKTOP SITE
# ------------------------------

# Check if the XenDesktop site is configured and retrieve the site version number
DS_WriteLog "I" "Check if the XenDesktop site is configured and retrieve the site version number" $LogFile
$SiteExists = $False
try {
    $SQL_ConnectionString = "Server=$DatabaseServer,$DatabaseServerPort;Database=$DatabaseName_Site;Integrated Security=True;"
    $SQL_Connection = New-Object System.Data.SqlClient.SqlConnection
    $SQL_Connection.ConnectionString = $SQL_ConnectionString
    $SQL_Connection.Open()
    $SQL_Command = $SQL_Connection.CreateCommand()
    $SQL_Query = "SELECT [ProductVersion] FROM [ConfigurationSchema].[Site]"
    $SQL_Command.CommandText = $SQL_Query
    $SQL_QUERY_ProductVersion = new-object "System.Data.DataTable"
    $SQL_QUERY_ProductVersion.Load( $SQL_Command.ExecuteReader() )
    foreach ($Element in $SQL_QUERY_ProductVersion) { 
        $SiteVersion = [string]$Element.Productversion
    }
        
    # If the variable '$SiteVersion' is empty, the site has not yet been created
    if ( [string]::IsNullOrEmpty($SiteVersion)) {
        DS_WriteLog "I" "The site database '$DatabaseName_Site' exists, but the site still needs to be created." $LogFile
    } else {
        DS_WriteLog "I" "The site has already been created. The version of the site is: $SiteVersion" $LogFile
        $SiteExists = $True
    }
    $SQL_Connection.Close()
} catch {
    DS_WriteLog "E" "An error occurred trying to retrieve the site and site version (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Create a new site, or if the site exists, compare the site version to the version of the XenDesktop product software installed on the local server and join the local server to the site
if ( $SiteExists ) {
    DS_WriteLog "I" "Compare the site version to the version of the XenDesktop product software installed on the local server and join the local server to the site" $LogFile
    
    # Get the version of the XenDesktop product software installed on the local server
    try {
        [string]$XenDesktopSoftwareVersion = (gwmi win32_product | Where-Object { $_.Name -like "*Citrix Broker Service*" }).Version
    } catch {
        DS_WriteLog "E" "An error occurred trying to retrieve the version of the locally installed XenDesktop software  (error: $($Error[0]))" $LogFile
    }
    
    # JOIN SITE
    # ---------
    if ( $SiteVersion -eq $XenDesktopSoftwareVersion.Substring(0,$SiteVersion.Length) ) {
        DS_WriteLog "I" "The site version ($SiteVersion) is equal to the XenDesktop product software installed on the local server ($XenDesktopSoftwareVersion)" $LogFile
        DS_WriteLog "I" "Check if the local server already has been joined to the site" $LogFile

        # Check if the local server already has been joined
        $SQL_ConnectionString = "Server=$DatabaseServer,$DatabaseServerPort;Database=$DatabaseName_Site;Integrated Security=True;"
        $SQL_Connection = New-Object System.Data.SqlClient.SqlConnection
        $SQL_Connection.ConnectionString = $SQL_ConnectionString
        $SQL_Connection.Open()
        $SQL_Command = $SQL_Connection.CreateCommand()
        $SQL_Query = "SELECT [MachineName] FROM [ConfigurationSchema].[Services]"
        $SQL_Command.CommandText = $SQL_Query
        $SQL_QUERY_Controllers = new-object "System.Data.DataTable"
        $SQL_QUERY_Controllers.Load( $SQL_Command.ExecuteReader() )
        $ServerAlreadyJoined = $False
        $x = 0
        foreach ($Element in $SQL_QUERY_Controllers) {
            $x++
            if ( $Element.MachineName -eq $ComputerName ) {
                $ServerAlreadyJoined = $True
            }
        }
        $SQL_Connection.Close()
        
        # Join the local server to the site (if needed)
        if ( $ServerAlreadyJoined ) {
            DS_WriteLog "I" "The local machine $Computername has already been joined to the site '$SiteName'. Nothing to do." $LogFile
        } else {
            DS_WriteLog "I" "The local machine $Computername is not joined to the site '$SiteName'" $LogFile
            # Use one of the available controllers for the parameter 'SiteControllerAddress'
            $y = 0
            foreach ($Element in $SQL_QUERY_Controllers) {
                $y++
                $Controller = ($Element.MachineName).ToUpper()
                DS_WriteLog "I" "Join site using controller $Controller ($y of $x)" $LogFile
                try {
                    Add-XDController -SiteControllerAddress $Controller  | Out-Null
                    DS_WriteLog "S" "The local server was successfully joined to the site '$SiteName'" $LogFile
                    Break
                } catch {
                    DS_WriteLog "E" "An error occurred trying to join using controller $Controller (error: $($Error[0]))" $LogFile
                }
            }
        }
    } else {
        DS_WriteLog "E" "The site version ($SiteVersion) and the version of the locally installed XenDesktop product software ($XenDesktopSoftwareVersion) are not equal!" $LogFile
        Exit 1
    }
} else {
    # CREATE SITE
    # -----------
    DS_WriteLog "I" "Create the XenDesktop site '$SiteName'" $LogFile
    try {
        New-XDSite -DatabaseServer $DatabaseServer -LoggingDatabaseName $DatabaseName_Logging -MonitorDatabaseName $DatabaseName_Monitoring -SiteDatabaseName $DatabaseName_Site -SiteName $SiteName -AdminAddress $ComputerName -ErrorAction Stop  | Out-Null
        DS_WriteLog "S" "The site '$SiteName' was created successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to create the site '$SiteName' (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # LICENSE SERVER CONFIG
    # ---------------------
    # Configure license server
    DS_WriteLog "I" "Configure licensing" $LogFile
    DS_WriteLog "I" "Set the license server" $LogFile
    try {
        Set-XDLicensing -AdminAddress $ComputerName -LicenseServerAddress $LicenseServer -LicenseServerPort $LicenseServerPort -Force  | Out-Null
        DS_WriteLog "S" "The license server '$LicenseServer' was configured successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to configure the license server '$LicenseServer' (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Configure the licensing model, product and edition
    DS_WriteLog "I" "Configure the licensing model, product and edition" $LogFile
    try {  
        Set-ConfigSite  -AdminAddress $ComputerName -LicensingModel $LicensingModel -ProductCode $ProductCode -ProductEdition $ProductEdition | Out-Null
        DS_WriteLog "I" "The licensing model, product and edition have been configured correctly" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to configure the licensing model, product and edition (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Register the certificate hash
    DS_WriteLog "I" "Register the certificate hash" $LogFile
    try {  
        Set-ConfigSiteMetadata -AdminAddress $ComputerName -Name 'CertificateHash' -Value $(Get-LicCertificate -AdminAddress "https://$($LicenseServer):8083").CertHash | Out-Null
        DS_WriteLog "I" "The certificate hash from server '$LicenseServer' has been confirmed successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to confirm the certificate hash from server '$LicenseServer' (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # CREATE ADMINISTRATORS
    # ---------------------
    # Create a full admin group "CTXAdmins"
    DS_WriteLog "I" "Create the Citrix administrator $AdminGroup" $LogFile
    try {
        Get-AdminAdministrator $AdminGroup | Out-Null
        DS_WriteLog "I" "The Citrix administrator $AdminGroup already exists. Nothing to do." $LogFile
    } catch { 
        try {
            New-AdminAdministrator -AdminAddress $ComputerName -Name $AdminGroup | Out-Null
            DS_WriteLog "S" "The Citrix administrator $AdminGroup has been created successfully" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to create the Citrix administrator $AdminGroup (error: $($Error[0]))" $LogFile
            Exit 1
        }
    }

    # Assign full admin rights to the admin group "CTXAdmins"
    DS_WriteLog "I" "Assign full admin rights to the Citrix administrator $AdminGroup" $LogFile
    try {  
        Add-AdminRight -AdminAddress $ComputerName -Administrator $AdminGroup -Role 'Full Administrator' -Scope "All" | Out-Null
        DS_WriteLog "S" "Successfully assigned full admin rights to the Citrix administrator $AdminGroup" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to assign full admin rights to the Citrix administrator $AdminGroup (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # ADDITIONAL SITE CONFIGURATIONS
    # ------------------------------
    # Configure grooming settings
    DS_WriteLog "I" "Configure grooming settings" $LogFile
    try {  
        Set-MonitorConfiguration -GroomApplicationInstanceRetentionDays $GroomingDays -GroomDeletedRetentionDays $GroomingDays -GroomFailuresRetentionDays $GroomingDays -GroomLoadIndexesRetentionDays $GroomingDays -GroomMachineHotfixLogRetentionDays $GroomingDays -GroomNotificationLogRetentionDays $GroomingDays -GroomResourceUsageDayDataRetentionDays $GroomingDays -GroomSessionsRetentionDays $GroomingDays -GroomSummariesRetentionDays $GroomingDays | Out-Null
        DS_WriteLog "S" "Successfully changed the grooming settings to $GroomingDays days" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to change the grooming settings to $GroomingDays days (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Enable the Delivery Controller to trust XML requests sent from StoreFront (https://docs.citrix.com/en-us/receiver/windows/4-7/secure-connections/receiver-windows-configure-passthrough.html)
    DS_WriteLog "I" "Enable the Delivery Controller to trust XML requests sent from StoreFront" $LogFile
    try {  
        Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true | Out-Null
        DS_WriteLog "S" "Successfully enabled trusted XML requests" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to enable trusted XML requests (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Disable connection leasing (enabled by default in a new site)
    DS_WriteLog "I" "Disable connection leasing" $LogFile
    try {
        Set-BrokerSite -ConnectionLeasingEnabled $false | Out-Null
        DS_WriteLog "S" "Connection leasing was disabled successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to disable connection leasing (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Enable Local Host Cache (disabled by default in a new site)
    DS_WriteLog "I" "Enable Local Host Cache" $LogFile
    try {
        Set-BrokerSite -LocalHostCacheEnabled $true | Out-Null
        DS_WriteLog "S" "Local Host Cache was enabled successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to enable Local Host Cache (error: $($Error[0]))" $LogFile
        Exit 1
    }

    DS_WriteLog "-" "" $LogFile

    # Disable the Customer Experience Improvement Program (CEIP)
    DS_WriteLog "I" "Disable the Customer Experience Improvement Program (CEIP)" $LogFile
    try {
        Set-AnalyticsSite -Enabled $false | Out-Null
        DS_WriteLog "S" "The Customer Experience Improvement Program (CEIP) was disabled successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to disable the Customer Experience Improvement Program (CEIP) (error: $($Error[0]))" $LogFile
        Exit 1
    }
}

# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile

"complete"  >> c:\logs\sitedone.txt