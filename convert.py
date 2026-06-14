import os
import sys
import subprocess
import glob
import re

# ── 1. 필수 라이브러리 자동 설치 로직 ──
try:
    import markdown
except ImportError:
    print("[시스템] 'markdown' 라이브러리가 필요합니다. 자동 설치를 시작합니다...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "markdown"])
        import markdown
        print("[시스템] 라이브러리 설치 성공!")
    except Exception as e:
        print(f"[오류] 라이브러리 자동 설치 실패: {e}")
        print("[조치] 터미널에 'pip install markdown'을 실행해 주세요.")
        sys.exit(1)

# ── 2. 경로 설정 ──
# 스크립트 파일이 위치한 폴더 기준
base_dir = os.path.dirname(os.path.abspath(__file__))
design_md_dir = os.path.join(base_dir, "awesome-design-md-main", "design-md")
output_dir = os.path.join(base_dir, "previews")

# 출력 폴더 생성
os.makedirs(output_dir, exist_ok=True)

# ── 3. HTML 템플릿 정의 (CSS 내장) ──
HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{company_name} — Design System Preview</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Noto+Sans+KR:wght@300;400;500;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {{
            --bg-color: #fcfbfa;
            --text-color: rgba(0, 0, 0, 0.85);
            --text-muted: rgba(0, 0, 0, 0.5);
            --border-color: rgba(0, 0, 0, 0.08);
            --code-bg: #1e1e24;
            --code-text: #f8f8f2;
            --accent-color: #0075ff;
            --accent-glow: rgba(0, 117, 255, 0.08);
        }}

        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            background-color: var(--bg-color);
            color: var(--text-color);
            font-family: 'Inter', 'Noto Sans KR', sans-serif;
            line-height: 1.8;
            padding: 60px 24px 100px 24px;
            -webkit-font-smoothing: antialiased;
        }}

        /* ── 본문 레이아웃 ── */
        .article-container {{
            max-width: 760px;
            margin: 0 auto;
            position: relative;
        }}

        /* ── 뒤로가기 헤더 ── */
        .back-nav {{
            margin-bottom: 48px;
        }}

        .back-link {{
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
            color: var(--text-muted);
            text-decoration: none;
            transition: color 0.2s ease;
            padding: 8px 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background: #ffffff;
        }}

        .back-link:hover {{
            color: var(--accent-color);
            border-color: var(--accent-color);
            background-color: var(--accent-glow);
        }}

        /* ── 마크다운 컨텐츠 스타일링 (Typography) ── */
        .markdown-body {{
            font-size: 16px;
            font-weight: 400;
        }}

        .markdown-body h1 {{
            font-size: 36px;
            font-weight: 700;
            margin-bottom: 28px;
            line-height: 1.25;
            letter-spacing: -1px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 12px;
        }}

        .markdown-body h2 {{
            font-size: 24px;
            font-weight: 700;
            margin-top: 48px;
            margin-bottom: 18px;
            line-height: 1.3;
            letter-spacing: -0.5px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 8px;
        }}

        .markdown-body h3 {{
            font-size: 18px;
            font-weight: 600;
            margin-top: 36px;
            margin-bottom: 12px;
        }}

        .markdown-body p {{
            margin-bottom: 20px;
            color: var(--text-color);
        }}

        .markdown-body strong {{
            font-weight: 600;
        }}

        /* 리스트 */
        .markdown-body ul, .markdown-body ol {{
            margin-bottom: 20px;
            padding-left: 24px;
        }}

        .markdown-body li {{
            margin-bottom: 8px;
        }}

        .markdown-body li p {{
            margin-bottom: 0;
        }}

        /* 인용구 */
        .markdown-body blockquote {{
            border-left: 4px solid var(--accent-color);
            padding: 12px 20px;
            background-color: rgba(0, 0, 0, 0.02);
            color: var(--text-muted);
            font-style: italic;
            margin-bottom: 24px;
            border-radius: 0 6px 6px 0;
        }}

        .markdown-body blockquote p {{
            margin-bottom: 0;
        }}

        /* 테이블 */
        .markdown-body table {{
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 28px;
            font-size: 14px;
            line-height: 1.5;
        }}

        .markdown-body th, .markdown-body td {{
            padding: 10px 14px;
            border: 1px solid var(--border-color);
            text-align: left;
        }}

        .markdown-body th {{
            background-color: rgba(0, 0, 0, 0.02);
            font-weight: 600;
        }}

        .markdown-body tr:nth-child(even) {{
            background-color: rgba(0, 0, 0, 0.01);
        }}

        /* 코드 및 모노스페이스 */
        .markdown-body code {{
            font-family: 'JetBrains Mono', monospace;
            font-size: 14px;
            background-color: rgba(0, 0, 0, 0.04);
            padding: 2px 6px;
            border-radius: 4px;
            color: #d63384; /* 가독성 높은 핑크색 */
        }}

        .markdown-body pre {{
            background-color: var(--code-bg);
            color: var(--code-text);
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin-bottom: 24px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }}

        .markdown-body pre code {{
            background-color: transparent;
            padding: 0;
            border-radius: 0;
            color: inherit;
            font-size: 13px;
        }}

        /* 구분선 */
        .markdown-body hr {{
            height: 1px;
            background-color: var(--border-color);
            border: none;
            margin: 40px 0;
        }}

        /* ── 반응형 ── */
        @media (max-width: 640px) {{
            body {{
                padding: 40px 16px 80px 16px;
            }}
            .markdown-body h1 {{ font-size: 28px; }}
            .markdown-body h2 {{ font-size: 20px; margin-top: 36px; }}
            .markdown-body table {{ display: block; overflow-x: auto; }}
        }}
    </style>
