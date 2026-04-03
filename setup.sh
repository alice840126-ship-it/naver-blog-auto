#!/bin/bash
# 네이버 블로그 자동화 파이프라인 설치 스크립트

set -e

echo ""
echo "========================================="
echo "  네이버 블로그 자동화 파이프라인 설치"
echo "========================================="
echo ""

# 바탕화면 경로 자동 감지
if [ -d "$HOME/Desktop" ]; then
  DESKTOP="$HOME/Desktop"
elif [ -d "$HOME/바탕 화면" ]; then
  DESKTOP="$HOME/바탕 화면"
else
  DESKTOP="$HOME/Desktop"
  mkdir -p "$DESKTOP"
fi
OUTPUT="$DESKTOP/블로그자동화"

# [1/4] API 키 입력
echo "[1/4] 네이버 검색 API 키 입력"
echo ""
echo "  아직 발급 안 하셨으면 여기서 발급하세요:"
echo "  https://developers.naver.com/apps"
echo "  → 애플리케이션 등록 → 검색 API 선택"
echo ""
read -p "  Client ID: " NAVER_ID
read -p "  Client Secret: " NAVER_SECRET

echo ""
echo "[2/4] Gemini API 키 입력 (이미지 생성용)"
echo ""
echo "  아직 발급 안 하셨으면 여기서 발급하세요:"
echo "  https://aistudio.google.com/apikey"
echo ""
read -p "  API Key: " GEMINI_KEY

# [3/4] 파일 설치
echo ""
echo "[3/4] 파일 설치 중..."

AGENTS_DIR="$HOME/.claude/agents/blog"
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$AGENTS_DIR" "$COMMANDS_DIR" "$OUTPUT" "$OUTPUT/images"

