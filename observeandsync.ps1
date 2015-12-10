param 
(
    [switch]$upgrade = $false
)

# A3 Server Details
$ServerNumber = "svr1"
$masterbranch = "C:\srv\arma\arma3-masterbranch\"
$AppDir = "D:\arma3\" + $ServerNumber
$AppPath = # will be $AppDir + arma3server.exe if empty
$ServerParameter = "-world=empty"
$ServerPort = "2302"
$ServerWorkingDir = $AppDir
# $ServerMods = "


#$ModRepo = "Full Qualified Path to Mod Repository"
#$MissionRepo = "Full Qualified Path to Mission Repository"

# Binaries
$7z = "C:\Program Files\7-Zip\7z.exe"

# Config Files
$dropboxconf = "C:\srv\Dropbox\arma3" + $ServerNumber + "\"
$confdir = "D:\arma3\" + $ServerNumber + "\"
$ServerConfig = $confdir + $ServerNumber + "_server.cfg"
$ServerBasic = $confdir + $ServerNumber + "_basic.cfg"
$ServerProfiles = $confdir + $ServerNumber + "\Profile_" + $ServerNumber

# SteamCMD Detail
$SteamCMD = "C:\srv\tools\steamcmd\"
$SteamAccount = "armaadm"
$SteamPassword = "3cgAzy8ug3x39V8q0lpt"
# HINT: You will be asked to manually enter the 
# HINT: Steam Guard Code the first time you run SteamCMD

# Additional App-Related Steam Details
$SteamAppID = "233780"

# Setting AppPath if not defined otherwise
IF([string]::IsNullOrEmpty($AppPath)) 
{
    $AppPath = $AppDir + "arma3server.exe"
}
$ServerPath = $AppPath

##################################
##################################
###                            ###
### DONT EDIT BELOW THIS LINES ###
###                            ###
##################################
##################################

#param(
#    [string]$upgrade = $null
#)





# Starts the program and stores its PID
function ServerStart 
{
    # $Process = [Diagnostics.Process]::Start($AppPath) 
    $id = $Process.Id
    $id = Start-Process arma3server.exe "$ServerParameters -profiles=$ServerProfiles -config=$ServerConfig -cfg=$ServerBasic -mod=$ServerMods" -WorkingDirectory $ServerPath -PassThru    
    Write-Host "Process created. Process id is $id"             
    Write-Host "sleeping for 5 seconds" 
    Start-Sleep 5   
    return $id 
}

# Copies the config from dropbox to srv config
function ServerSync
{
    #$7z "a -tzip -mx=9 "
    robocopy /MIR $masterbranch $AppDir
    robocopy /MIR $dropboxconf $confdir
}

# Updates the master branch
function ServerUpdate
{
    Start-Process $SteamCMD\steamcmd.exe "+login $SteamAccount $SteamPassword +force_install_dir $ServerPath +app_update $SteamAppID -validate +quit"
}

function Email($MsgSubject, $MsgBody)
{
    $SmtpClient = new-object system.net.mail.smtpClient
    $MailMessage = New-Object system.net.mail.mailmessage
    $SmtpClient.Host = "$MailHost"      
    $MailMessage.from = "$MailFrom"   
    $MailMessage.To.add("$MailTo")   
    $MailMessage.Subject = “$MsgSubject”
    $MailMessage.IsBodyHtml = $false
    $MailMessage.Body = "Dear Admin, " + "`n" + "$MsgBody"
    $SmtpClient.Send($mailmessage)
}

# Monitors the Server and restarts it if it gets stuck or just dies
function ServerMonitor
{
    if (Get-Process -id $id -ErrorAction silentlycontinue) 
    {
        if ((gps -id $id).Responding)
        {
            return $true
        } else {
            return $false
        }
    } else {
        return $false
    }
}

# Stops the Server by killing its process (using PID)
function ServerStop
{
    try {            
        Stop-Process -Id $id -ErrorAction stop            
        Write-Host "Successfully killed the process with ID: $ID"                     
    } catch {            
        Write-Host "Failed to kill the process"  
        Email "Failed to kill the process" "the little me was not able to kill the great beast of ArmA 3 Process. PID is: $id."         
    }
}

# Restarts and updates server using StopServer, ServerUpdate and StartServer
function ServerRestart
{
	ServerStop
	Start-Sleep 5
	ServerUpdate
    ServerSync
	Start-Sleep 3
	ServerStart
}

# If Script is called with args
if ($upgrade)
{
    ServerUpdate
    ServerStop
    ServerSync
    ServerStart
    exit
}

# Update, start and monitor the server
while ($true)
{
    $TimeStart = Get-Date
    $TimeEnd = $TimeStart.AddHours(3)

    Do 
    {
        ServerStart
        ServerMonitor
        $TimeNow = Get-Date
        if ($TimeNow -ge $TimeEnd)
        {
            # Time is over
            ServerRestart
        }
        else 
        {
            # Its not yet time
            if (-NOT (ServerMonitor = $true))
            {
                ServerStop
                ServerUpdate
                ServerStart      
            }
        }
        # Pause for 10 Seconds to not waste cpu time
        Start-Sleep -Seconds 10
    }
    Until ($TimeNow -ge $TimeEnd) 
}
