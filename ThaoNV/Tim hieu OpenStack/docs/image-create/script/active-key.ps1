$all_services = Get-WmiObject -Query "SELECT * FROM SoftwareLicensingService"
$all_services.InstallProductKey("VPJ6B-W2R9M-7KD7R-8KWQV-G4TG2")
$service = Get-WmiObject SoftwareLicensingProduct | Where-Object {$_.PartialProductKey}
$service.Activate()
$all_services.RefreshLicenseStatus()
