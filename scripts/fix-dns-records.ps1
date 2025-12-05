# Fix DNS Records (retry without BOM)
$DOMAIN_NAME = "insight-hr.io.vn"
$CLOUDFRONT_DOMAIN = "d2z6tht6rq32uy.cloudfront.net"
$CERTIFICATE_ARN = "arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c"

# Get hosted zone
$zones = aws route53 list-hosted-zones --output json | ConvertFrom-Json
$zone = $zones.HostedZones | Where-Object { $_.Name -eq "$DOMAIN_NAME." }
$HOSTED_ZONE_ID = $zone.Id

Write-Host "Fixing DNS records..." -ForegroundColor Yellow
Write-Host "Hosted Zone: $HOSTED_ZONE_ID" -ForegroundColor Cyan

# Get certificate validation records
$certDetails = aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region us-east-1 --output json | ConvertFrom-Json

Write-Host ""
Write-Host "Creating validation records..." -ForegroundColor Yellow

foreach ($validation in $certDetails.Certificate.DomainValidationOptions) {
    if ($validation.ResourceRecord) {
        $record = $validation.ResourceRecord
        Write-Host "  $($validation.DomainName): $($record.Name)" -ForegroundColor Cyan
        
        $json = "{`"Changes`":[{`"Action`":`"UPSERT`",`"ResourceRecordSet`":{`"Name`":`"$($record.Name)`",`"Type`":`"$($record.Type)`",`"TTL`":300,`"ResourceRecords`":[{`"Value`":`"$($record.Value)`"}]}}]}"
        
        $utf8 = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText("temp.json", $json, $utf8)
        
        aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp.json | Out-Null
        Remove-Item "temp.json" -ErrorAction SilentlyContinue
        
        Write-Host "    Created" -ForegroundColor Green
    }
}

# Create A records
Write-Host ""
Write-Host "Creating A records..." -ForegroundColor Yellow

$json = "{`"Changes`":[{`"Action`":`"UPSERT`",`"ResourceRecordSet`":{`"Name`":`"$DOMAIN_NAME`",`"Type`":`"A`",`"AliasTarget`":{`"HostedZoneId`":`"Z2FDTNDATAQYW2`",`"DNSName`":`"$CLOUDFRONT_DOMAIN`",`"EvaluateTargetHealth`":false}}}]}"
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("temp.json", $json, $utf8)
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp.json | Out-Null
Remove-Item "temp.json" -ErrorAction SilentlyContinue
Write-Host "  $DOMAIN_NAME" -ForegroundColor Green

$json = "{`"Changes`":[{`"Action`":`"UPSERT`",`"ResourceRecordSet`":{`"Name`":`"www.$DOMAIN_NAME`",`"Type`":`"A`",`"AliasTarget`":{`"HostedZoneId`":`"Z2FDTNDATAQYW2`",`"DNSName`":`"$CLOUDFRONT_DOMAIN`",`"EvaluateTargetHealth`":false}}}]}"
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("temp.json", $json, $utf8)
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://temp.json | Out-Null
Remove-Item "temp.json" -ErrorAction SilentlyContinue
Write-Host "  www.$DOMAIN_NAME" -ForegroundColor Green

Write-Host ""
Write-Host "DNS records fixed!" -ForegroundColor Green
