-- 连续打英文单词时，自动在单词之间补空格 —— 处理器部分
--
-- 与 en_auto_space_filter.lua 配套使用，两个都要挂：
--     engine/processors 里（express_editor 之前）  - lua_processor@*en_auto_space_processor
--     engine/filters 里（uniquifier 之前）         - lua_filter@*en_auto_space_filter
--
-- 【模式】en_auto_space/mode: trailing 用于纯英文方案：选词后立即加尾空格，
-- 回车原样上屏也加尾空格。此模式由滤镜处理候选，不需要记录提交状态。
-- 已上屏的尾空格无法自动撤回，紧接标点前需手动退格。
--
-- 【默认模式：空格补在哪】补在**下一个单词前面**，不是这个单词后面。
--     hello + world  →  "hello" 然后 " world"
-- 补在后面的话，单词后面接标点就成了 "hello ,"，而 Rime 没有办法把已经上屏的
-- 空格删回来（iOS 自带键盘能删，是因为它直接操作输入框）。那是天天都会撞上的误判。
--
-- 【什么时候补】只在「上一次上屏的是英文，且之后没有别的键进过输入框」时。
-- 本文件负责维护这个状态，记在 context 的 property 里（值是上屏时刻的时间戳），
-- 滤镜那边只读不写。状态在三种情况下作废：
--     · 上屏了不是英文的东西（中文、标点、数字）
--     · 没在打字时按了任何非字母键：空格、回车、退格、方向键……
--       —— 你自己打了空格就不该再补一个；删过字、换过行也不该补
--     · 过了 timeout 秒（默认 10）。挪光标、切 App、点发送按钮，这些 Rime 都看不见，
--       只能靠时间兜底：隔了一阵再打的，多半已经不是同一句话了。
--       宁可少补一个（你自己按一下空格），不要在句首多出一个
--
-- 【回车】打字中途按回车是「把打的字母原样上屏」。候选项的空格由滤镜补，
-- 原样上屏不经过候选，所以在这里接管：该补空格时自己上屏 " " + 字母。
--
-- 上游有个同名思路的 en_spacer.lua，没用它的原因：它只认候选不认回车；
-- 它只看上屏历史，你手动打过空格它不知道，会补成两个空格。

local P = {}

local PROP = 'en_auto_space'

-- 算作「英文」的上屏内容：字母开头，后面是字母、数字、撇号、连字符、句点、空格。
-- 覆盖 hello / don't / well-known / Mrs. / thank you / MP3；开头允许一个空格（上一次补的）。
local function is_english(text)
    return text ~= nil and text:match("^ ?%a[%w'%-%. ]*$") ~= nil
end

-- 修饰键本身的按下（Shift、Ctrl、Caps Lock……）不算「有键进过输入框」
local function is_modifier(keycode)
    return keycode >= 0xffe1 and keycode <= 0xffee
end

local function is_letter(keycode)
    return (keycode >= 0x41 and keycode <= 0x5a) or (keycode >= 0x61 and keycode <= 0x7a)
end

function P.init(env)
    local config = env.engine.schema.config
    env.timeout = config:get_int('en_auto_space/timeout') or 10
    env.trailing = config:get_string('en_auto_space/mode') == 'trailing'

    -- 尾空格模式不依赖上一次提交的状态；候选由滤镜直接加尾空格。
    if env.trailing then
        return
    end

    -- 每次上屏后更新状态。候选上屏、空格上屏、回车原样上屏都会走到这里
    env.commit_conn = env.engine.context.commit_notifier:connect(function(ctx)
        if is_english(ctx:get_commit_text()) then
            ctx:set_property(PROP, tostring(os.time()))
        else
            ctx:set_property(PROP, '')
        end
    end)
end

function P.fini(env)
    if env.commit_conn then
        env.commit_conn:disconnect()
    end
end

function P.func(key, env)
    if key:release() then
        return 2
    end
    local ctx = env.engine.context
    local keycode = key.keycode

    if env.trailing then
        -- 回车提交原始输入，不经过候选滤镜，在这里补上相同的尾空格。
        local repr = key:repr()
        if ctx:is_composing() and (repr == 'Return' or repr == 'KP_Enter') and
            ctx.input:match("^%a[%w'%-%. ]*$") then
            env.engine:commit_text(ctx.input:gsub(' +$', '') .. ' ')
            ctx:clear()
            return 1
        end
        return 2
    end

    if not ctx:is_composing() then
        -- 没在打字：除了字母（要开始打下一个词了）和修饰键，任何键都让状态作废
        if not is_modifier(keycode) and
            (not is_letter(keycode) or key:ctrl() or key:alt() or key:super()) then
            ctx:set_property(PROP, '')
        end
        return 2
    end

    -- 打字中途按回车：原样上屏。该补空格时在这里接管
    local repr = key:repr()
    if repr == 'Return' or repr == 'KP_Enter' then
        local stamp = tonumber(ctx:get_property(PROP))
        local input = ctx.input
        if stamp and (env.timeout <= 0 or os.time() - stamp <= env.timeout) and
            input:match("^%a[%a']*$") then
            env.engine:commit_text(' ' .. input)
            ctx:clear()
            ctx:set_property(PROP, tostring(os.time()))
            return 1
        end
    end
    return 2
end

return P
