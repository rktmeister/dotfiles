# OpenCode Config

Managed via GNU Stow. Symlinked to `~/.config/opencode/`.

## Structure

```
.config/opencode/
├── opencode.json       # Main config (providers, models, agents)
└── agent/
    ├── oracle.md       # Deep reasoning (GPT-5.2 via OpenRouter)
    └── multimodal-looker.md  # PDF/image analysis (Gemini 3 Flash via OpenRouter)
```

## Not in dotfiles (auto-generated or sensitive)

- `~/.config/opencode/node_modules/` - Plugin dependencies
- `~/.config/opencode/package.json` - Plugin manifest
- `~/.local/share/opencode/auth.json` - API keys (sensitive)

## Model routing

| Agent/Purpose | Model | Provider |
|---------------|-------|----------|
| oracle | GPT-5.2 (reasoningEffort: xhigh) | OpenRouter |
| multimodal-looker | Gemini 3 Flash | OpenRouter |
| explore | Gemini 3 Flash | OpenRouter |
| general | Gemini 3 Flash | OpenRouter |
| small_model | Gemini 3 Flash | OpenRouter |

## Adding agents

Create markdown files in `agent/` with YAML frontmatter:

```markdown
---
description: What this agent does
mode: subagent
model: openrouter/model-name
temperature: 0.1
tools:
  write: false
---

System prompt here...
```

## Key config options

- `model` - Default model for main agent
- `small_model` - Lightweight tasks (titles, summaries)
- `agent.<name>.model` - Override model for built-in agents
- `provider.<id>.models` - Define available models per provider
- `instructions` - Array of paths to load as system context

## Docs

https://opencode.ai/docs/config/
