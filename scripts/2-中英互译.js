// ============================================================
// 中英互译（自动判方向）
//
//   我明天可能没时间  →  I might not have time tomorrow.
//   I might not...    →  我明天可能没时间。
//
// 中文占比过半判为中译英，否则英译中。
// ============================================================

const API_KEY = 'sk-ant-在这里填你的key'
const MODEL = 'claude-opus-5'

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

// 按 CJK 字符占比判断翻译方向。
// 只数「有意义的字符」（去掉空白和标点），否则中英混排时标点会把比例带偏。
function isChinese(text) {
  const meaningful = text.replace(/[\s\p{P}\p{S}]/gu, '')
  if (!meaningful) return false
  const cjk = meaningful.match(/[一-鿿]/g)
  return cjk && cjk.length / meaningful.length > 0.3
}

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
      output_config: { effort: 'low' },
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
  if (json.stop_reason === 'refusal') {
    $log('模型拒答: ' + JSON.stringify(json.stop_details))
    return null
  }
  const block = (json.content || []).find(b => b.type === 'text')
  return block ? block.text.trim() : null
}

async function output() {
  try {
    const text = pickInput()
    if (!text) return '没有取到文本：先选中或复制'

    const toEnglish = isChinese(text)
    const system = toEnglish
      ? 'Translate the user text from Chinese to English. Produce ' +
        'natural, idiomatic English that a native speaker would ' +
        'actually write — not a literal gloss. Match the register of ' +
        'the original (casual stays casual, formal stays formal). ' +
        'Output ONLY the translation, no preamble, no quotes.'
      : '把用户提供的英文翻译成中文。译文要自然通顺，符合中文表达习惯，' +
        '不要翻译腔。保持原文的语气（口语就口语，正式就正式）。' +
        '只输出译文，不要前言，不要引号。'

    const result = await ask(system, text)
    if (!result) return '翻译失败，详情见日志'
    return result
  } catch (error) {
    $log('异常: ' + error)
    return '出错了：' + error
  }
}
