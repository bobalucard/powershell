# Run with SharePoint 2010 Management Shell

$webUrl = Read-Host "Enter the web url"

$web = Get-SPWeb $webUrl

$list = $web.Lists["User Information List"]

$query = New-Object Microsoft.SharePoint.SPQuery

$queryCamlString = '<Query><OrderBy><FieldRef Name="Title" Ascending="True" /></OrderBy></Query>'

$query.Query = $queryCamlString

$UILItems = $list.GetItems($query)

foreach($item in $UILItems)

{
	$first = ""
	$last = ""
	$name = ""
	$name = $item.Title.split(',')
	try {
		$last = $name[0].Trim()
	}
	catch {}
	try {
		$first = $name[1].Trim()
	}
	catch {}
	#$first = $first -replace "\(.*\)",""
	try {
		$first = $first.Trim()
	}
	catch {}
	$full = $item.Title
	try 
	{
		$uad = Get-ADUser -f {Name -eq $full}
		if ($uad -ne $null -and $uad.Enabled -ne "True")
		{
			"$first, $last, Disabled" | Out-File -FilePath output.csv -Append -Encoding ASCII
			write-host "$full "$uad.Enabled
		}
	}
	catch { Write-host "Search failed level 1 for $full"}
	if (($uad -eq $null) -and ($first -ne "" -and $last -ne ""))
	{
		try
		{
			$uad2 = Get-ADUser -f {GivenName -eq $first -and Surname -eq $last}
			#if
		}
		catch { Write-host "Search failed level 2 for f:$first l:$last"}
		if ($uad2 -eq $null)
		{
			$first = $first.split()
			$first = $first[0]
			try
			{
				$uad3 = Get-ADUser -f {GivenName -eq $first -and Surname -eq $last}
			}
			catch { Write-host "Search failed level 3 for f:$first l:$last"}
			if ($uad3 -eq $null)
			{
				Write-host "User does not exist in AD: $first $last"
				"$first, $last, Missing" | Out-File -FilePath output.csv -Append -Encoding ASCII
			}
		}
	}
}
