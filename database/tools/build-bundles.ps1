param([switch]$Check)
$ErrorActionPreference = 'Stop'
# Only assembles local SQL text. Does not connect to or modify any database.
$databaseRoot = Split-Path -Parent $PSScriptRoot
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
$moduleFiles = @(Get-ChildItem -LiteralPath (Join-Path $databaseRoot 'modules') -Filter '*.sql' | Sort-Object Name)
$testFiles = @(Get-ChildItem -LiteralPath (Join-Path $databaseRoot 'tests') -Filter '*.sql' | Sort-Object Name)
if ($moduleFiles.Count -ne 8 -or $testFiles.Count -eq 0) { throw 'Expected eight modules and test sources.' }
$install = "-- GENERATED: edit modules/*.sql or 90_seed.sql, then run tools/build-bundles.ps1.`n-- SSMS: execute this entire file; SQLCMD mode is not required.`n"
foreach ($file in $moduleFiles) {
    $install += "`n-- SOURCE: modules/$($file.Name)`n" + [IO.File]::ReadAllText($file.FullName) + "`n"
}
$install += "`n-- SOURCE: 90_seed.sql`n" + [IO.File]::ReadAllText((Join-Path $databaseRoot '90_seed.sql')) + "`n"
$install += "PRINT N'INSTALL COMPLETE';`nGO`n"
# Execute test batches inside one TRY/CATCH. SSMS must not print ALL TESTS
# PASSED after an earlier batch failed and the client continued past GO.
$acceptance = "-- GENERATED: edit tests/*.sql, then run tools/build-bundles.ps1.`n-- Requires a complete installation and the unchanged demo baseline.`nUSE OnlineEducationSQL;`nGO`nSET NOCOUNT ON;`nSET XACT_ABORT ON;`nBEGIN TRY`n"
foreach ($file in $testFiles) {
    $acceptance += " -- SOURCE: tests/$($file.Name)`n"
    $batches = [regex]::Split([IO.File]::ReadAllText($file.FullName), '(?im)^GO[ 	]*?$')
    foreach ($batch in $batches) {
        if ($batch.Trim().Length -eq 0) { continue }
        $escaped = $batch.Trim().Replace("'", "''")
        $acceptance += " EXEC sys.sp_executesql N'$escaped';`n"
    }
}
$acceptance += " PRINT N'ALL TESTS PASSED';`nEND TRY`nBEGIN CATCH`n IF @@TRANCOUNT>0 ROLLBACK;`n THROW;`nEND CATCH;`nGO`n"
foreach ($entry in @(@{Name='00_install.sql'; Text=$install}, @{Name='92_acceptance.sql'; Text=$acceptance})) {
    $target = Join-Path $databaseRoot $entry.Name
    if ($Check) {
        if (-not (Test-Path -LiteralPath $target) -or [IO.File]::ReadAllText($target) -cne $entry.Text) {
            throw "Bundle is out of date: $($entry.Name)"
        }
    } else {
        [IO.File]::WriteAllText($target, $entry.Text, $utf8Bom)
    }
}
if ($Check) { Write-Output 'SQL bundles are synchronized.' }
else { Write-Output 'Generated 00_install.sql and 92_acceptance.sql.' }
