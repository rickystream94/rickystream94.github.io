param
(
	[Parameter(Mandatory=$true)]
    [string] $RekordboxCollectionXmlFilePath,

    [Parameter(Mandatory=$false)]
	[switch] $WhatIf
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $RekordboxCollectionXmlFilePath))
{
    throw "Rekordbox collection XML file not found: '$RekordboxCollectionXmlFilePath'"
}

$startTime = Get-Date

$outputFolder = Split-Path $RekordboxCollectionXmlFilePath -Parent
$logFilePath = Join-Path $outputFolder "delete_tracks_$((Get-Date).ToString("yyyy-MM-dd_HH-mm")).log"

# Open XML file
[xml]$rekordboxCollection = Get-Content $RekordboxCollectionXmlFilePath

# Get tracks to be deleted by inspecting the playlist "Delete"
$libraryMgmtNode = $rekordboxCollection.DJ_PLAYLISTS.PLAYLISTS.NODE.NODE | ? {$_.Name -eq "LIBRARY MANAGEMENT"}
if (!$libraryMgmtNode)
{
	throw "No 'LIBRARY MANAGEMENT' playlist folder found in the Rekordbox collection XML."
}

$deletePlaylist = $libraryMgmtNode.NODE | ? {$_.Name -eq "Delete"}
if (!$deletePlaylist)
{
	throw "No 'Delete' playlist found in the 'LIBRARY MANAGEMENT' folder of the Rekordbox collection XML."
}

$trackIds = $deletePlaylist.TRACK | % Key

Write-Host "Found $($trackIds.Count) tracks marked for deletion."

# Find paths of the tracks to be deleted by inspecting the collection
$tracksToDelete = $rekordboxCollection.DJ_PLAYLISTS.COLLECTION.TRACK | ? {$_.TrackID -in $trackIds}

$deletedTracksCount = 0
$tracksFailedToDelete = 0

Write-Host "Found $($tracksToDelete.Count) tracks to delete in the Rekordbox collection."
if ($tracksToDelete.Count -eq 0)
{
	Write-Host "No tracks to delete found in the Rekordbox collection." -ForegroundColor Green
	return
}

$tracksToDeletePaths = $tracksToDelete | % { [System.Uri]::UnescapeDataString(($_.Location -replace "file://localhost/","")) }
foreach ($trackPath in $tracksToDeletePaths)
{
	if (!(Test-Path -LiteralPath $trackPath))
	{
		Write-Warning "Track not found: $trackPath"
		"Track not found: $trackPath" | Out-File -FilePath $logFilePath -Append
		$tracksFailedToDelete++
		continue
	}

	$trackName = Split-Path $trackPath -Leaf
	Write-Host "Deleting track: '$trackName' at '$trackPath'"
	if ($WhatIf)
	{
		Write-Host "WhatIf mode is enabled. Skipping deletion of '$trackName'." -ForegroundColor Yellow
	}
	else
	{
		try
		{
			Remove-Item -LiteralPath $trackPath -Force
			Write-Host "Deleted track: '$trackName'" -ForegroundColor Green
			$deletedTracksCount++
			"Deleted track: '$trackName' at '$trackPath'" | Out-File -FilePath $logFilePath -Append
		}
		catch
		{
			Write-Error "Failed to delete track '$trackName': $($_.Exception.Message)"
			"Failed to delete track '$trackName': $($_.Exception.Message)" | Out-File -FilePath $logFilePath -Append
			$tracksFailedToDelete++
		}
	}
}

Write-Host "`nDone! It took $(((Get-Date) - $startTime).TotalSeconds) seconds." -ForegroundColor Green
Write-Host "Deleted tracks: $deletedTracksCount" -ForegroundColor Green
Write-Host "Failed to delete tracks: $tracksFailedToDelete" -ForegroundColor Yellow