</head>
<body>
    <div class="article-container">
        <!-- 네비게이션 -->
        <div class="back-nav">
            <a href="index.html" class="back-link">
                ← 전체 목록으로 돌아가기
            </a>
        </div>

        <!-- 본문 컨텐츠 -->
        <article class="markdown-body">
            {content_html}
        </article>
    </div>
</body>
</html>
"""

# ── 4. 인덱스 포털 템플릿 정의 (CSS & 실시간 검색 JS 내장) ──
INDEX_TEMPLATE = """<!DOCTYPE html>
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
        :root {{
            --bg-color: #f7f6f3;
            --card-color: #ffffff;
            --text-primary: rgba(0, 0, 0, 0.85);
            --text-secondary: rgba(0, 0, 0, 0.5);
            --border-color: rgba(0, 0, 0, 0.06);
            --accent-color: #0075ff;
            --accent-hover: #0056c6;
        }}

        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            background-color: var(--bg-color);
            color: var(--text-primary);
            font-family: 'Inter', 'Noto Sans KR', sans-serif;
            padding: 80px 24px 100px 24px;
            -webkit-font-smoothing: antialiased;
        }}

        .portal-container {{
            max-width: 1000px;
            margin: 0 auto;
        }}

        /* ── 헤더 영역 ── */
        .portal-header {{
            text-align: center;
            margin-bottom: 64px;
        }}

        .portal-title {{
            font-size: clamp(32px, 5vw, 48px);
            font-weight: 800;
            letter-spacing: -1.5px;
            line-height: 1.2;
            margin-bottom: 16px;
        }}

        .portal-desc {{
            font-size: 16px;
            color: var(--text-secondary);
            font-weight: 300;
            margin-bottom: 36px;
        }}

        /* ── 검색 및 액션 툴바 ── */
        .toolbar {{
            display: flex;
            gap: 16px;
            max-width: 600px;
            margin: 0 auto 48px auto;
        }}

        .search-wrapper {{
            position: relative;
            flex-grow: 1;
        }}

        .search-wrapper i {{
            position: absolute;
            left: 16px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
            font-size: 16px;
        }}

        .search-input {{
            width: 100%;
            padding: 14px 16px 14px 44px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            background-color: var(--card-color);
            font-size: 15px;
            outline: none;
            box-shadow: 0 2px 8px rgba(0,0,0,0.02);
            transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }}

        .search-input:focus {{
            border-color: var(--accent-color);
            box-shadow: 0 0 0 3px rgba(0, 117, 255, 0.12);
        }}

        .btn-shuffle {{
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
        }}

        .btn-shuffle:hover {{
            background-color: var(--accent-hover);
        }}

        .btn-shuffle:active {{
            transform: scale(0.97);
        }}

        /* ── 카드 리스트 그리드 ── */
        .company-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
        }}

        .company-card {{
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
        }}

        .company-card:hover {{
            transform: translateY(-4px);
            border-color: var(--accent-color);
            box-shadow: 0 8px 24px rgba(0, 117, 255, 0.08);
        }}

        .company-logo-badge {{
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
            margin-bottom: 16px;
            text-transform: uppercase;
            border: 1px dashed var(--border-color);
            transition: background-color 0.2s;
        }}

        .company-card:hover .company-logo-badge {{
            background-color: rgba(0, 117, 255, 0.05);
            border-style: solid;
        }}

        .company-name {{
            font-size: 16px;
            font-weight: 600;
            color: var(--text-primary);
            text-transform: capitalize;
            letter-spacing: -0.3px;
        }}

        /* ── 매치 안되는 검색 결과 ── */
        .no-results {{
            text-align: center;
            grid-column: 1 / -1;
            padding: 64px 0;
            color: var(--text-secondary);
            font-size: 15px;
            display: none;
        }}

        .no-results i {{
            font-size: 32px;
            margin-bottom: 12px;
            display: block;
        }}

        /* ── 반응형 ── */
        @media (max-width: 640px) {{
            body {{ padding: 40px 16px; }}
            .portal-header {{ margin-bottom: 40px; }}
            .toolbar {{ flex-direction: column; width: 100%; }}
            .btn-shuffle {{ padding: 14px; width: 100%; }}
            .company-grid {{ grid-template-columns: repeat(2, 1fr); gap: 12px; }}
        }}
    </style>
