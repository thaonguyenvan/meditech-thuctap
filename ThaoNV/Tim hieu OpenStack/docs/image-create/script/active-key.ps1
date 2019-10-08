param(
[string]$key
)

$all_services = Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService"
$all_services.InstallProductKey($key)
$service = Get-WmiObject SoftwareLicensingProduct | Where-Object {$_.PartialProductKey}
$service.Activate()
$all_services.RefreshLicenseStatus()
