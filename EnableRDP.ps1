#Enabled RDP Icon and then creates Citrix Icon for user to RDP to the workstation via citrix web interface or storefront
#open csv file that has list of computers
#Make sure this is run from a citrix server in order for the icon to be created successfully.
#ideal for Xenapp 6.0 and 6.5
<#
Sample of csv opened in notepad:
WS_name,User_ID
WorkstationName,UserName
Workstation2,User2
Workstation2,User1
#>
$file1 = "C:\path\file.csv"
notepad $file1
Write-Host "Edit notepadfile to include computernames and userIDs. Press any key to continue ..."
#Domain variable domain.com would be domain, domain1.org would also be domain1
$domain = 'domain'
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host "Adding Citrix Snapins to console and Contacting workstation to continue"
Add-PSSnapin Citrix*
$file = Import-CSV $file1
ForEach ($record in $file){
$WSname = $record.WS_name
$UserID = $record.User_ID
    #check to make sure computer is Up
    #works with Win7 - not tested with win8
    $PingStatus = Gwmi Win32_PingStatus -Filter "Address = '$WSname'" | Select-Object StatusCode 
    If ($PingStatus.StatusCode -eq 0){ 
        #update permissions to allow RDP
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $WSname ) 
        $regKey= $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server",$true) 
        $regKey.SetValue("fDenyTSConnections","0",[Microsoft.Win32.RegistryValueKind]::DWord) 
    #add user to remote desktop user group
	$de = [ADSI]"WinNT://$WSname/Remote Desktop Users,group" 
	$de.psbase.Invoke("Add",([ADSI]"WinNT://$domain/$UserID").path)
    #create icon on Xenapp Farm
    #application shows up in /Applications/Remote Desktop
    #icon in web interface or Storefront shows up in 'Remote Desktop' folder
    $wgname = "workergroup"
	New-XAApplication –BrowserName "$WSname - $UserID" -DisplayName "$WSname - $UserID" –CommandLineExecutable "C:\WINDOWS\system32\mstsc.exe /v:$WSname" -WorkingDirectory C:\Windows\system32\ -ApplicationType ServerInstalled -ClientFolder "Remote Desktop" -FolderPath "Applications/Remote Desktop"
	Add-XAApplicationWorkerGroup "$WSname - $UserID" –WorkerGroupNames "$wgname"
	Add-XAApplicationAccount "$WSname - $UserID" “$domain\$UserID”
	Set-XAApplication "$WSname - $UserID" –Enabled $true
	Write-Host "Icon $WSname - $UserID created in Remote Desktop Folder. Press any key to continue ..."
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
     } 
    else { 
        Write-Host "$WSname unreachable" 
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } 
} 