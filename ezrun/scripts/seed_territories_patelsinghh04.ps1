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
    p_user_id = 'db4ac973-3d3e-41e0-abc3-87f06f16e310'
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

# 5 territories in Bangalore (different areas)
$ok1 = Invoke-Claim -Name 'MG Road / Trinity' -Points @(
  @{lat=12.9740;lng=77.6214}, @{lat=12.9728;lng=77.6236}, @{lat=12.9712;lng=77.6241}, @{lat=12.9706;lng=77.6223},
  @{lat=12.9710;lng=77.6202}, @{lat=12.9726;lng=77.6196}, @{lat=12.9736;lng=77.6205}, @{lat=12.9740;lng=77.6214}
)

$ok2 = Invoke-Claim -Name 'Whitefield (ITPL area)' -Points @(
  @{lat=12.9878;lng=77.7368}, @{lat=12.9865;lng=77.7392}, @{lat=12.9848;lng=77.7398}, @{lat=12.9839;lng=77.7382},
  @{lat=12.9844;lng=77.7360}, @{lat=12.9861;lng=77.7354}, @{lat=12.9874;lng=77.7360}, @{lat=12.9878;lng=77.7368}
)

$ok3 = Invoke-Claim -Name 'Electronic City Phase 1' -Points @(
  @{lat=12.8442;lng=77.6640}, @{lat=12.8428;lng=77.6663}, @{lat=12.8410;lng=77.6669}, @{lat=12.8402;lng=77.6652},
  @{lat=12.8408;lng=77.6629}, @{lat=12.8426;lng=77.6622}, @{lat=12.8438;lng=77.6630}, @{lat=12.8442;lng=77.6640}
)

$ok4 = Invoke-Claim -Name 'Banashankari 2nd Stage' -Points @(
  @{lat=12.9253;lng=77.5662}, @{lat=12.9241;lng=77.5685}, @{lat=12.9225;lng=77.5690}, @{lat=12.9218;lng=77.5673},
  @{lat=12.9222;lng=77.5651}, @{lat=12.9239;lng=77.5645}, @{lat=12.9250;lng=77.5653}, @{lat=12.9253;lng=77.5662}
)

$ok5 = Invoke-Claim -Name 'Yelahanka New Town' -Points @(
  @{lat=13.1069;lng=77.5748}, @{lat=13.1055;lng=77.5773}, @{lat=13.1037;lng=77.5779}, @{lat=13.1028;lng=77.5762},
  @{lat=13.1034;lng=77.5738}, @{lat=13.1052;lng=77.5732}, @{lat=13.1064;lng=77.5740}, @{lat=13.1069;lng=77.5748}
)

Write-Host "Done. Success flags: $ok1, $ok2, $ok3, $ok4, $ok5"
