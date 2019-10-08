net user administrator /active:yes
net user administrator Nhanhoa2019#@!
net user cloud /active:no
net user cloud /delete
net user admin /active:no
net user admin /delete
$all_services = Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService"
$all_services.InstallProductKey("YFQJ2-JT3Y2-KJXGF-DKHJ6-42QYY")
$service = Get-WmiObject SoftwareLicensingProduct | Where-Object {$_.PartialProductKey}
$service.Activate()
$all_services.RefreshLicenseStatus()
shutdown /r
