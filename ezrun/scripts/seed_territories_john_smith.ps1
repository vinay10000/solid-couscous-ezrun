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

# 5 territories around Bangalore landmarks
$ok1 = Invoke-Claim -Name 'Cubbon Park' -Points @(
  @{lat=12.9766;lng=77.5911}, @{lat=12.9755;lng=77.5923}, @{lat=12.9757;lng=77.5943}, @{lat=12.9767;lng=77.5952},
  @{lat=12.9779;lng=77.5948}, @{lat=12.9782;lng=77.5931}, @{lat=12.9776;lng=77.5917}, @{lat=12.9766;lng=77.5911}
)

$ok2 = Invoke-Claim -Name 'Lalbagh Botanical Garden' -Points @(
  @{lat=12.9506;lng=77.5832}, @{lat=12.9496;lng=77.5847}, @{lat=12.9499;lng=77.5862}, @{lat=12.9509;lng=77.5871},
  @{lat=12.9521;lng=77.5867}, @{lat=12.9524;lng=77.5851}, @{lat=12.9517;lng=77.5838}, @{lat=12.9506;lng=77.5832}
)

$ok3 = Invoke-Claim -Name 'Indiranagar 100ft Road (Toit area)' -Points @(
  @{lat=12.9781;lng=77.6394}, @{lat=12.9772;lng=77.6405}, @{lat=12.9774;lng=77.6423}, @{lat=12.9784;lng=77.6431},
  @{lat=12.9796;lng=77.6427}, @{lat=12.9799;lng=77.6410}, @{lat=12.9791;lng=77.6399}, @{lat=12.9781;lng=77.6394}
)

$ok4 = Invoke-Claim -Name 'Koramangala 5th Block (Forum area)' -Points @(
  @{lat=12.9342;lng=77.6096}, @{lat=12.9332;lng=77.6107}, @{lat=12.9334;lng=77.6124}, @{lat=12.9344;lng=77.6132},
  @{lat=12.9356;lng=77.6128}, @{lat=12.9359;lng=77.6111}, @{lat=12.9350;lng=77.6100}, @{lat=12.9342;lng=77.6096}
)

$ok5 = Invoke-Claim -Name 'Bellandur (RMZ Ecospace)' -Points @(
  @{lat=12.9232;lng=77.6873}, @{lat=12.9223;lng=77.6886}, @{lat=12.9225;lng=77.6903}, @{lat=12.9236;lng=77.6912},
  @{lat=12.9248;lng=77.6907}, @{lat=12.9251;lng=77.6890}, @{lat=12.9243;lng=77.6879}, @{lat=12.9232;lng=77.6873}
)

Write-Host "Done. Success flags: $ok1, $ok2, $ok3, $ok4, $ok5"
