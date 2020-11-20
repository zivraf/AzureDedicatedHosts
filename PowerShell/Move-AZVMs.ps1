# PowerShell function to move all VMs from one Host to another 
# syntax
# Move-ADHVMs {srcResourceGroup} {srcHostGroup} {srcHostName} {dstResourceGroup} {dstHostGroup} {dstHostName}
# Author: Ziv Rafalovich
Function Move-ADHVMs {
    [cmdletbinding()]
    Param (
        [string]$SourceResourceGroup,
        [string]$SourceHostGroup,
        [string]$SourceHostName,
        [string]$DestResourceGroup,
        [string]$DestHostGroup,       
        [string]$DestHostName
    )
    Process {
        Clear-Host
        Write-Host (get-date).ToString('T') ": Looking for source host"
        $srcHost = Get-AzHost -ResourceGroupName $SourceResourceGroup -HostGroupName $SourceHostGroup -Name $SourceHostName
        if (!$srcHost)
        {
            Write-Host " Source Host was not found .. Exit"
            return
        }
        
        Write-Host (get-date).ToString('T') " Looking for destination host"
        $dstHost = Get-AzHost -ResourceGroupName $DestResourceGroup -HostGroupName $DestHostGroup -Name $DestHostName
        if (!$dstHost)
        {
            Write-Host " Destination Host was not found .. Exit"
            return
        }

        Write-Host (get-date).ToString('T') ": Stoping all VMs"
        foreach ($vm in $srcHost.VirtualMachines) 
        {
            Write-Host "Iterate VM: " $vm.Id
            $strToken=$vm.Id.split("/")
            Write-Host "Stop VM: -ResourceGroupName " $strToken[4] " -name " $strToken[8]
            Stop-AzVM -ResourceGroupName $strToken[4] -name $strToken[8] -Force -AsJob
        }
        Write-Host (get-date).ToString('T') ": Waiting for all jobs to complete"
        Get-Job | Wait-Job -Timeout 180
        Get-Job | Remove-Job

        Write-Host (get-date).ToString('T') ": Moving all VMs"
        foreach ($vm in $srcHost.VirtualMachines) 
        {
            Write-Host "Iterate VM: " $vm.Id
            $strToken=$vm.Id.split("/")
            $currVM = Get-AzVM -ResourceGroupName $strToken[4] -name $strToken[8] 
            $currVM.Host = New-Object Microsoft.Azure.Management.Compute.Models.SubResource
            $currVM.Host.Id = $dstHost.Id
            Update-AzVM -ResourceGroupName $strToken[4] -VM $currVM -AsJob           
            
        }
        Write-Host (get-date).ToString('T') ": Waiting for all jobs to complete"

        Get-Job | Wait-Job -Timeout 180
        Get-Job | Remove-Job
        
        Write-Host (get-date).ToString('T') ": Starting all VMs"
        
        foreach ($vm in $srcHost.VirtualMachines) 
        {
            Write-Host "Iterate VM: " $vm.Id
            $strToken=$vm.Id.split("/")
            Start-AzVM -ResourceGroupName $strToken[4] -name $strToken[8] -AsJob            
        }

        Write-Host (get-date).ToString('T') ": Waiting for all jobs to complete"

        Get-Job | Wait-Job -Timeout 240
        Get-Job | Remove-Job

        Write-Host (get-date).ToString('T') ": All jobs have been completed"

    }
}

# syntax
# Move-ADHVMs {srcResourceGroup} {srcHostGroup} {srcHostName} {dstResourceGroup} {dstHostGroup} {dstHostName}
