Function Get-DSCNode
{
    [CmdletBinding()]
    Param(
        [string]$PullServer)

    $evt = Get-WinEvent -MaxEvents 100 -FilterHashtable @{ID=4358;LogName="Microsoft-Windows-PowerShell-DesiredStateConfiguration-PullServer/Operational"}

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
        [string]$PullServer,
        [string]$AgentId)

        $requestURI = "https://$PullServer`:8080/PSDSCPullServer.svc/Nodes(AgentId='{0}')/Reports"

        $reportArray = @()
        $report = Invoke-WebRequest -Uri ($requestURI -f $AgentId) -UseBasicParsing -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} -Verbose
        $object = ConvertFrom-Json -InputObject $report.Content
        foreach ($o in $object.value)
        {$reportArray += $o}

        $output = $reportArray | Select -ExpandProperty StatusData | ConvertFrom-Json | Select *

        return $output
}

Export-ModuleMember -Function *