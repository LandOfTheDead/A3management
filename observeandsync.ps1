# A3 Server Details
$srvnr = "svr1"
$masterbranch = "C:\srv\arma\arma3-masterbranch\"
$AppDir = "D:\arma3\" + $srvnr
$AppPath = # will be $AppDir + arma3server.exe if empty
#$ModRepo = "Full Qualified Path to Mod Repository"
#$MissionRepo = "Full Qualified Path to Mission Repository"

# Binaries
$7z = "C:\Program Files\7-Zip\7z.exe"

# Config Files
$dpconf = "C:\srv\Dropbox\arma3" + $srvnr
$confdir = "D:\arma3\" + $srvnr "\"
$srvconfig = $confdir + $srvnr "_server.cfg"

# Setting AppPath if not defined otherwise
IF([string]::IsNullOrEmpty($AppPath)) 
{
    $AppPath = $AppDir + "arma3server.exe"
}

##################################
##################################
###                            ###
### DONT EDIT BELOW THIS LINES ###
###                            ###
##################################
##################################


# Starts the program and stores its PID
function ServerStart 
{
    $Process = [Diagnostics.Process]::Start($AppPath)            
    $id = $Process.Id            
    Write-Host "Process created. Process id is $id"             
    Write-Host "sleeping for 5 seconds" 
    Start-Sleep 5   
    return $id 
}

# Copies the config from dropbox to srv config
function sync
{
    
    robocopy /MIR $masterbranch $AppDir
    robocopy /MIR $dpconf $confdir
}



