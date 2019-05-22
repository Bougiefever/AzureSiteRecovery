

$subscriptionid = "subscriptionid"
$storageaccountname = "mystorageaccount"
$key = "key1"
$sharename = "main"

#Connect-AzureRmAccount
Set-AzureRmContext -Subscription $subscriptionid

# Get the storact account context
$ctx = New-AzureStorageContext -StorageAccountName $storageaccountname -StorageAccountKey $key

# Get a reference to the share
$share = Get-AzureStorageFile -Context $ctx -Name $sharename

# Create a new snapshot
# The snapshot object contains properties, such as the uri
$snapshot = $share.Snapshot()

# Get a list of all snapshots
$snapshots = Get-AzureStorageShare -Context $ctx | Where-Object { $_.Name -eq $sharename -and $_.IsSnapshot -eq $true }

# Delete a snapshot
Remove-AzureStorageShare -Share $snapshot
