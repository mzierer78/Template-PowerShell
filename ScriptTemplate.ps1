<# Scriptheader
.Synopsis 
    Short description of script purpose
.DESCRIPTION 
    Detailed description of script purpose
.NOTES 
   Created by: 
   Modified by: 
 
   Changelog: 
 
   To Do: 
.PARAMETER Debug 
    If the Parameter is specified, script runs in Debug mode
.EXAMPLE 
   Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error 
   Writes the message to the specified log file as an error message, and writes the message to the error pipeline. 
.LINK 
   https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0 
#>

param(
    [string]$XMLName = "config.xml",
    [switch]$Debug
)

#region loading modules, scripts & files
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptNameTmp = ($MyInvocation.MyCommand.Name).Split(".")
$ScriptName = $ScriptNameTmp[0]
#
# load configuration XML(s)
$XMLPath = Join-Path $here -ChildPath $XMLName
[xml]$ConfigFile = Get-Content -Path $XMLPath
#
# we write one logfile and append each script execution
[string]$global:Logfile = $ConfigFile.Configuration.Logfile.Name
If ($Logfile -eq "Default"){
    $global:Logfile = Join-Path "C:\Windows\Logs" -ChildPath ($ScriptName + ".log")
} else {
  $global:Logfile = Join-Path $ConfigFile.Configuration.Logfile.Path -ChildPath $LogFile
}
$lfTmp = $global:Logfile.Split(".")
$global:Logfile = $lfTmp[0] + (Get-Date -Format yyyyMMdd) + "." + $lfTmp[1]
#
<# Debug Mode
# If the parameter '-Debug' is specified or debug in XMLfile is set to "true", script activates debug mode
# when debug mode is active, debug messages will be dispalyed in console windows 
#>
#
If ($ConfigFile.Configuration.debug -eq "true"){
    $Debug = $true
}
#
If ($Debug){
    $DebugPreference = "Continue"
} else {$DebugPreference = "SilentlyContinue"}
#
#endregion

