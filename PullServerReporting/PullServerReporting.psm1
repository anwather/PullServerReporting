Function Get-DSCNode
{
    [CmdletBinding()]
    Param(
        [int]$MaxEvents)

    $evt = Get-WinEvent -MaxEvents $MaxEvents -FilterHashtable @{ID=4358;LogName="Microsoft-Windows-PowerShell-DesiredStateConfiguration-PullServer/Operational"}

    foreach ($e in $evt)
    {
        $guid = $e.Message.Split(" ")[6]
        if ($agentIDArray -notcontains $guid)
        {
            $agentIDArray += $guid
        }
    }
    
    return $agentIDArray  
}

Function Get-DSCNodeReport
{
    [CmdletBinding()]
    Param(
        
        [string]$PullServer="$env:ComputerName`.$env:UserDNSDomain",

        [ValidateSet("Success","Failure")]
        [string]$Status,

        [ValidateSet("Initial","Consistency")]
        [string]$Type,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$AgentId)

    Begin {
        $requestURI = "https://$PullServer`:8080/PSDSCPullServer.svc/Nodes(AgentId='{0}')/Reports"
        }

    Process {
        $reportArray = @()
        $report = Invoke-WebRequest -Uri ($requestURI -f $_) -UseBasicParsing -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} -Verbose
        $object = ConvertFrom-Json -InputObject $report.Content
        foreach ($o in $object.value)
        {$reportArray += $o}
        
        $test = $PSBoundParameters
        #Write-Host "Blah"

        if ($PSBoundParameters.ContainsKey("Status"))
        {
            $output = $reportArray | Select -ExpandProperty StatusData | ConvertFrom-Json | Where-Object Status -eq $($PSBoundParameters.Status) | Select *
            return $output
        }

        if ($PSBoundParameters.ContainsKey("Type"))
        {
            $output = $reportArray | Select -ExpandProperty StatusData | ConvertFrom-Json | Where-Object Type -eq $($PSBoundParameters.Type) | Select *
            return $output
        }

        $output = $reportArray | Select -ExpandProperty StatusData | ConvertFrom-Json | Select *

        return $output
    }
        
}

Export-ModuleMember -Function *