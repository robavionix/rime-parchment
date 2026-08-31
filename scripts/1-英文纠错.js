// ============================================================
// 英文纠错
//
// 选中英文 → 跑脚本 → 点候选替换
//   I go to university yesterday and I meet my friend
//   → I went to university yesterday and met my friend.
//
// 也可复制文本后直接跑（取剪贴板）。
// ============================================================

// ---------- 配置 ----------
const API_KEY = 'sk-ant-在这里填你的key'
const MODEL = 'claude-opus-5'   // 嫌慢改 'claude-haiku-4-5'

// ---------- 取输入 ----------
function pickInput() {
  const sources = [
    typeof $selectedText !== 'undefined' ? $selectedText : null,
    typeof $pasteboardContent !== 'undefined' ? $pasteboardContent : null,
    typeof $searchText !== 'undefined' ? $searchText : null,
  ]
  for (const s of sources) {
    if (s && String(s).trim()) return String(s).trim()
  }
  return null
}

// ---------- 调用 Claude ----------
async function ask(system, user) {
  const res = await $http({
    url: 'https://api.anthropic.com/v1/messages',
    method: 'POST',
    header: {
      'Content-Type': 'application/json',
      'x-api-key': API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: {
      model: MODEL,
      max_tokens: 2000,
      // effort: low —— 保持思考开启但压到最低档。
      // 键盘场景对延迟敏感，而这类文本改写不需要深度推理。
      output_config: { effort: 'low' },
      // 服务端兜底：极小概率的拒答会自动路由到备用模型，
      // 避免脚本在键盘里静默失败。
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      system: system,
      messages: [{ role: 'user', content: user }],
    },
    timeout: 30,
  })

  if (res.response.statusCode !== 200) {
    $log('HTTP ' + res.response.statusCode + ': ' + res.data)
    return null
  }

  const json = JSON.parse(res.data)

  // stop_reason 为 refusal 时 content 可能为空，先判再取
  if (json.stop_reason === 'refusal') {
    $log('模型拒答: ' + JSON.stringify(json.stop_details))
    return null
  }

  const block = (json.content || []).find(b => b.type === 'text')
  return block ? block.text.trim() : null
}

// ---------- 主流程 ----------
async function output() {
  try {
    const text = pickInput()
    if (!text) return '没有取到文本：先选中或复制'

    const system =
      'You are an English proofreader. Correct grammar, tense, ' +
      'spelling, and punctuation in the user text. Keep the original ' +
      'meaning, tone, and register — do not rewrite the style or add ' +
      'content. Output ONLY the corrected text, with no preamble, ' +
      'no quotes, and no explanation. If the text is already correct, ' +
      'output it unchanged.'

    const fixed = await ask(system, text)
    if (!fixed) return '纠错失败，详情见日志'

    // 没有改动时明确告知，省得盯着候选找差异
    if (fixed === text) return '✓ 原文无误：' + text
    return fixed
  } catch (error) {
    $log('异常: ' + error)
    return '出错了：' + error
  }
}
