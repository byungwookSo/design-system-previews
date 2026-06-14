# ==========================================================================
# UNDERPACE DESIGN MD TO HTML CONVERTER (PowerShell Enhanced Version)
# ==========================================================================

$baseDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($baseDir)) {
    $baseDir = Get-Location
}

$designMdDir = Join-Path $baseDir "awesome-design-md-main\design-md"
$outputDir = Join-Path $baseDir "previews"

# 회사 로고 도메인 매핑 테이블
$domainMap = @{
    "airbnb" = "airbnb.com"
    "airtable" = "airtable.com"
    "apple" = "apple.com"
    "binance" = "binance.com"
    "bmw-m" = "bmw.de"
    "bmw" = "bmw.de"
    "bugatti" = "bugatti.com"
    "cal" = "cal.com"
    "claude" = "anthropic.com"
    "clay" = "clay.earth"
    "clickhouse" = "clickhouse.com"
    "cohere" = "cohere.com"
    "coinbase" = "coinbase.com"
    "composio" = "composio.dev"
    "cursor" = "cursor.sh"
    "dell-1996" = "dell.com"
    "elevenlabs" = "elevenlabs.io"
    "expo" = "expo.dev"
    "ferrari" = "ferrari.com"
    "figma" = "figma.com"
    "framer" = "framer.com"
    "hashicorp" = "hashicorp.com"
    "hp" = "hp.com"
    "ibm" = "ibm.com"
    "intercom" = "intercom.com"
    "kraken" = "kraken.com"
    "lamborghini" = "lamborghini.com"
    "linear.app" = "linear.app"
    "lovable" = "lovable.dev"
    "mastercard" = "mastercard.com"
    "meta" = "meta.com"
    "minimax" = "minimax.ai"
    "mintlify" = "mintlify.com"
    "miro" = "miro.com"
    "mistral.ai" = "mistral.ai"
    "mongodb" = "mongodb.com"
    "nike" = "nike.com"
    "nintendo-2001" = "nintendo.com"
    "notion" = "notion.so"
    "nvidia" = "nvidia.com"
    "ollama" = "ollama.com"
    "opencode.ai" = "opencode.ai"
    "pinterest" = "pinterest.com"
    "playstation" = "playstation.com"
    "posthog" = "posthog.com"
    "raycast" = "raycast.com"
    "renault" = "renault.com"
    "replicate" = "replicate.com"
    "resend" = "resend.com"
    "revolut" = "revolut.com"
    "runwayml" = "runwayml.com"
    "sanity" = "sanity.io"
    "sentry" = "sentry.io"
    "shopify" = "shopify.com"
    "slack" = "slack.com"
    "spacex" = "spacex.com"
    "spotify" = "spotify.com"
    "starbucks" = "starbucks.com"
    "stripe" = "stripe.com"
    "supabase" = "supabase.com"
    "superhuman" = "superhuman.com"
    "tesla" = "tesla.com"
    "theverge" = "theverge.com"
    "together.ai" = "together.ai"
    "uber" = "uber.com"
    "vercel" = "vercel.com"
    "vodafone" = "vodafone.com"
    "voltagent" = "voltagent.ai"
    "warp" = "warp.dev"
    "webflow" = "webflow.com"
    "wired" = "wired.com"
    "wise" = "wise.com"
    "x.ai" = "x.ai"
    "zapier" = "zapier.com"
}

# 출력 디렉토리 생성
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if (!(Test-Path $designMdDir)) {
    Write-Host "[오류] 디자인 마크다운 폴더를 찾을 수 없습니다: $designMdDir" -ForegroundColor Red
    Exit 1
}

