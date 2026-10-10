-- 连续打英文单词时，自动在单词之间补空格 —— 滤镜部分
--
-- 与 en_auto_space_processor.lua 配套使用，说明都在那边。
-- 纯英文 trailing 模式给英文候选加尾空格；默认混打模式在状态有效时加前空格。
-- 混打状态由处理器维护，这里只读。

local F = {}

local PROP = 'en_auto_space'

function F.init(env)
    local config = env.engine.schema.config
    env.timeout = config:get_int('en_auto_space/timeout') or 10
    env.trailing = config:get_string('en_auto_space/mode') == 'trailing'
end

function F.func(input, env)
    local stamp = tonumber(env.engine.context:get_property(PROP))
    local on = stamp ~= nil and (env.timeout <= 0 or os.time() - stamp <= env.timeout)
    for cand in input:iter() do
        -- 纯英文词库也包含 3D、C++、.NET、CI/CD 和带重音字母的外文词，
        -- 不能限定「字母开头、只含撇号等」。此模式仅挂在独立英文方案。
        if env.trailing and cand.text:find('%a') then
            -- 纯英文方案：候选本身带尾空格，空格选词和点选都走同一路径。
            -- 已带空格的候选不重复追加。
            local text = cand.text:gsub(' +$', '') .. ' '
            yield(cand:to_shadow_candidate(cand.type, text, cand.comment))
        -- 混打仍使用保守识别，中文及中英混合词（P社、T恤）原样放行。
        elseif not env.trailing and on and cand.text:match("^%a[%w'%-%. ]*$") then
            yield(cand:to_shadow_candidate(cand.type, ' ' .. cand.text, cand.comment))
        else
            yield(cand)
        end
    end
end

return F
