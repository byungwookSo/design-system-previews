$path = Join-Path $PSScriptRoot "convert.ps1"
if (Test-Path $path) {
    # BOM 없는 UTF-8로 읽어서 메모리에 적재
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($path, $utf8NoBOM)
    
    # BOM이 포함된 UTF-8로 다시 저장 (.NET 기본 WriteAllText는 UTF-8 BOM 사용)
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "[인코딩 수정 완료] convert.ps1 파일이 UTF-8 BOM 형식으로 재저장되었습니다." -ForegroundColor Green
} else {
    Write-Host "[오류] convert.ps1 파일을 찾을 수 없습니다." -ForegroundColor Red
}
