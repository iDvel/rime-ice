local function debug_checker(input, env)
  for cand in input:iter() do
    yield(ShadowCandidate(
      cand,
      cand.type,
      cand.text,
      env.engine.context.input .. " - " .. env.engine.context:get_preedit().text .. " - " .. cand.preedit
    ))
  end
end

return debug_checker
