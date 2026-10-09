# 04 — OpenCode + DeepSeek-V4.1-Flash on Fireworks (Microsoft Foundry)

Config: `~/.config/opencode/opencode.json`
- Provider id: `fireworks-azure` (npm `@ai-sdk/openai-compatible`)
- Base URL: `https://nabhasens-foundry.services.ai.azure.com/openai/v1`
- Model entry: `Avi-DeepSeek-V4.1-Flash` with `id: DeepSeek-V4.1-Flash` (the real API id) so the
  picker shows a named entry while the API still receives the correct model.
- Cost: input $0.30 / output $1.20 / cache read $0.006 / write $0.
- Key: `{env:OPENCODE_FIREWORKS_API_KEY}` (Plan B) — also stored in the OpenCode auth
  store as the `Azure` integration (`opencode2 auth list`).

Verify:
```bash
Avi-opencode2 models | grep fireworks
Avi-opencode2 run --standalone --model fireworks-azure/Avi-DeepSeek-V4.1-Flash "Reply PING"
opencode2 stats          # token + cost tracking
```
Credentials were imported from the local machine's OpenCode (`Azure`, `Firecrawl`).
