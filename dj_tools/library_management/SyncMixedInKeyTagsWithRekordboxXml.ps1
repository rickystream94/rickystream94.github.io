param
(
    [Parameter(Mandatory=$true)]
    [string] $RekordboxCollectionXmlFilePath
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $RekordboxCollectionXmlFilePath))
{
    throw "Rekordbox collection XML file not found: '$RekordboxCollectionXmlFilePath'"
}

# Add required types
if (!([System.AppDomain]::CurrentDomain.GetAssemblies() | ? {$_ -match "TagLibSharp"}))
{
    $tagLibSharpDllPath = Join-Path $PSScriptRoot "lib\TagLibSharp.dll"
    if (!(Test-Path $tagLibSharpDllPath))
    {
        throw "TagLibSharp.dll not found in '$PSScriptRoot\lib'. Please ensure it is present."
    }

    Add-Type -Path $tagLibSharpDllPath
}

# Read mapping energy level -> color code from JSON file
$energyLevelMappingFile = Join-Path $PSScriptRoot "EnergyLevelToColorCode.json"
if (Test-Path $energyLevelMappingFile)
{
    $energyLevelToColorCode = Get-Content -Path $energyLevelMappingFile | ConvertFrom-Json
}
else
{
    throw "Energy level to color code mapping file not found: '$energyLevelMappingFile'."
}

$outputFolder = Split-Path $RekordboxCollectionXmlFilePath -Parent
$outputFile = Join-Path $outputFolder "rekordbox_collection_$((Get-Date).ToString("yyyy-MM-dd_HH-mm")).xml"
$infoLogFilePath = Join-Path $outputFolder "info_$((Get-Date).ToString("yyyy-MM-dd_HH-mm")).log"

$startTime = Get-Date

# Open XML file
[xml]$rekordboxCollection = Get-Content $RekordboxCollectionXmlFilePath

$tracksToProcess = $rekordboxCollection.DJ_PLAYLISTS.COLLECTION.TRACK
$tracksNotFound = 0
$tracksWithNoTonality = 0
$tracksWithNoEnergyLevel = 0
$skippedTracks = 0

$fixedKeyTrackIds = @()
$fixedColourTrackIds = @()

# Create custom playlists the fixed tracks will be added to, so it's easier to re-import them in Rekordbox
$libraryMgmtNode = $rekordboxCollection.DJ_PLAYLISTS.PLAYLISTS.NODE.NODE | ? {$_.Name -eq "LIBRARY MANAGEMENT"}
if (!$libraryMgmtNode)
{
    throw "No 'LIBRARY MANAGEMENT' playlist folder found in the Rekordbox collection XML."
}

foreach ($playlistName in @("MIK Key Analysis", "MIK Energy Level Analysis"))
{
    $customPlaylist = $libraryMgmtNode.NODE | ? {$_.Name -eq $playlistName}
    if (!$customPlaylist)
    {
        # Create the new NODE element
        $customPlaylist = $rekordboxCollection.CreateElement("NODE")
    }
    else
    {
        # Clear the existing playlist if it exists
        $customPlaylist.RemoveAll() | Out-Null
    }

    $customPlaylist.SetAttribute("Name", $playlistName)
    $customPlaylist.SetAttribute("Type", "1")
    $customPlaylist.SetAttribute("KeyType", "0")
    $customPlaylist.SetAttribute("Entries", "0") # This will be updated later with the actual count

    # Add it as a child of $libraryMgmtNode
    $libraryMgmtNode.AppendChild($customPlaylist) | Out-Null
}

# Find the newly created custom playlists for MIK Key Analysis and MIK Energy Level Analysis
$mikKeyAnalysisPlaylist = $libraryMgmtNode.NODE | ? {$_.Name -eq "MIK Key Analysis"}
$mikEnergyLevelAnalysisPlaylist = $libraryMgmtNode.NODE | ? {$_.Name -eq "MIK Energy Level Analysis"}

