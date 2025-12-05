# Step 1: Create Route53 Hosted Zone
$DOMAIN_NAME = "insight-hr.io.vn"

Write-Host "Creating Route53 hosted zone for $DOMAIN_NAME..." -ForegroundColor Yellow

$callerRef = [System.Guid]::NewGuid().ToString()
$result = aws route53 create-hosted-zone `
    --name $DOMAIN_NAME `
    --caller-reference $callerRef `
    --output json 2>&1

if ($LASTEXITCODE -eq 0) {
    $json = $result | ConvertFrom-Json
    $zoneId = $json.HostedZone.Id
    $nameservers = $json.DelegationSet.NameServers
    
    Write-Host ""
    Write-Host "SUCCESS! Hosted zone created" -ForegroundColor Green
    Write-Host "Zone ID: $zoneId" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "UPDATE NAMESERVERS AT MATBAO.NET" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    foreach ($ns in $nameservers) {
        Write-Host "  $ns" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "SAVE THESE NAMESERVERS!" -ForegroundColor Red
    Write-Host ""
    
    # Save to file
    $nameservers | Out-File -FilePath "nameservers.txt"
    Write-Host "Nameservers saved to: nameservers.txt" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "Checking for existing hosted zone..." -ForegroundColor Yellow
    $zones = aws route53 list-hosted-zones --output json | ConvertFrom-Json
    $zone = $zones.HostedZones | Where-Object { $_.Name -eq "$DOMAIN_NAME." }
    
    if ($zone) {
        $zoneId = $zone.Id
        Write-Host "Hosted zone already exists: $zoneId" -ForegroundColor Green
        
        $zoneDetails = aws route53 get-hosted-zone --id $zoneId --output json | ConvertFrom-Json
        $nameservers = $zoneDetails.DelegationSet.NameServers
        
        Write-Host ""
        Write-Host "Nameservers for Matbao.net:" -ForegroundColor Yellow
        foreach ($ns in $nameservers) {
            Write-Host "  $ns" -ForegroundColor White
        }
        Write-Host ""
        
        $nameservers | Out-File -FilePath "nameservers.txt"
        Write-Host "Nameservers saved to: nameservers.txt" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "Next: Run .\scripts\setup-domain-step2.ps1" -ForegroundColor Cyan