# 현재 스크립트 위치 기준 (로컬 설치 시)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/agents" ]; then
  # 로컬 설치 (ZIP 또는 git clone)
  for f in "$SCRIPT_DIR"/agents/*.md; do
    BASENAME=$(basename "$f")
    sed "s|__OUTPUT__|$OUTPUT|g; s|__AGENTS__|$AGENTS_DIR|g" "$f" > "$AGENTS_DIR/$BASENAME"
  done
  cp "$SCRIPT_DIR/agents/web_data_scraper.py" "$AGENTS_DIR/" 2>/dev/null || true
  sed "s|__AGENTS__|$AGENTS_DIR|g" "$SCRIPT_DIR/commands/블로그.md" > "$COMMANDS_DIR/블로그.md"
else
  # 원격 설치 (curl 파이프)
  REPO="https://raw.githubusercontent.com/alice840126-ship-it/naver-blog-auto/main"
  for f in orchestration-blog.md naver-analyzer.md serp-analyzer.md \
           blog-writer-naver.md blog-image.md blog-saver.md; do
    curl -fsSL "$REPO/agents/$f" | \
      sed "s|__OUTPUT__|$OUTPUT|g; s|__AGENTS__|$AGENTS_DIR|g" \
      > "$AGENTS_DIR/$f"
  done
  curl -fsSL "$REPO/agents/web_data_scraper.py" > "$AGENTS_DIR/web_data_scraper.py"
  curl -fsSL "$REPO/commands/블로그.md" | \
    sed "s|__AGENTS__|$AGENTS_DIR|g" \
    > "$COMMANDS_DIR/블로그.md"
fi

echo "  에이전트 파일 설치 완료"
echo "  커맨드 파일 설치 완료"

# .env 설정
ENV_FILE="$HOME/.claude/.env"
mkdir -p "$HOME/.claude"
[ -f "$ENV_FILE" ] && cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"
touch "$ENV_FILE"

# 기존 키가 있으면 제거 후 새로 추가
for key in NAVER_CLIENT_ID NAVER_CLIENT_SECRET GEMINI_API_KEY BLOG_OUTPUT_PATH BLOG_AGENTS_PATH; do
  sed -i '' "/^${key}=/d" "$ENV_FILE" 2>/dev/null || sed -i "/^${key}=/d" "$ENV_FILE" 2>/dev/null || true
done
cat >> "$ENV_FILE" << EOF
NAVER_CLIENT_ID=$NAVER_ID
NAVER_CLIENT_SECRET=$NAVER_SECRET
GEMINI_API_KEY=$GEMINI_KEY
BLOG_OUTPUT_PATH=$OUTPUT
BLOG_AGENTS_PATH=$AGENTS_DIR
EOF

echo "  API 키 저장 완료"

# Python 의존성
echo ""
echo "  Python 패키지 설치 중..."
pip3 install -q Pillow requests 2>/dev/null || pip install -q Pillow requests 2>/dev/null || echo "  ⚠️ pip 설치 실패 — 수동으로 pip3 install Pillow requests 실행해주세요"

# [4/4] 검증
echo ""
echo "[4/4] 설치 검증 중..."
echo ""

PASS=0
FAIL=0

# .env 키 확인
for key in NAVER_CLIENT_ID NAVER_CLIENT_SECRET GEMINI_API_KEY; do
  if grep -q "^${key}=." "$ENV_FILE" 2>/dev/null; then
    echo "  ✅ $key"
    ((PASS++))
  else
    echo "  ❌ $key 없음"
    ((FAIL++))
  fi
done

# 폴더 확인
if [ -d "$OUTPUT" ]; then
  echo "  ✅ 블로그자동화 폴더: $OUTPUT"
  ((PASS++))
else
  echo "  ❌ 블로그자동화 폴더 없음"
  ((FAIL++))
fi

# 커맨드 파일 확인
if [ -f "$COMMANDS_DIR/블로그.md" ]; then
  echo "  ✅ /블로그 커맨드"
  ((PASS++))
else
  echo "  ❌ /블로그 커맨드 없음"
  ((FAIL++))
fi

# 에이전트 파일 확인
AGENT_COUNT=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -ge 5 ]; then
  echo "  ✅ 에이전트 파일 ${AGENT_COUNT}개"
  ((PASS++))
else
  echo "  ❌ 에이전트 파일 부족 (${AGENT_COUNT}개)"
  ((FAIL++))
fi

# 플레이스홀더 잔존 체크
if grep -rq "__OUTPUT__\|__AGENTS__" "$AGENTS_DIR"/*.md 2>/dev/null; then
  echo "  ❌ 경로 치환 미완료"
  ((FAIL++))
else
  echo "  ✅ 경로 치환 완료"
  ((PASS++))
fi

# 네이버 API 테스트
NID=$(grep "^NAVER_CLIENT_ID=" "$ENV_FILE" | cut -d'=' -f2)
NSEC=$(grep "^NAVER_CLIENT_SECRET=" "$ENV_FILE" | cut -d'=' -f2)
if [ -n "$NID" ] && [ -n "$NSEC" ]; then
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://openapi.naver.com/v1/search/blog.json?query=테스트&display=1" \
    -H "X-Naver-Client-Id: $NID" \
    -H "X-Naver-Client-Secret: $NSEC" 2>/dev/null)
  if [ "$STATUS" = "200" ]; then
    echo "  ✅ 네이버 API 연결 성공"
    ((PASS++))
  else
    echo "  ❌ 네이버 API 응답: $STATUS"
    ((FAIL++))
  fi
fi

echo ""
echo "========================================="
echo "  결과: ${PASS}개 통과 / ${FAIL}개 실패"
echo "========================================="
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "🎉 설치 완료!"
  echo ""
  echo "사용법:"
  echo "  1. Claude Code 실행"
  echo "  2. /블로그 [키워드] 입력"
  echo "     예: /블로그 클로드 코드 활용법"
  echo ""
  echo "결과물:"
  echo "  바탕화면 > 블로그자동화 폴더"
  echo ""
else
  echo "⚠️ 위 실패 항목을 확인해주세요."
fi
