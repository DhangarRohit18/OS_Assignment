# PowerShell script to remove comments from source code files
# Supports C/C++ and Python files

param(
    [string]$RootPath = "e:\Operating Sysytem\final pr"
)

# Function to remove C/C++ comments
function Remove-CppComments {
    param([string]$Content)
    
    # Remove single-line comments (//)
    $Content = $Content -replace '//.*$', '' -split "`n" | ForEach-Object { $_ } | Join-String -Separator "`n"
    
    # Remove multi-line comments (/* ... */)
    $Content = $Content -replace '/\*(?:.|\n)*?\*/', ''
    
    return $Content
}

# Function to remove Python comments
function Remove-PythonComments {
    param([string]$Content)
    
    # Split into lines to handle # comments (but not in strings)
    $lines = $Content -split "`n"
    $processedLines = @()
    
    foreach ($line in $lines) {
        # Simple approach: remove # and everything after it
        # This is a basic implementation that removes # comments
        if ($line -match '#') {
            # Find the position of # that's not in a string
            $result = ""
            $inSingleQuote = $false
            $inDoubleQuote = $false
            $i = 0
            while ($i -lt $line.Length) {
                $char = $line[$i]
                if ($char -eq '"' -and (-not $inSingleQuote)) {
                    $inDoubleQuote = -not $inDoubleQuote
                    $result += $char
                } elseif ($char -eq "'" -and (-not $inDoubleQuote)) {
                    $inSingleQuote = -not $inSingleQuote
                    $result += $char
                } elseif ($char -eq '#' -and (-not $inSingleQuote) -and (-not $inDoubleQuote)) {
                    break
                } else {
                    $result += $char
                }
                $i++
            }
            $processedLines += $result.TrimEnd()
        } else {
            $processedLines += $line
        }
    }
    
    return ($processedLines -join "`n")
}

# Function to clean up extra blank lines
function Clean-BlankLines {
    param([string]$Content)
    
    # Replace multiple consecutive blank lines with a single blank line
    $Content = $Content -replace '(\r?\n\s*){3,}', "`n`n"
    
    # Remove blank lines at the start and end
    $Content = $Content -replace '^\s*\n+', ''
    $Content = $Content -replace '\n+\s*$', ''
    
    return $Content
}

# Main execution
Write-Host "Starting comment removal process..." -ForegroundColor Green
Write-Host "Root path: $RootPath`n" -ForegroundColor Cyan

$processedFiles = @()
$errorFiles = @()

# Get all files, excluding .git directory
$files = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object { $_.FullName -notmatch '\.git' }

foreach ($file in $files) {
    $extension = $file.Extension.ToLower()
    
    # Process C/C++ files
    if ($extension -in @('.c', '.cpp', '.cc', '.cxx', '.h', '.hpp', '.hxx')) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            $modified = Remove-CppComments -Content $content
            $modified = Clean-BlankLines -Content $modified
            Set-Content -Path $file.FullName -Value $modified -Encoding UTF8 -NoNewline
            $processedFiles += $file.FullName
            Write-Host "[C/C++] Processed: $($file.FullName)" -ForegroundColor Green
        } catch {
            $errorFiles += @{ File = $file.FullName; Error = $_.Exception.Message }
            Write-Host "[ERROR] Failed to process: $($file.FullName)" -ForegroundColor Red
        }
    }
    # Process Python files
    elseif ($extension -eq '.py') {
        try {
            $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            $modified = Remove-PythonComments -Content $content
            $modified = Clean-BlankLines -Content $modified
            Set-Content -Path $file.FullName -Value $modified -Encoding UTF8 -NoNewline
            $processedFiles += $file.FullName
            Write-Host "[Python] Processed: $($file.FullName)" -ForegroundColor Green
        } catch {
            $errorFiles += @{ File = $file.FullName; Error = $_.Exception.Message }
            Write-Host "[ERROR] Failed to process: $($file.FullName)" -ForegroundColor Red
        }
    }
}

# Print summary
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Yellow
Write-Host "Files processed: $($processedFiles.Count)" -ForegroundColor Cyan
Write-Host "Errors encountered: $($errorFiles.Count)" -ForegroundColor Cyan

if ($processedFiles.Count -gt 0) {
    Write-Host "`nProcessed files:" -ForegroundColor Yellow
    $processedFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

if ($errorFiles.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $errorFiles | ForEach-Object { Write-Host "  - $($_.File): $($_.Error)" -ForegroundColor Red }
}

Write-Host "`nComment removal completed!" -ForegroundColor Green
