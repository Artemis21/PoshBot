
function Help {
    <#
    .SYNOPSIS
        List bot commands
    .EXAMPLE
        !help mycommand
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [string]$Filter
    )

    #Write-Output ($bot | format-list | out-string)

    $availableCommands = New-Object System.Collections.ArrayList
    foreach ($pluginKey in $Bot.PluginManager.Plugins.Keys) {
        $plugin = $Bot.PluginManager.Plugins[$pluginKey]
        foreach ($commandKey in $plugin.Commands.Keys) {
            $command = $plugin.Commands[$commandKey]
            $x = [pscustomobject][ordered]@{
                Command = "$pluginKey`:$CommandKey"
                #Plugin = $pluginKey
                #Name = $commandKey
                Description = $command.Description
                HelpText = $command.HelpText
            }
            $availableCommands.Add($x) | Out-Null
        }
    }

    # If we asked for help about a particular plugin or command, filter on it
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $availableCommands = $availableCommands.Where({($_.Plugin -like $Filter) -or ($_.Name -like $Filter)})
    }

    Write-Output ($availableCommands | Format-Table -AutoSize | Out-String -Width 150)
}

function Status {
    <#
    .SYNOPSIS
        Get Bot status
    .EXAMPLE
        !status
    #>
    param(
        [parameter(Mandatory)]
        $Bot
    )

    if ($Bot._Stopwatch.IsRunning) {
        $uptime = $Bot._Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $hash = [ordered]@{
        Version = '1.0.0'
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
    }

    $status = [pscustomobject]$hash
    $status
}

function Roles {
    <#
    .SYNOPSIS
        Get all roles
    .EXAMPLE
        !roles
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $roles = foreach ($key in ($Bot.RoleManager.Roles.Keys | Sort-Object)) {
        [pscustomobject][ordered]@{
            Name = $key
            Description =$Bot.RoleManager.Roles[$key].Description
        }
    }
    Write-Output ($roles | Format-Table -AutoSize | Out-String -Width 150)
}

function RoleShow {
    <#
    .SYNOPSIS
        Show details about a role
    .EXAMPLE
        !roleshow --role <rolename>
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Role
    )

    $r = $Bot.RoleManager.GetRole($Role)
    if (-not $r) {
        Write-Error "Role [$Role] not found :("
        return
    }
    $roleMapping = $Bot.RoleManager.RoleUserMapping[$Role]
    $members = New-Object System.Collections.ArrayList
    if ($roleMapping) {
        $roleMapping.Users.GetEnumerator() | ForEach-Object {
            $m = [pscustomobject][ordered]@{
                ID = $_.Name
                Name = $_.Value.Nickname
            }
            $members.Add($m) | Out-Null
        }
    }

    Write-Output "Role details for [$Role]"
    Write-Output "Description: $($r.Description)"
    Write-Output "Members:`n$($Members | Format-Table | Out-String)"
}

function AddUserToRole {
    <#
    .SYNOPSIS
        Add a user to a role
    .EXAMPLE
        !roleadd --role <rolename> --user <username>
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Role,

        [parameter(Mandatory)]
        [string]$User
    )

    # Validate role and username
    $id = $Bot.RoleManager.ResolveUserToId($User)
    if (-not $id) {
        throw "Username [$User] was not found."
    }
    $r = $Bot.RoleManager.GetRole($Role)
    if (-not $r) {
        throw "Username [$User] was not found."
    }

    try {
        $Bot.RoleManager.AddUserToRole($id, $Role)
        Write-Output "OK, user [$User] added to role [$Role]"
    } catch {
        throw $_
    }
}

function Plugins {
  <#
    .SYNOPSIS
        Get all installed plugins
    .EXAMPLE
        !plugins
    .ROLE
        Admin
        PluginAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $plugins = foreach ($key in ($Bot.PluginManager.Plugins.Keys | Sort-Object)) {
        $plugin = $Bot.PluginManager.Plugins[$key]
        [pscustomobject][ordered]@{
            Name = $key
            Commands = $plugin.Commands.Keys
            Roles = $plugin.Roles.Keys
            Enabled = $plugin.Enabled
        }
    }
    Write-Output ($plugins | Format-List | Out-String -Width 150)
}

function About {
    [cmdletbinding()]
    param()

    $path = "$PSScriptRoot/../../PoshBot.psd1"
    #$manifest = Test-ModuleManifest -Path $path -Verbose:$false
    $manifest = Import-PowerShellDataFile -Path $path
    $ver = $manifest.ModuleVersion

    $msg = @"
PoshBot v$ver
$($manifest.CopyRight)

https://github.com/devblackops/PoshBot
"@
    $msg
}

Export-ModuleMember -Function *
