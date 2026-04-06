#!/usr/bin/env python3
"""
MD → 네이버 블로그용 HTML 변환기
- 내용 100% 보존 (요약/변경 없음)
- 스타일만 추가: H1/H2/H3 색상·크기, 본문 가독성, 코드 블록
- 변환 후 브라우저 자동 오픈 → Cmd+A, Cmd+C → 네이버 블로그 붙여넣기
"""
import sys
import os
import subprocess
from pathlib import Path

try:
    import markdown
    from markdown.extensions.tables import TableExtension
    from markdown.extensions.fenced_code import FencedCodeExtension
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "markdown", "-q"], check=True)
    import markdown
    from markdown.extensions.tables import TableExtension
    from markdown.extensions.fenced_code import FencedCodeExtension

NAVER_CSS = """
  * {
    box-sizing: border-box;
  }
  body {
    font-family: 'Noto Sans KR', 'Apple SD Gothic Neo', '맑은 고딕', sans-serif;
    font-size: 16px;
    color: #333333;
    line-height: 1.9;
    max-width: 860px;
    margin: 0 auto;
    padding: 40px 24px 80px;
    background: #ffffff;
  }

  /* H1 대제목 */
  h1 {
    font-size: 28px;
    font-weight: 700;
    color: #0D1B2A;
    margin-top: 48px;
    margin-bottom: 20px;
    padding-top: 16px;
    border-top: 4px solid #0D1B2A;
    line-height: 1.3;
  }

  /* H2 중제목 */
  h2 {
    font-size: 22px;
    font-weight: 700;
    color: #1A5276;
    margin-top: 40px;
    margin-bottom: 16px;
    padding-left: 14px;
    border-left: 5px solid #1A5276;
    line-height: 1.4;
  }

  /* H3 소제목 */
  h3 {
    font-size: 18px;
    font-weight: 600;
    color: #2874A6;
    margin-top: 28px;
    margin-bottom: 10px;
    line-height: 1.5;
  }

  /* H4 */
  h4 {
    font-size: 16px;
    font-weight: 600;
    color: #2874A6;
    margin-top: 20px;
    margin-bottom: 8px;
  }

  /* 본문 */
  p {
    margin-bottom: 16px;
    word-break: keep-all;
  }

  /* 굵게 — 본문 색 유지, 굵기만 살짝 강조 */
  strong {
    font-weight: 600;
    color: inherit;
  }

  /* 인라인 코드 */
  code {
    background: #F4F6F7;
    border: 1px solid #D5D8DC;
    border-radius: 4px;
    padding: 2px 6px;
    font-size: 14px;
    font-family: 'Courier New', monospace;
    color: #C0392B;
  }

  /* 코드 블록 */
  pre {
    background: #F4F6F7;
    border: 1px solid #D5D8DC;
    border-radius: 6px;
    padding: 16px 20px;
    overflow-x: auto;
    margin: 16px 0 24px;
  }
  pre code {
    background: none;
    border: none;
    padding: 0;
    font-size: 14px;
    color: #2C3E50;
    line-height: 1.7;
  }

  /* 리스트 */
  ul, ol {
    margin: 12px 0 16px;
    padding-left: 28px;
  }
  li {
    margin-bottom: 6px;
    line-height: 1.8;
  }

  /* 인용구 */
  blockquote {
    border-left: 4px solid #AED6F1;
    background: #EBF5FB;
    margin: 16px 0;
    padding: 12px 20px;
    color: #2C3E50;
    border-radius: 0 6px 6px 0;
  }
  blockquote p {
    margin: 0;
  }

  /* 테이블 */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
    font-size: 15px;
  }
  th {
    background: #1A5276;
    color: #ffffff;
    padding: 10px 14px;
    text-align: left;
    font-weight: 600;
  }
  td {
    padding: 9px 14px;
    border-bottom: 1px solid #D5D8DC;
    vertical-align: top;
  }
  tr:nth-child(even) td {
    background: #F8F9FA;
  }

  /* 구분선 */
  hr {
    border: none;
    border-top: 2px solid #EBF5FB;
    margin: 32px 0;
  }

  /* 이미지 */
  img {
    max-width: 100%;
    height: auto;
    display: block;
    margin: 20px auto;
    border-radius: 6px;
  }

  /* 해시태그 (맨 하단) */
  p:last-of-type {
    color: #2874A6;
    font-size: 14px;
    margin-top: 32px;
    padding-top: 20px;
    border-top: 1px solid #EBF5FB;
  }

  /* 링크 */
  a {
    color: #1A5276;
    text-decoration: underline;
  }
  a:hover {
    color: #2874A6;
  }
"""

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
{css}
  </style>
</head>
<body>
{body}
</body>
</html>
"""

def convert(md_path: str) -> str:
    md_file = Path(md_path)
    if not md_file.exists():
        print(f"❌ 파일 없음: {md_path}")
        sys.exit(1)

    text = md_file.read_text(encoding="utf-8")

    # frontmatter 제거 (--- 로 시작하는 YAML 블록)
    if text.startswith("---"):
        end = text.find("---", 3)
        if end != -1:
            text = text[end + 3:].lstrip("\n")

    # 제목 추출 (H1)
    title = md_file.stem
    for line in text.splitlines():
        if line.startswith("# "):
            title = line[2:].strip()
            break

    # MD → HTML 변환 (내용 1:1 보존)
    md = markdown.Markdown(extensions=[
        "extra",          # tables, fenced_code, footnotes 등
        "codehilite",     # 코드 하이라이팅
        "toc",            # 목차
        "nl2br",          # 줄바꿈 보존
    ])
    body_html = md.convert(text)

    # 붙여넣기 시 단락 간격 보존: </p> 뒤에 <br> 삽입
    # (CSS margin은 rich text 붙여넣기 시 날아가므로 명시적 줄바꿈 필요)
    import re
    body_html = re.sub(r'</p>\s*<p>', '</p>\n<br>\n<p>', body_html)
    body_html = re.sub(r'</p>\s*<h([1-6])', r'</p>\n<br>\n<h\1', body_html)
    body_html = re.sub(r'</ul>\s*<p>', '</ul>\n<br>\n<p>', body_html)
    body_html = re.sub(r'</ol>\s*<p>', '</ol>\n<br>\n<p>', body_html)
    body_html = re.sub(r'</blockquote>\s*<p>', '</blockquote>\n<br>\n<p>', body_html)

    # 전체 HTML 조립
    html = HTML_TEMPLATE.format(
        title=title,
        css=NAVER_CSS,
        body=body_html,
    )

    # 저장
    out_path = md_file.with_suffix(".html")
    out_path.write_text(html, encoding="utf-8")
    print(f"✅ HTML 변환 완료: {out_path}")
    return str(out_path)


def main():
    if len(sys.argv) < 2:
        print("사용법: python3 md_to_naver_html.py [MD파일경로]")
        sys.exit(1)

    out_path = convert(sys.argv[1])

    # 브라우저 자동 오픈
    subprocess.run(["open", out_path])
    print()
    print("📋 브라우저에서 Cmd+A → Cmd+C → 네이버 블로그 에디터에 붙여넣기!")


if __name__ == "__main__":
    main()