# ── 1. 경량 YAML 파서 함수 (토큰 데이터 카드 시각화) ──
function Convert-YamlToHtml {
    param (
        [string]$YamlContent
    )

    $lines = $YamlContent -split "`r?`n"
    $html = New-Object System.Text.StringBuilder
    
    $currentSection = ""
    $subSection = ""
    $subSectionData = @{}
    
    $html.AppendLine("<div class='yaml-container'>") | Out-Null

    # description 및 최상위 변수들을 모아둘 딕셔너리
    $metaData = @{}
    $colors = @()
    $typography = @()
    $rounded = @()
    $spacing = @()
    $components = @()

    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $trimmed = $line.Trim()
        
        if ([string]::IsNullOrWhiteSpace($line) -or $trimmed -eq "---" -or $trimmed -eq "...") {
            $i++
            continue
        }

        # 들여쓰기 수준 계산 (2칸 또는 4칸 들여쓰기)
        $indent = 0
        if ($line -match "^(\s+)") {
            $indent = $Matches[1].Length
        }

        # ── 최상위 섹션 정의 ──
        if ($indent -eq 0) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):\s*(.*)") {
                $key = $Matches[1].Trim()
                $val = $Matches[2].Trim()
                
                if ($key -eq "colors" -or $key -eq "typography" -or $key -eq "rounded" -or $key -eq "spacing" -or $key -eq "components") {
                    $currentSection = $key
                } else {
                    $currentSection = ""
                    # 따옴표 제거 및 클리닝
                    $val = $val.Trim("`"").Trim("'")
                    $metaData[$key] = $val
                }
            }
            $i++
            continue
        }

        # ── colors 섹션 파싱 ──
        if ($currentSection -eq "colors" -and $indent -gt 0) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):\s*`"?(#[0-9a-fA-F]{3,8}|transparent|rgba?\(.+?\))`"?") {
                $colorName = $Matches[1].Trim()
                $colorValue = $Matches[2].Trim()
                $colors += [PSCustomObject]@{ Name = $colorName; Value = $colorValue }
            }
            $i++
            continue
        }

        # ── rounded 섹션 파싱 ──
        if ($currentSection -eq "rounded" -and $indent -gt 0) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):\s*(.+)") {
                $rounded += [PSCustomObject]@{ Name = $Matches[1].Trim(); Value = $Matches[2].Trim().Trim("`"").Trim("'") }
            }
            $i++
            continue
        }

        # ── spacing 섹션 파싱 ──
        if ($currentSection -eq "spacing" -and $indent -gt 0) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):\s*(.+)") {
                $spacing += [PSCustomObject]@{ Name = $Matches[1].Trim(); Value = $Matches[2].Trim().Trim("`"").Trim("'") }
            }
            $i++
            continue
        }

        # ── typography 섹션 파싱 (중첩 객체) ──
        if ($currentSection -eq "typography" -and $indent -eq 2) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):") {
                $subSection = $Matches[1].Trim()
                $subSectionData = @{}
                
                # 하위 속성들(들여쓰기 4칸 이상) 수집
                $j = $i + 1
                while ($j -lt $lines.Count) {
                    $subLine = $lines[$j]
                    $subTrimmed = $subLine.Trim()
                    if ([string]::IsNullOrWhiteSpace($subLine)) { $j++; continue }
                    
                    $subIndent = 0
                    if ($subLine -match "^(\s+)") { $subIndent = $Matches[1].Length }
                    
                    if ($subIndent -ge 4) {
                        if ($subTrimmed -match "^([a-zA-Z0-9\-_]+):\s*(.+)") {
                            $propKey = $Matches[1].Trim()
                            $propVal = $Matches[2].Trim().Trim("`"").Trim("'")
                            $subSectionData[$propKey] = $propVal
                        }
                        $j++
                    } else {
                        break
                    }
                }
                
                $typography += [PSCustomObject]@{ Name = $subSection; Data = $subSectionData }
                $i = $j
                continue
            }
        }

        # ── components 섹션 파싱 (중첩 객체) ──
        if ($currentSection -eq "components" -and $indent -eq 2) {
            if ($trimmed -match "^([a-zA-Z0-9\-_]+):") {
                $subSection = $Matches[1].Trim()
                $subSectionData = @{}
                
                $j = $i + 1
                while ($j -lt $lines.Count) {
                    $subLine = $lines[$j]
                    $subTrimmed = $subLine.Trim()
                    if ([string]::IsNullOrWhiteSpace($subLine)) { $j++; continue }
                    
                    $subIndent = 0
                    if ($subLine -match "^(\s+)") { $subIndent = $Matches[1].Length }
                    
                    if ($subIndent -ge 4) {
                        if ($subTrimmed -match "^([a-zA-Z0-9\-_]+):\s*(.+)") {
                            $propKey = $Matches[1].Trim()
                            $propVal = $Matches[2].Trim().Trim("`"").Trim("'")
                            $subSectionData[$propKey] = $propVal
                        }
                        $j++
                    } else {
                        break
                    }
                }
                
                $components += [PSCustomObject]@{ Name = $subSection; Data = $subSectionData }
                $i = $j
                continue
            }
        }

        $i++
    }

    # ── HTML 구조 조립 및 렌더링 ──
    
    # 1. 문서 헤더 및 설명 카드 (Description Card)
    if ($metaData.ContainsKey("name")) {
        $html.AppendLine("<h1 class='yaml-title'>$($metaData['name'])</h1>") | Out-Null
    }
    if ($metaData.ContainsKey("version")) {
        $html.AppendLine("<div class='yaml-version-badge'>Version: $($metaData['version'])</div>") | Out-Null
    }
    if ($metaData.ContainsKey("description")) {
        $html.AppendLine("<div class='yaml-card yaml-description-card'>") | Out-Null
        $html.AppendLine("  <h2>시스템 설명 (System Description)</h2>") | Out-Null
        $html.AppendLine("  <p>$($metaData['description'])</p>") | Out-Null
        $html.AppendLine("</div>") | Out-Null
    }

    # 2. 색상표 그리드 렌더링 (Color Palette Grid)
    if ($colors.Count -gt 0) {
        $html.AppendLine("<div class='yaml-section-title'>Color Palette</div>") | Out-Null
        $html.AppendLine("<div class='yaml-color-grid'>") | Out-Null
        foreach ($color in $colors) {
            # 컬러 칩이 투명하거나 투명도 지원
            $bgStyle = $color.Value
            $html.AppendLine("  <div class='yaml-color-card'>") | Out-Null
            $html.AppendLine("    <div class='yaml-color-visual' style='background-color: $bgStyle;'></div>") | Out-Null
            $html.AppendLine("    <div class='yaml-color-info'>") | Out-Null
            $html.AppendLine("      <span class='yaml-color-name'>$($color.Name)</span>") | Out-Null
            $html.AppendLine("      <span class='yaml-color-hex'>$($color.Value)</span>") | Out-Null
            $html.AppendLine("    </div>") | Out-Null
            $html.AppendLine("  </div>") | Out-Null
        }
        $html.AppendLine("</div>") | Out-Null
    }

    # 3. 타이포그래피 카드 렌더링 (Typography Cards)
    if ($typography.Count -gt 0) {
        $html.AppendLine("<div class='yaml-section-title'>Typography Specs</div>") | Out-Null
        $html.AppendLine("<div class='yaml-text-grid'>") | Out-Null
        foreach ($type in $typography) {
            $font = $type.Data["fontFamily"]
            $size = $type.Data["fontSize"]
            $weight = $type.Data["fontWeight"]
            $lh = $type.Data["lineHeight"]
            $ls = $type.Data["letterSpacing"]
            $transform = if ($type.Data.ContainsKey("textTransform")) { $type.Data["textTransform"] } else { "none" }

            $html.AppendLine("  <div class='yaml-text-card'>") | Out-Null
            $html.AppendLine("    <div class='yaml-text-header'>$($type.Name)</div>") | Out-Null
            # 예시 글자 미리보기 렌더링
            $sampleStyle = "font-family: $font; font-size: $size; font-weight: $weight; line-height: $lh; letter-spacing: $ls; text-transform: $transform;"
            $html.AppendLine("    <div class='yaml-text-preview' style='$sampleStyle'>AaBbCc 123 가나다</div>") | Out-Null
            $html.AppendLine("    <div class='yaml-text-details'>") | Out-Null
            if ($font) { $html.AppendLine("      <div class='yaml-text-detail-row'><span class='label'>Font</span><span class='val'>$font</span></div>") | Out-Null }
            if ($size) { $html.AppendLine("      <div class='yaml-text-detail-row'><span class='label'>Size</span><span class='val'>$size</span></div>") | Out-Null }
            if ($weight) { $html.AppendLine("      <div class='yaml-text-detail-row'><span class='label'>Weight</span><span class='val'>$weight</span></div>") | Out-Null }
            if ($lh) { $html.AppendLine("      <div class='yaml-text-detail-row'><span class='label'>Line Height</span><span class='val'>$lh</span></div>") | Out-Null }
            if ($ls) { $html.AppendLine("      <div class='yaml-text-detail-row'><span class='label'>Letter Spacing</span><span class='val'>$ls</span></div>") | Out-Null }
            $html.AppendLine("    </div>") | Out-Null
            $html.AppendLine("  </div>") | Out-Null
        }
        $html.AppendLine("</div>") | Out-Null
    }

    # 4. 둥글기 및 여백 정보 테이블 (Border Radius & Spacing Layouts)
    if ($rounded.Count -gt 0 -or $spacing.Count -gt 0) {
        $html.AppendLine("<div class='yaml-section-title'>Layout & Spacing Tokens</div>") | Out-Null
        $html.AppendLine("<div class='yaml-layout-row'>") | Out-Null
        
        # 둥글기 테이블
        if ($rounded.Count -gt 0) {
            $html.AppendLine("  <div class='yaml-card yaml-layout-card'>") | Out-Null
            $html.AppendLine("    <h3>Border Radius (모서리 둥글기)</h3>") | Out-Null
            $html.AppendLine("    <table>") | Out-Null
            $html.AppendLine("      <thead><tr><th>Token Name</th><th>Radius Value</th><th>Visual Preview</th></tr></thead>") | Out-Null
            $html.AppendLine("      <tbody>") | Out-Null
            foreach ($r in $rounded) {
                # 둥글기 시각화 프리뷰 생성 (풀필이거나 퍼센티지 대응)
                $rVal = $r.Value
                $previewStyle = "border-radius: $rVal;"
                if ($rVal -eq "9999px" -or $rVal -eq "full") { $previewStyle = "border-radius: 20px; width: 60px;" }
                $html.AppendLine("        <tr><td><code>$($r.Name)</code></td><td>$rVal</td><td><div class='radius-preview-block' style='$previewStyle'></div></td></tr>") | Out-Null
            }
            $html.AppendLine("      </tbody>") | Out-Null
            $html.AppendLine("    </table>") | Out-Null
            $html.AppendLine("  </div>") | Out-Null
        }

        # 여백 테이블
        if ($spacing.Count -gt 0) {
            $html.AppendLine("  <div class='yaml-card yaml-layout-card'>") | Out-Null
            $html.AppendLine("    <h3>Spacing & Gaps (여백 규격)</h3>") | Out-Null
            $html.AppendLine("    <table>") | Out-Null
            $html.AppendLine("      <thead><tr><th>Token Name</th><th>Spacing Value</th></tr></thead>") | Out-Null
            $html.AppendLine("      <tbody>") | Out-Null
            foreach ($s in $spacing) {
                $html.AppendLine("        <tr><td><code>$($s.Name)</code></td><td>$($s.Value)</td></tr>") | Out-Null
            }
            $html.AppendLine("      </tbody>") | Out-Null
            $html.AppendLine("    </table>") | Out-Null
            $html.AppendLine("  </div>") | Out-Null
        }
        
        $html.AppendLine("</div>") | Out-Null
    }

    # 5. 컴포넌트 스펙 정보 리스트
    if ($components.Count -gt 0) {
        $html.AppendLine("<div class='yaml-section-title'>Component Specifications</div>") | Out-Null
        $html.AppendLine("<div class='yaml-component-list'>") | Out-Null
        foreach ($comp in $components) {
            $html.AppendLine("  <div class='yaml-card yaml-component-card'>") | Out-Null
            $html.AppendLine("    <h4>$($comp.Name)</h4>") | Out-Null
            $html.AppendLine("    <div class='component-specs-grid'>") | Out-Null
            foreach ($key in $comp.Data.Keys) {
                $html.AppendLine("      <div class='comp-spec-row'><span class='c-label'>$key</span><span class='c-val'>$($comp.Data[$key])</span></div>") | Out-Null
            }
            $html.AppendLine("    </div>") | Out-Null
            $html.AppendLine("  </div>") | Out-Null
        }
        $html.AppendLine("</div>") | Out-Null
    }

    $html.AppendLine("</div>") | Out-Null
    return $html.ToString()
}