</head>
<body>
    <div class="portal-container">
        <header class="portal-header">
            <h1 class="portal-title">Awesome Design Systems</h1>
            <p class="portal-desc">글로벌 IT 리테일 기업들의 마크다운 디자인 문서 일괄 변환 미리보기 포털</p>
            
            <div class="toolbar">
                <div class="search-wrapper">
                    <i class="fa-solid fa-magnifying-glass"></i>
                    <input type="text" id="search" class="search-input" placeholder="회사명 검색...">
                </div>
                <button id="shuffle" class="btn-shuffle">
                    <i class="fa-solid fa-shuffle"></i> 랜덤 탐색
                </button>
            </div>
        </header>

        <main class="company-grid" id="grid">
            {cards_html}
            
            <div class="no-results" id="no-results">
                <i class="fa-regular fa-face-frown"></i>
                검색 결과와 일치하는 회사가 없습니다.
            </div>
        </main>
    </div>

    <!-- ── 실시간 검색 및 랜덤 이동 기능 스크립트 ── -->
    <script>
        const searchInput = document.getElementById('search');
        const grid = document.getElementById('grid');
        const cards = Array.from(grid.getElementsByClassName('company-card'));
        const noResults = document.getElementById('no-results');
        const shuffleBtn = document.getElementById('shuffle');

        // 1. 실시간 검색 필터링
        searchInput.addEventListener('input', (e) => {{
            const query = e.target.value.toLowerCase().trim();
            let visibleCount = 0;

            cards.forEach(card => {{
                const name = card.getAttribute('data-name');
                if (name.includes(query)) {{
                    card.style.display = 'flex';
                    visibleCount++;
                }} else {{
                    card.style.display = 'none';
                }}
            }});

            if (visibleCount === 0) {{
                noResults.style.display = 'block';
            }} else {{
                noResults.style.display = 'none';
            }}
        }});

        // 2. 랜덤 탐색 이동
        shuffleBtn.addEventListener('click', () => {{
            const visibleCards = cards.filter(card => card.style.display !== 'none');
            if (visibleCards.length > 0) {{
                const randomIndex = Math.floor(Math.random() * visibleCards.length);
                const targetUrl = visibleCards[randomIndex].getAttribute('href');
                window.location.href = targetUrl;
            }}
        }});
    </script>
