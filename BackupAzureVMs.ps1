
$subscriptionid = "subscriptionid"
$vaultName = "harman-vault";
$rgname = "anbougie-harman"
$location = "West Europe"

Connect-AzureRmAccount
Set-AzureRmContext -Subscription $subscriptionid

# You should only have to do this once in your environment
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"

$vault1 = Get-AzureRmRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgname
Set-AzureRmRecoveryServicesVaultContext -Vault $vault1
$container = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM -Name harmanvm1 -ResourceGroupName anbougie-harman
$backupitem = Get-AzureRmRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM
$job = Backup-AzureRmRecoveryServicesBackupItem -Item $backupitem
$joblist = Get-AzureRmRecoveryservicesBackupJob –Status "InProgress"