# ── 2. 마크다운 파서 함수 ──
function Convert-MarkdownToHtml {
    param (
        [string]$MarkdownContent
    )

    $lines = $MarkdownContent -split "`r?`n"
    $html = New-Object System.Text.StringBuilder
    
    $inCodeBlock = $false
    $inList = $false
    $listType = ""
    $inTable = $false
    $tableHeader = $true

    foreach ($line in $lines) {
        $trimmed = $line.Trim()

        if ($trimmed -like "```*") {
            if ($inCodeBlock) {
                $html.AppendLine("</code></pre>") | Out-Null
                $inCodeBlock = $false
            } else {
                $lang = $trimmed.Substring(3).Trim()
                if ($lang) {
                    $html.AppendLine("<pre><code class=`"language-$lang`">") | Out-Null
                } else {
                    $html.AppendLine("<pre><code>") | Out-Null
                }
                $inCodeBlock = $true
            }
            continue
        }

        if ($inCodeBlock) {
            $escaped = $line.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")
            $html.AppendLine($escaped) | Out-Null
            continue
        }

        if ($trimmed.StartsWith("|") -and $trimmed.EndsWith("|")) {
            if (!$inTable) {
                $inTable = $true
                $tableHeader = $true
                $html.AppendLine("<table>") | Out-Null
            }

            if ($trimmed -match "^\|[\s\-\:\|]+\|$") {
                $tableHeader = $false
                continue
            }

            $cells = $trimmed.Split("|") | Where-Object { $_ -ne "" } | ForEach-Object { $_.Trim() }
            
            $html.Append("  <tr>") | Out-Null
            foreach ($cell in $cells) {
                $parsedCell = Convert-InlineMarkdown $cell
                if ($tableHeader) {
                    $html.Append("<th>$parsedCell</th>") | Out-Null
                } else {
                    $html.Append("<td>$parsedCell</td>") | Out-Null
                }
            }
            $html.AppendLine("</tr>") | Out-Null
            continue
        } else {
            if ($inTable) {
                $html.AppendLine("</table>") | Out-Null
                $inTable = $false
            }
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($inList) {
                $html.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
            $html.AppendLine("<br>") | Out-Null
            continue
        }

        $isUnorderedList = $trimmed -match "^[\*\-\+]\s+(.+)"
        $isOrderedList = $trimmed -match "^\d+\.\s+(.+)"

        if ($isUnorderedList -or $isOrderedList) {
            $currentListType = if ($isUnorderedList) { "ul" } else { "ol" }
            $listContent = if ($isUnorderedList) { $Matches[1] } else { $Matches[1] }
            $parsedContent = Convert-InlineMarkdown $listContent

            if (!$inList) {
                $inList = $true
                $listType = $currentListType
                $html.AppendLine("<$listType>") | Out-Null
            } elseif ($listType -ne $currentListType) {
                $html.AppendLine("</$listType>") | Out-Null
                $listType = $currentListType
                $html.AppendLine("<$listType>") | Out-Null
            }

            $html.AppendLine("  <li>$parsedContent</li>") | Out-Null
            continue
        } else {
            if ($inList) {
                $html.AppendLine("</$listType>") | Out-Null
                $inList = $false
            }
        }

        if ($trimmed -match "^(#+)\s+(.+)") {
            $level = $Matches[1].Length
            $headerText = Convert-InlineMarkdown $Matches[2].Trim()
            $html.AppendLine("<h$level>$headerText</h$level>") | Out-Null
            continue
        }

        if ($trimmed -match "^>\s*(.*)") {
            $quoteText = Convert-InlineMarkdown $Matches[1].Trim()
            $html.AppendLine("<blockquote><p>$quoteText</p></blockquote>") | Out-Null
            continue
        }

        if ($trimmed -match '^(\-{3,}|\*{3,}|_{3,})$') {
            $html.AppendLine("<hr>") | Out-Null
            continue
        }

        $parsedParagraph = Convert-InlineMarkdown $line
        $html.AppendLine("<p>$parsedParagraph</p>") | Out-Null
    }

    if ($inList) { $html.AppendLine("</$listType>") | Out-Null }
    if ($inTable) { $html.AppendLine("</table>") | Out-Null }

    return $html.ToString()
}

# ── 3. 인라인 파서 및 컬러 칩 치환 로직 ──
function Convert-InlineMarkdown {
    param (
        [string]$Text
    )
    
    $t = $Text.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;")

    # A. 굵은 글씨 및 기울임
    $t = [Regex]::Replace($t, '\*\*(.*?)\*\*', '<strong>$1</strong>')
    $t = [Regex]::Replace($t, '__(.*?)__', '<strong>$1</strong>')
    $t = [Regex]::Replace($t, '\*(.*?)\*', '<em>$1</em>')
    $t = [Regex]::Replace($t, '_(.*?)_', '<em>$1</em>')

    # B. 인라인 코드 (`code`)
    $t = [Regex]::Replace($t, '`([^`]+)`', '<code>$1</code>')

    # C. 이미지 및 링크
    $t = [Regex]::Replace($t, '!\[(.*?)\]\((.*?)\)', '<img src="$2" alt="$1" style="max-width:100%;height:auto;">')
    $t = [Regex]::Replace($t, '\[(.*?)\]\((.*?)\)', '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>')

    # D. 컬러 칩 시각화 정규식 (6자리 헥사코드 감지하여 컬러 칩 HTML 추가)
    # 문장 내에 #ff385c 같은 코드가 발견되면 둥근 원형 배지를 옆에 띄워줍니다.
    $t = [Regex]::Replace($t, '(#[0-9a-fA-F]{6})', '<span class="inline-color-chip"><span class="inline-color-dot" style="background-color: $1;"></span>$1</span>')

    return $t
}

# ── 4. HTML 템플릿 정의 (구글 웹 번역 위젯 내장) ──
$HTML_TEMPLATE = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{company_name} — Design System Preview</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Noto+Sans+KR:wght@300;400;500;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <!-- FontAwesome for Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --bg-color: #fcfbfa;
            --text-color: rgba(0, 0, 0, 0.85);
            --text-muted: rgba(0, 0, 0, 0.5);
            --border-color: rgba(0, 0, 0, 0.08);
            --card-bg: #ffffff;
            --code-bg: #1e1e24;
            --code-text: #f8f8f2;
            --accent-color: #0075ff;
            --accent-glow: rgba(0, 117, 255, 0.08);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            font-family: 'Inter', 'Noto Sans KR', sans-serif;
            line-height: 1.8;
            padding: 40px 24px 100px 24px;
            -webkit-font-smoothing: antialiased;
        }

        /* 구글 번역바 커스텀 */
        .goog-te-banner-frame { display: none !important; }
        body { top: 0px !important; }
        .skiptranslate { font-family: 'Inter', sans-serif; }

        .article-container {
            max-width: 800px;
            margin: 0 auto;
            position: relative;
        }

        /* 네비게이션 & 번역 툴바 */
        .header-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 48px;
            gap: 16px;
            flex-wrap: wrap;
        }

        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
            color: var(--text-muted);
            text-decoration: none;
            transition: all 0.2s ease;
            padding: 10px 16px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            background: #ffffff;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }

        .back-link:hover {
            color: var(--accent-color);
            border-color: var(--accent-color);
            background-color: var(--accent-glow);
            transform: translateX(-2px);
        }

        /* 구글 번역기 영역 */
        .translate-wrapper {
            background: #ffffff;
            border: 1px solid var(--border-color);
            padding: 6px 12px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }

        .translate-wrapper i {
            color: var(--accent-color);
        }

        /* ── 마크다운 컨텐츠 스타일링 ── */
        .markdown-body {
            font-size: 16px;
            font-weight: 400;
        }

        .markdown-body h1 {
            font-size: 36px;
            font-weight: 700;
            margin-bottom: 28px;
            line-height: 1.25;
            letter-spacing: -1px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 12px;
        }

        .markdown-body h2 {
            font-size: 24px;
            font-weight: 700;
            margin-top: 48px;
            margin-bottom: 18px;
            line-height: 1.3;
            letter-spacing: -0.5px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 8px;
        }

        .markdown-body h3 {
            font-size: 18px;
            font-weight: 600;
            margin-top: 36px;
            margin-bottom: 12px;
        }

        .markdown-body p {
            margin-bottom: 20px;
        }

        .markdown-body strong {
            font-weight: 600;
        }

        .markdown-body ul, .markdown-body ol {
            margin-bottom: 20px;
            padding-left: 24px;
        }

        .markdown-body li {
            margin-bottom: 8px;
        }

        .markdown-body blockquote {
            border-left: 4px solid var(--accent-color);
            padding: 12px 20px;
            background-color: rgba(0, 0, 0, 0.02);
            color: var(--text-muted);
            font-style: italic;
            margin-bottom: 24px;
            border-radius: 0 6px 6px 0;
        }

        .markdown-body table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 28px;
            font-size: 14px;
        }

        .markdown-body th, .markdown-body td {
            padding: 10px 14px;
            border: 1px solid var(--border-color);
            text-align: left;
        }

        .markdown-body th {
            background-color: rgba(0, 0, 0, 0.02);
            font-weight: 600;
        }

        .markdown-body tr:nth-child(even) {
            background-color: rgba(0, 0, 0, 0.01);
        }

        .markdown-body code {
            font-family: 'JetBrains Mono', monospace;
            font-size: 14px;
            background-color: rgba(0, 0, 0, 0.04);
            padding: 2px 6px;
            border-radius: 4px;
            color: #d63384;
        }

        .markdown-body pre {
            background-color: var(--code-bg);
            color: var(--code-text);
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin-bottom: 24px;
        }

        .markdown-body pre code {
            background-color: transparent;
            padding: 0;
            border-radius: 0;
            color: inherit;
            font-size: 13px;
        }

        .markdown-body hr {
            height: 1px;
            background-color: var(--border-color);
            border: none;
            margin: 40px 0;
        }

        /* ── 인라인 컬러 칩 ── */
        .inline-color-chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(0,0,0,0.03);
            border: 1px solid rgba(0,0,0,0.06);
            padding: 1px 8px;
            border-radius: 4px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            vertical-align: middle;
            margin: 0 4px;
        }

        .inline-color-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
            border: 1px solid rgba(0,0,0,0.15);
            flex-shrink: 0;
        }

        /* ── YAML 토큰 비주얼 카드 스타일 ── */
        .yaml-container {
            display: flex;
            flex-direction: column;
            gap: 32px;
        }

        .yaml-title {
            font-size: clamp(32px, 5vw, 44px);
            font-weight: 800;
            letter-spacing: -1.5px;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 16px;
            text-transform: capitalize;
        }

        .yaml-version-badge {
            align-self: flex-start;
            font-family: var(--font-mono);
            font-size: 12px;
            font-weight: 600;
            color: var(--accent-color);
            background: var(--accent-glow);
            border: 1px solid rgba(0, 117, 255, 0.2);
            padding: 4px 12px;
            border-radius: 50px;
            margin-top: -16px;
        }

        .yaml-card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.02);
        }

        .yaml-description-card h2 {
            font-size: 18px;
            margin-bottom: 12px;
            color: var(--accent-color);
            border: none;
            padding: 0;
            margin-top: 0;
        }

        .yaml-section-title {
            font-size: 22px;
            font-weight: 700;
            margin-top: 24px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 8px;
        }

        /* 컬러 팔레트 그리드 */
        .yaml-color-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
            gap: 16px;
        }

        .yaml-color-card {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }

        .yaml-color-visual {
            height: 100px;
            width: 100%;
            border-bottom: 1px solid var(--border-color);
        }

        .yaml-color-info {
            padding: 12px 14px;
        }

        .yaml-color-name {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-color);
            margin-bottom: 4px;
            word-break: break-all;
        }

        .yaml-color-hex {
            display: block;
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            color: var(--text-muted);
        }

        /* 타이포그래피 */
        .yaml-text-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 20px;
        }

        .yaml-text-card {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }

        .yaml-text-header {
            font-size: 15px;
            font-weight: 700;
            color: var(--accent-color);
            margin-bottom: 12px;
            border-bottom: 1px dashed var(--border-color);
            padding-bottom: 6px;
        }

        .yaml-text-preview {
            padding: 16px 0;
            border-bottom: 1px solid var(--border-color);
            margin-bottom: 12px;
            overflow: hidden;
            white-space: nowrap;
        }

        .yaml-text-details {
            display: flex;
            flex-direction: column;
            gap: 6px;
            font-size: 12px;
        }

        .yaml-text-detail-row {
            display: flex;
            justify-content: space-between;
        }

        .yaml-text-detail-row .label {
            color: var(--text-muted);
        }

        .yaml-text-detail-row .val {
            font-weight: 500;
            text-align: right;
            word-break: break-all;
            max-width: 160px;
        }

        /* 레이아웃 & 테이블 */
        .yaml-layout-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }

        .yaml-layout-card {
            padding: 24px;
        }

        .yaml-layout-card h3 {
            font-size: 16px;
            color: var(--accent-color);
            margin-bottom: 16px;
        }

        .yaml-layout-card table {
            margin-bottom: 0;
        }

        .radius-preview-block {
            width: 40px;
            height: 40px;
            background-color: var(--accent-color);
            border: 1px solid rgba(0,0,0,0.1);
        }

        /* 컴포넌트 리스트 */
        .yaml-component-list {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .yaml-component-card h4 {
            font-size: 15px;
            font-weight: 700;
            color: var(--text-color);
            margin-bottom: 12px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 6px;
        }

        .component-specs-grid {
            display: flex;
            flex-direction: column;
            gap: 8px;
            font-size: 13px;
        }

        .comp-spec-row {
            display: flex;
            justify-content: space-between;
            border-bottom: 1px dashed rgba(0,0,0,0.03);
            padding-bottom: 4px;
        }

        .comp-spec-row .c-label {
            color: var(--text-muted);
        }

        .comp-spec-row .c-val {
            font-family: 'JetBrains Mono', monospace;
            font-weight: 500;
            text-align: right;
        }

        @media (max-width: 768px) {
            body { padding: 30px 16px; }
            .header-bar { flex-direction: column; align-items: stretch; }
            .back-link { justify-content: center; }
            .translate-wrapper { justify-content: center; }
            .yaml-layout-row { grid-template-columns: 1fr; }
            .yaml-component-list { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="article-container">
        <!-- 상단 헤더 툴바 -->
        <div class="header-bar">
            <a href="index.html" class="back-link">
                <i class="fa-solid fa-arrow-left"></i> 전체 목록으로 돌아가기
            </a>
            <!-- 회사 로고 및 이름 -->
            <div class="detail-company-header" style="display: flex; align-items: center; gap: 10px;">
                <img src="https://logo.clearbit.com/{company_domain}" style="width: 32px; height: 32px; border-radius: 6px; object-fit: contain; border: 1px solid var(--border-color); background: white;" onerror="if(this.src.indexOf('clearbit.com')!==-1){this.src='https://www.google.com/s2/favicons?domain={company_domain}&sz=128&default=404';}else{this.style.display='none';}">
                <span style="font-weight: 600; font-size: 16px; text-transform: capitalize;">{company_name}</span>
            </div>
            <!-- 구글 웹 번역기 연동 -->
            <div class="translate-wrapper">
                <i class="fa-solid fa-language"></i>
                <div id="google_translate_element"></div>
            </div>
        </div>

        <!-- 본문 컨텐츠 -->
        <article class="markdown-body">
            {content_html}
        </article>
    </div>

    <!-- 구글 번역 API 스크립트 -->
    <script type="text/javascript">
        function googleTranslateElementInit() {
            new google.translate.TranslateElement({
                pageLanguage: 'en',
                includedLanguages: 'ko,en',
                layout: google.translate.TranslateElement.InlineLayout.SIMPLE
            }, 'google_translate_element');
        }
    </script>
    <script type="text/javascript" src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script>
</body>
</html>
"@

# ── 5. 포털 인덱스 템플릿 정의 (구글 번역 위젯 내장) ──
$INDEX_TEMPLATE = @'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Awesome Design Systems Portal</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800&family=Noto+Sans+KR:wght@300;400;500;700&display=swap" rel="stylesheet">
    <!-- FontAwesome for Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --bg-color: #f7f6f3;
            --card-color: #ffffff;
            --text-primary: rgba(0, 0, 0, 0.85);
            --text-secondary: rgba(0, 0, 0, 0.5);
            --border-color: rgba(0, 0, 0, 0.06);
            --accent-color: #0075ff;
            --accent-hover: #0056c6;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-primary);
            font-family: 'Inter', 'Noto Sans KR', sans-serif;
            padding: 80px 24px 100px 24px;
            -webkit-font-smoothing: antialiased;
        }

        /* 구글 번역바 커스텀 */
        .goog-te-banner-frame { display: none !important; }
        body { top: 0px !important; }
        .skiptranslate { font-family: 'Inter', sans-serif; }

        .portal-container {
            max-width: 1000px;
            margin: 0 auto;
        }

        .portal-header {
            text-align: center;
            margin-bottom: 64px;
            position: relative;
        }

        /* 구글 번역기 상단 고정 */
        .top-translate-bar {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 24px;
        }

        .translate-wrapper {
            background: #ffffff;
            border: 1px solid var(--border-color);
            padding: 6px 12px;
            border-radius: 8px;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
        }

        .translate-wrapper i {
            color: var(--accent-color);
        }

        .portal-title {
            font-size: clamp(32px, 5vw, 48px);
            font-weight: 800;
            letter-spacing: -1.5px;
            line-height: 1.2;
            margin-bottom: 16px;
        }

        .portal-desc {
            font-size: 16px;
            color: var(--text-secondary);
            font-weight: 300;
            margin-bottom: 36px;
        }

        .toolbar {
            display: flex;
            gap: 16px;
            max-width: 600px;
            margin: 0 auto 48px auto;
        }

        .search-wrapper {
            position: relative;
            flex-grow: 1;
        }

        .search-wrapper i {
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
            font-size: 16px;
        }

        .search-input {
            width: 100%;
            padding: 14px 16px 14px 44px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            background-color: var(--card-color);
            font-size: 15px;
            outline: none;
            box-shadow: 0 2px 8px rgba(0,0,0,0.02);
            transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .search-input:focus {
            border-color: var(--accent-color);
            box-shadow: 0 0 0 3px rgba(0, 117, 255, 0.12);
        }

        .btn-shuffle {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 0 24px;
            border-radius: 8px;
            background-color: var(--accent-color);
            color: #ffffff;
            font-weight: 600;
            font-size: 14px;
            border: none;
            cursor: pointer;
            transition: background-color 0.2s ease, transform 0.1s ease;
            box-shadow: 0 2px 8px rgba(0, 117, 255, 0.2);
        }

        .btn-shuffle:hover {
            background-color: var(--accent-hover);
        }

        .btn-shuffle:active {
            transform: scale(0.97);
        }

        .company-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
        }

        .company-card {
            background-color: var(--card-color);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 24px 20px;
            text-align: center;
            text-decoration: none;
            color: inherit;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.02);
            transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), border-color 0.25s, box-shadow 0.25s;
        }

        .company-card:hover {
            transform: translateY(-4px);
            border-color: var(--accent-color);
            box-shadow: 0 8px 24px rgba(0, 117, 255, 0.08);
        }

        .logo-container {
            width: 48px;
            height: 48px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
        }

        .company-logo-img {
            width: 48px;
            height: 48px;
            border-radius: 10px;
            object-fit: contain;
            border: 1px solid var(--border-color);
            background: #ffffff;
            box-shadow: 0 2px 6px rgba(0,0,0,0.03);
            transition: transform 0.2s;
        }

        .company-card:hover .company-logo-img {
            transform: scale(1.05);
            border-color: var(--accent-color);
        }

        .company-logo-badge {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            background-color: var(--bg-color);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            font-weight: 700;
            color: var(--accent-color);
            text-transform: uppercase;
            border: 1px dashed var(--border-color);
            transition: background-color 0.2s;
        }

        .company-card:hover .company-logo-badge {
            background-color: rgba(0, 117, 255, 0.05);
            border-style: solid;
        }

        .company-name {
            font-size: 16px;
            font-weight: 600;
            color: var(--text-primary);
            text-transform: capitalize;
            letter-spacing: -0.3px;
        }

        .no-results {
            text-align: center;
            grid-column: 1 / -1;
            padding: 64px 0;
            color: var(--text-secondary);
            font-size: 15px;
            display: none;
        }

        .no-results i {
            font-size: 32px;
            margin-bottom: 12px;
            display: block;
        }

        @media (max-width: 640px) {
            body { padding: 40px 16px; }
            .portal-header { margin-bottom: 40px; }
            .top-translate-bar { justify-content: center; }
            .toolbar { flex-direction: column; width: 100%; }
            .btn-shuffle { padding: 14px; width: 100%; }
            .company-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
        }
    </style>
    <script type="text/javascript">
        function handleLogoError(img, letter, domain) {
            if (img.src.indexOf('logo.clearbit.com') !== -1) {
                img.src = 'https://www.google.com/s2/favicons?domain=' + domain + '&sz=128&default=404';
            } else {
                const container = img.parentNode;
                container.innerHTML = `<div class="company-logo-badge">${letter}</div>`;
            }
        }
    </script>
