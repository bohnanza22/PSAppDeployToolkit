# PSAppDeployToolkit default rules for PSScriptAnalyser, to ensure compatibility with PowerSHell 3.0
@{
    Severity     = @(
        'Error',
        'Warning'
    );
    IncludeRules = @(
        'PSAvoidDefaultValueSwitchParameter',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSAvoidUsingCmdletAliases',
        'PSUseDeclaredVarsMoreThanAssignments'
        );
    ExcludeRules = @(
        'PSUseDeclaredVarsMoreThanAssigments'
    );
    Rules        = @{
        PSUseCompatibleCmdlets = @{
            Compatibility = @('desktop-3.0-windows')
        };
    }
}