foreach ($track in $tracksToProcess)
{
    $encodedTrackPath = $track.Location -replace "file://localhost/",""
    $trackPath = [System.Uri]::UnescapeDataString($encodedTrackPath)

    if (!(Test-Path -LiteralPath $trackPath))
    {
        Write-Warning "Track not found: $trackPath"
        $tracksNotFound++
        "Track not found: $trackPath" | Out-File -FilePath $infoLogFilePath -Append
        continue
    }

    $trackName = Split-Path $trackPath -Leaf
    $media = [TagLib.File]::Create($trackPath)

    # The assumption here is that we have setup MIK to write the key and energy level at the beginning of the 'Comment' tag, like "1A - Energy 6"
    $comment = $media.Tag.Comment
    $initialKey = $comment -split " " | select -First 1

    ######### ENERGY LEVEL HANDLING #########
    # For energy level, we can't trust that it's always going to be last in the comments, as the MIK comment precedes any other pre-existing comment.
    # Extract the energy level using regex.
    if ($comment -match "Energy (\d{1,2})")
    {
        # Map energy level from MIK with color codes used by Rekordbox
        $energyLevel = $matches[1]
        $currentColor = $track.Colour
        $expectedColor = $energyLevelToColorCode.$energyLevel
        if ($currentColor -ne $expectedColor)
        {
            Write-Host "Updating color mapped to energy level ($energyLevel) for track '$trackName'" -ForegroundColor Magenta
            $track.SetAttribute("Colour", $expectedColor)
            $fixedColourTrackIds += $track.TrackID

            $playlistTrackNode = $rekordboxCollection.CreateElement("TRACK")
            $playlistTrackNode.SetAttribute("Key", $track.TrackID)
            $mikEnergyLevelAnalysisPlaylist.AppendChild($playlistTrackNode) | Out-Null
        }
        else
        {
            Write-Host "Track '$trackName' already has correct color for energy level ($energyLevel)" -ForegroundColor Green
        }
    }
    else
    {
        Write-Warning "Track '$trackName' has no energy level in comment: '$comment'"
        "Track '$trackName' has no energy level in comment: '$comment'" | Out-File -FilePath $infoLogFilePath -Append
        $tracksWithNoEnergyLevel++
    }

    ######### KEY HANDLING #########
    if ($track.Kind -ne "M4A File")
    {
        Write-Host "Skipping key handling for track '$trackName' because it is not an M4A file." -ForegroundColor Yellow
        "Skipping key handling for track '$trackName' because it is not an M4A file." | Out-File -FilePath $infoLogFilePath -Append
        $skippedTracks++
        continue
    }

    if (!$comment -or !$initialKey -or $initialKey -notmatch "^\d{1,2}[A-G]$")
    {
        Write-Warning "Track '$trackName' has no valid tonality in comment: '$comment'"
        $tracksWithNoTonality++
        "Track '$trackName' has no valid tonality in comment: '$comment'" | Out-File -FilePath $infoLogFilePath -Append
        continue
    }

    $trackTonality = $track.Tonality
    if ($trackTonality -eq $initialKey)
    {
        Write-Host "Track '$trackName' already has correct tonality" -ForegroundColor Green
    }
    else
    {
        Write-Host "Fixing tonality for track '$trackName': $trackTonality (Rekordbox) --> $initialKey (Mixed In Key)" -ForegroundColor Magenta
        $track.Tonality = $initialKey
        $fixedKeyTrackIds += $track.TrackID
        "Fixed tonality for track '$trackName': $trackTonality (Rekordbox) --> $initialKey (Mixed In Key)" | Out-File -FilePath $infoLogFilePath -Append

        $playlistTrackNode = $rekordboxCollection.CreateElement("TRACK")
        $playlistTrackNode.SetAttribute("Key", $track.TrackID)
        $mikKeyAnalysisPlaylist.AppendChild($playlistTrackNode) | Out-Null
    }
}

# Update custom playlists entries count
$mikEnergyLevelAnalysisPlaylist.SetAttribute("Entries", $fixedColourTrackIds.Count.ToString())
$mikKeyAnalysisPlaylist.SetAttribute("Entries", $fixedKeyTrackIds.Count.ToString())

$endTime = Get-Date
$duration = $endTime - $startTime

# Save the modified Rekordbox collection XML file
$rekordboxCollection.Save($outputFile)

Write-Host "`nDone! It took $($duration.TotalSeconds) seconds." -ForegroundColor Green
Write-Host "Processed tracks: $($tracksToProcess.Count)" -ForegroundColor Green
Write-Host "Tracks with fixed key: $($fixedKeyTrackIds.Count) (Find in 'LIBRARY MANAGEMENT' > 'MIK Key Analysis' playlist)" -ForegroundColor Green
Write-Host "Tracks with fixed color: $($fixedColourTrackIds.Count) (Find in 'LIBRARY MANAGEMENT' > 'MIK Energy Level Analysis' playlist)" -ForegroundColor Green
Write-Host "Tracks not found: $tracksNotFound" -ForegroundColor Yellow
Write-Host "Tracks with no valid tonality in 'Comment' ID3 tag: $tracksWithNoTonality" -ForegroundColor Yellow
Write-Host "Tracks with no energy level in 'Comment' ID3 tag: $tracksWithNoEnergyLevel" -ForegroundColor Yellow
Write-Host "New Rekordbox XML collection saved to: $outputFile" -ForegroundColor Cyan
Write-Host "Log file created at: $infoLogFilePath" -ForegroundColor Cyan
