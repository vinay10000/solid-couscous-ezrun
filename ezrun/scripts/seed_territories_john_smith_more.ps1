$ErrorActionPreference = 'Stop'

$Base = 'https://olyuuljglgcycjaufoyt.supabase.co/rest/v1/rpc/ezrun_claim_territory'
$Headers = @{
  apikey         = 'sb_publishable_1JKuPs_IvSzoKeco3b96pg_jKSHiMDe'
  Authorization  = 'Bearer sb_publishable_1JKuPs_IvSzoKeco3b96pg_jKSHiMDe'
  'Content-Type' = 'application/json'
}

function Invoke-Claim {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][object[]]$Points
  )

  $Body = @{ 
    p_user_id = '3aa5dcff-0fd8-45ba-b3ed-a254008de9e6'
    p_run_id  = $null
    p_polygon_points = $Points
  } | ConvertTo-Json -Depth 10

  Write-Host "Claiming: $Name"
  try {
    $Res = Invoke-RestMethod -Method Post -Uri $Base -Headers $Headers -Body $Body
    Write-Host "OK territory_id=$Res"
    return $true
  } catch {
    Write-Host "FAILED $Name"
    Write-Host $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
      Write-Host $_.ErrorDetails.Message
    }
    return $false
  }
}

# 5 more territories (different areas)
$ok1 = Invoke-Claim -Name 'Kempegowda International Airport (KIA)' -Points @(
  @{lat=13.2056;lng=77.6903}, @{lat=13.2039;lng=77.6930}, @{lat=13.2018;lng=77.6957}, @{lat=13.1999;lng=77.6942},
  @{lat=13.2003;lng=77.6908}, @{lat=13.2025;lng=77.6885}, @{lat=13.2046;lng=77.6887}, @{lat=13.2056;lng=77.6903}
)

$ok2 = Invoke-Claim -Name 'Nandi Hills (base area)' -Points @(
  @{lat=13.3713;lng=77.6831}, @{lat=13.3698;lng=77.6860}, @{lat=13.3679;lng=77.6870}, @{lat=13.3667;lng=77.6847},
  @{lat=13.3676;lng=77.6818}, @{lat=13.3696;lng=77.6814}, @{lat=13.3710;lng=77.6822}, @{lat=13.3713;lng=77.6831}
)

$ok3 = Invoke-Claim -Name 'Hebbal Lake' -Points @(
  @{lat=13.0419;lng=77.5934}, @{lat=13.0407;lng=77.5961}, @{lat=13.0390;lng=77.5965}, @{lat=13.0383;lng=77.5944},
  @{lat=13.0391;lng=77.5919}, @{lat=13.0409;lng=77.5916}, @{lat=13.0417;lng=77.5925}, @{lat=13.0419;lng=77.5934}
)

$ok4 = Invoke-Claim -Name 'HSR Layout Sector 7' -Points @(
  @{lat=12.9157;lng=77.6424}, @{lat=12.9144;lng=77.6446}, @{lat=12.9126;lng=77.6452}, @{lat=12.9117;lng=77.6435},
  @{lat=12.9122;lng=77.6412}, @{lat=12.9140;lng=77.6407}, @{lat=12.9153;lng=77.6414}, @{lat=12.9157;lng=77.6424}
)

$ok5 = Invoke-Claim -Name 'Jayanagar 4th Block' -Points @(
  @{lat=12.9285;lng=77.5838}, @{lat=12.9273;lng=77.5860}, @{lat=12.9256;lng=77.5865}, @{lat=12.9249;lng=77.5848},
  @{lat=12.9254;lng=77.5826}, @{lat=12.9272;lng=77.5821}, @{lat=12.9282;lng=77.5830}, @{lat=12.9285;lng=77.5838}
)

Write-Host "Done. Success flags: $ok1, $ok2, $ok3, $ok4, $ok5"