</head>
<body>
    <div class="portal-container">
        <!-- 번역 툴바 -->
        <div class="top-translate-bar">
            <div class="translate-wrapper">
                <i class="fa-solid fa-language"></i>
                <div id="google_translate_element"></div>
            </div>
        </div>

        <header class="portal-header">
            <h1 class="portal-title">Awesome Design Systems</h1>
            <p class="portal-desc">글로벌 IT 리테일 기업들의 마크다운 디자인 문서 일괄 변환 미리보기 포털</p>
        </header>

        <main class="company-grid" id="grid">
            {cards_html}
        </main>
    </div>

    <!-- 구글 번역 API 스크립트 -->
    <script type="text/javascript">
        function googleTranslateElementInit() {
            new google.translate.TranslateElement({
                pageLanguage: 'en',
                includedLanguages: 'ko,en',
                layout: google.translate.TranslateElement.InlineLayout.SIMPLE
            }, 'google_translate_element');
        }
    </script>
    <script type="text/javascript" src="//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"></script>

</body>
</html>
'@

# ── 5. 디렉토리 순회 및 파일 변환 실행 ──
$subfolders = Get-ChildItem -Path $designMdDir -Directory | Sort-Object Name
$convertedCompanies = @()

Write-Host "[시스템] 총 $($subfolders.Count)개의 회사 디자인 폴더가 검색되었습니다. 변환을 시작합니다." -ForegroundColor Cyan

