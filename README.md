# 네이버 블로그 자동화 파이프라인

키워드 하나만 입력하면 네이버 SEO 최적화 블로그 글 + 이미지를 자동 생성합니다.

## 사전 준비

### 1. Claude Code 설치
이미 설치되어 있으면 스킵하세요.

### 2. API 키 2개 발급

**네이버 검색 API**
1. https://developers.naver.com/apps 접속
2. 애플리케이션 등록
3. "검색" API 선택
4. Client ID와 Client Secret 복사

**Gemini API (이미지 생성용)**
1. https://aistudio.google.com/apikey 접속
2. "Create API Key" 클릭
3. API Key 복사

## 설치 (1줄)

터미널에 아래를 복사-붙여넣기 하세요:

bash <(curl -fsSL https://raw.githubusercontent.com/alice840126-ship-it/naver-blog-auto/main/setup.sh)

설치 중 API 키를 묻습니다. 복사해둔 키를 붙여넣기 하세요.

## 사용법

Claude Code에서:
/블로그 [키워드]

예시:
/블로그 클로드 코드 활용법
/블로그 챗GPT vs 제미나이 비교
/블로그 네이버 블로그 상위노출 방법

## 결과물

바탕화면 > 블로그자동화 폴더에 저장됩니다:
- 마크다운 파일 (.md) — 블로그 글 본문
- images/ 폴더 — 커버 이미지 + 섹션별 이미지

## 네이버 블로그에 올리기

1. 바탕화면 > 블로그자동화 폴더 열기
2. .md 파일 열어서 내용 복사
3. 네이버 블로그 > 새 글 작성
4. 내용 붙여넣기
5. images/ 폴더에서 이미지 직접 첨부
6. 발행!

## FAQ

**Q. 비용이 드나요?**
네이버 API는 무료입니다. Gemini API도 무료 한도 내에서 사용 가능합니다.

**Q. 얼마나 걸리나요?**
약 15-20분 (이미지 생성 포함).

**Q. Gemini API 키가 없으면?**
이미지 없이 글만 생성됩니다.

**Q. 업데이트는 어떻게 하나요?**
설치 명령어를 다시 실행하면 됩니다. API 키는 유지됩니다.