#region functions
function  Write-Log {
  param
  (
    [Parameter(Mandatory=$true)]
    $Message
  )
  If($Debug){
    Write-Debug -Message $Message
  }

  $msgToWrite =  ('{0} :: {1}' -f (Get-Date -Format yyy-MM-dd_HH-mm-ss),$Message)

  if($global:Logfile)
  {
    $msgToWrite | out-file -FilePath $global:Logfile -Append -Encoding utf8
  }
}
function Exit-Script {
  param (
    $ExitCode = 0
  )
  Write-Log -Message "start function Exit-Script"
  Write-Log -Message "Exit Script execution with Error Code $ExitCode"
  Exit $ExitCode
}
function Show-ActionBox {
  param(
    $Button1Text = "Cancel",
    $Button2Text = "Back",
    $Button3Text = "Next",
    $TextToDisplay = "No Text provided"
  )
  <# TextToDisplay
  Damit der Text angezeigt werden kann, muss er in einem bestimmten Format
  vorliegen. Nachfolgend ein Beispiel

  $TextToDisplay = @"
    Es existiert bereits ein Benutzer Home Verzeichnis: 

    $UserHomePath

    Dieses Verzeichnis muss entfernt / archiviert werden
    bevor der Benutzer angelegt werden kann

    Benutzeranlage wird daher abgebrochen
"@

  Nur wichtig sind hierbei die beiden @ zeichen. Alles was zwischen Ihnen
  steht, wird als Text angezeigt. Es können auch Variablen verwendet werden.
  #>
  
  Write-Log -Message "start function Show-ActionBox"
  Add-Type -AssemblyName System.Windows.Forms
  # Erstelle ein Formular
  $form = New-Object Windows.Forms.Form
  $form.Text = $FormText
  $form.Size = New-Object Drawing.Size($FormSize)

  # Erstelle ein Label für den Text
  $label = New-Object Windows.Forms.Label
  $label.Text = $TextToDisplay
  $label.Location = New-Object Drawing.Point(20, 20)
  $label.AutoSize = $true

  # Erstelle die Schaltfläche "Cancel"
  $cancelButton = New-Object Windows.Forms.Button
  $cancelButton.Text = $Button1Text
  $cancelButton.Location = New-Object Drawing.Point(20, 270)
  $cancelButton.DialogResult = [Windows.Forms.DialogResult]::Cancel

  # Erstelle die Schaltfläche "Back"
  $backButton = New-Object Windows.Forms.Button
  $backButton.Text = $Button2Text
  $backButton.Location = New-Object Drawing.Point(120, 270)
  $backButton.DialogResult = [Windows.Forms.DialogResult]::Retry

  # Erstelle die Schaltfläche "Next"
  $continueButton = New-Object Windows.Forms.Button
  $continueButton.Text = $Button3Text
  $continueButton.Location = New-Object Drawing.Point(220, 270)
  $continueButton.DialogResult = [Windows.Forms.DialogResult]::OK

  # Füge die Steuerelemente zum Formular hinzu
  $form.Controls.Add($label)
  $form.Controls.Add($cancelButton)
  $form.Controls.Add($backButton)
  $form.Controls.Add($continueButton)

  # Zeige das Formular als Dialog an
  $result = $form.ShowDialog()

  # Überprüfe das Ergebnis
  if ($result -eq [Windows.Forms.DialogResult]::OK) {
      Write-Log -Message "User clicked $Button3Text"
  } 
  if ($result -eq [Windows.Forms.DialogResult]::Retry){
      Write-Log -Message "User clicked $Button2Text"
      $Global:Back = $true
  }
  if ($result -eq [Windows.Forms.DialogResult]::Cancel) {
      Write-Log -Message "User clicked $Button1Text"
      $Global:ExitScript = $true
  }

  # Gib das Formular frei
  $form.Dispose()
  write-log -Message "end function Show-ActionBox"
  
}
function Show-InfoBox {
  param (
    $TextToDisplay
  )
  Write-Log -Message "start function Show-InfoBox"
  # Anzeigen der Infos, welche zum Erstellen des Benutzers verwendet werden
  
  Write-Log -Message "Show message box"
  Add-Type -AssemblyName System.Windows.Forms
  # Erstelle ein Formular
  $form = New-Object Windows.Forms.Form
  $form.Text = $FormText
  $form.Size = New-Object Drawing.Size($FormSize)

  # Erstelle ein Label für den Text
  $label = New-Object Windows.Forms.Label
  $label.Text = $TextToDisplay
  $label.Location = New-Object Drawing.Point(20, 20)
  $label.AutoSize = $true

  # Erstelle die Schaltfläche "OK"
  $okButton = New-Object Windows.Forms.Button
  $okButton.Text = "OK"
  $okButton.Location = New-Object Drawing.Point(130, 270)
  $okButton.DialogResult = [Windows.Forms.DialogResult]::OK

  # Füge die Steuerelemente zum Formular hinzu
  $form.Controls.Add($label)
  $form.Controls.Add($okButton)
  
  # Zeige das Formular als Dialog an
  $result = $form.ShowDialog()
  
  # Überprüfe das Ergebnis
  if ($result -eq [Windows.Forms.DialogResult]::OK) {
      Write-Log -Message "User clicked OK"
  } 

  # Gib das Formular frei
#  $form.Dispose()
  write-log -Message "end function Show-ADInfos"
}
#endregion

#region write basic infos to log
Write-Log -Message '------------------------------- START -------------------------------'
$ScriptStart = "Script started at:               " + (Get-date)
Write-Log -Message $ScriptStart
If($Debug){
  Write-Log -Message "Debug Mode is:                   enabled"
} else {
  Write-Log -Message "Debug Mode is:                   disabled"
}
Write-Log -Message "PowerShell Script Path is:       $here"
Write-Log -Message "XML Config file is:              $XMLPath"
Write-Log -Message "LogFilePath is:                  $LogFile"
#endregion

#region read data from XML file
Write-Log -Message "start region read data from XML file"
[xml]$DataSource = Get-Content -Path $XMLPath

# prepare Variables
[string]$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
[string]$Setting1Name = $DataSource.Configuration.Setting1.Name
[string]$Setting1Type = $DataSource.Configuration.Setting1.Type

# dump Variables used:
Write-Log -Message "Dumping read values to Log..."
Write-Log -Message ('Current User Context:            {0}' -f $CurrentUser)
Write-Log -Message ('Setting1Name:                    {0}' -f $DataSource.Configuration.Setting1.Name)
Write-Log -Message ('Setting1Type:                    {0}' -f $DataSource.Configuration.Setting1.Type)
#foreach ($Service in $DataSource.Configuration.Service){Write-Log -Message ('Service Name:                    {0}' -f $Service.Name)}
Write-Log -Message "end region read data from XML file"
#endregion


#region Cleanup
Remove-Variable -Name DataSource

#endregion
Write-Log -Message '-------------------------------- End -------------------------------'