foreach ($folder in $subfolders) {
    $folderPath = $folder.FullName
    $folderName = $folder.Name
    
    $mdFile = $null
    $candidates = @("DESIGN.md", "design.md", "README.md", "readme.md")
    
    foreach ($cand in $candidates) {
        $candPath = Join-Path $folderPath $cand
        if (Test-Path $candPath) {
            $mdFile = $candPath
            break
        }
    }
    
    if ($null -eq $mdFile) {
        $otherMds = Get-ChildItem -Path $folderPath -Filter "*.md" -File
        if ($otherMds.Count -gt 0) {
            $mdFile = $otherMds[0].FullName
        }
    }
    
    if ($null -eq $mdFile) {
        continue
    }

    try {
        $mdContent = [System.IO.File]::ReadAllText($mdFile, [System.Text.Encoding]::UTF8)
        $htmlContent = ""

        # A. 문서 포맷 감지: 만약 파일 첫줄이 --- 이거나 전형적인 YAML 구조라면 YAML 카드 렌더러 실행
        if ($mdContent.StartsWith("---") -or ($mdContent -match "^[a-zA-Z0-9\-_]+:\s*")) {
            $htmlContent = Convert-YamlToHtml -YamlContent $mdContent
        } else {
            # B. 일반 마크다운 파서 실행
            $htmlContent = Convert-MarkdownToHtml -MarkdownContent $mdContent
        }
        
        $companyDisplay = $folderName.Replace("-", " ").Replace(".", " ")
        $companyDisplay = (Get-Culture).TextInfo.ToTitleCase($companyDisplay)

        # 도메인 매핑 조회
        $domain = $folderName.ToLower()
        if ($domainMap.ContainsKey($domain)) {
            $domain = $domainMap[$domain]
        } else {
            $domain = "$domain.com"
        }

        $renderedHtml = $HTML_TEMPLATE.Replace("{company_name}", $companyDisplay).Replace("{company_domain}", $domain).Replace("{content_html}", $htmlContent)
        
        $outputFilename = "$folderName.html"
        $outputPath = Join-Path $outputDir $outputFilename
        [System.IO.File]::WriteAllText($outputPath, $renderedHtml, [System.Text.Encoding]::UTF8)

        $convertedCompanies += [PSCustomObject]@{
            Name     = $folderName
            Display  = $companyDisplay
            Filename = $outputFilename
            Domain   = $domain
        }
        
        Write-Host "├─ [성공] $folderName 변환 완료" -ForegroundColor Green
    }
    catch {
        Write-Host "├─ [실패] $folderName 변환 중 오류 발생: $_" -ForegroundColor Red
    }
}

# ── 6. 인덱스 포털 index.html 빌드 ──
$cardsHtml = New-Object System.Text.StringBuilder
foreach ($company in $convertedCompanies) {
    $firstLetter = $company.Display.Substring(0, 1).ToUpper()
    $card = @"
            <a href="$($company.Filename)" class="company-card" data-name="$($company.Name.ToLower())">
                <div class="logo-container">
                    <img class="company-logo-img" src="https://logo.clearbit.com/$($company.Domain)" alt="$($company.Display) logo" onerror="handleLogoError(this, '$firstLetter', '$($company.Domain)')">
                </div>
                <div class="company-name">$($company.Display)</div>
            </a>
"@
    $cardsHtml.AppendLine($card) | Out-Null
}

$renderedIndex = $INDEX_TEMPLATE.Replace("{cards_html}", $cardsHtml.ToString())
$indexPath = Join-Path $outputDir "index.html"
[System.IO.File]::WriteAllText($indexPath, $renderedIndex, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "[완료] 총 $($convertedCompanies.Count)개의 회사 디자인 마크다운 파일 변환이 성공적으로 끝났습니다!" -ForegroundColor Green
Write-Host "[경로] 미리보기 포털 주소: $indexPath" -ForegroundColor Yellow