</body>
</html>
"""

# ── 5. 변환 로직 실행 ──
def main():
    if not os.path.exists(design_md_dir):
        print(f"[오류] 디자인 마크다운 폴더를 찾을 수 없습니다: {design_md_dir}")
        sys.exit(1)

    # design-md 하위의 모든 폴더 리스트
    subfolders = [f for f in os.listdir(design_md_dir) if os.path.isdir(os.path.join(design_md_dir, f))]
    subfolders.sort()

    converted_companies = []

    print(f"[시스템] 총 {len(subfolders)}개의 회사 디자인 폴더가 검색되었습니다. 변환을 시작합니다.")

    for folder_name in subfolders:
        folder_path = os.path.join(design_md_dir, folder_name)
        
        # md 파일 검색 우선순위 정의 (DESIGN.md ➔ design.md ➔ README.md ➔ 다른 md 파일)
        md_file = None
        candidates = ["DESIGN.md", "design.md", "README.md", "readme.md"]
        
        for cand in candidates:
            cand_path = os.path.join(folder_path, cand)
            if os.path.exists(cand_path):
                md_file = cand_path
                break
                
        if not md_file:
            # 후보 목록에 없는 임의의 md 파일 검색
            all_mds = glob.glob(os.path.join(folder_path, "*.md"))
            if all_mds:
                md_file = all_mds[0]
                
        if not md_file:
            # MD 파일이 없는 경우 스킵
            continue

        try:
            # 마크다운 읽기
            with open(md_file, "r", encoding="utf-8") as f:
                md_content = f.read()

            # 마크다운 ➔ HTML 파싱 (table, code 확장 활성화)
            html_content = markdown.markdown(md_content, extensions=['tables', 'fenced_code', 'toc'])

            # 템플릿에 데이터 채우기 (가독성 높은 타이틀)
            company_display = folder_name.replace("-", " ").replace(".", " ").capitalize()
            rendered_html = HTML_TEMPLATE.format(
                company_name=company_display,
                content_html=html_content
            )

            # HTML 파일로 저장
            output_filename = f"{folder_name}.html"
            output_path = os.path.join(output_dir, output_filename)
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(rendered_html)

            converted_companies.append({
                "name": folder_name,
                "display": company_display,
                "filename": output_filename
            })
            print(f"├─ [성공] {folder_name} 변환 완료")

        except Exception as e:
            print(f"├─ [실패] {folder_name} 변환 중 오류 발생: {e}")

    # ── 6. 인덱스 포털 index.html 생성 로직 ──
    cards_html = ""
    for company in converted_companies:
        first_letter = company["display"][0]
        cards_html += f"""
            <a href="{company['filename']}" class="company-card" data-name="{company['name'].lower()}">
                <div class="company-logo-badge">{first_letter}</div>
                <div class="company-name">{company['display']}</div>
            </a>"""

    rendered_index = INDEX_TEMPLATE.format(cards_html=cards_html)
    index_path = os.path.join(output_dir, "index.html")
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(rendered_index)

    print(f"\n[완료] 총 {len(converted_companies)}개의 회사 디자인 마크다운 파일 변환이 성공적으로 끝났습니다!")
    print(f"[경로] 미리보기 포털 주소: {index_path}")

if __name__ == "__main__":
    main()
