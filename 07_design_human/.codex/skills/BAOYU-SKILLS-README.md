# Project Skills

Source: `https://github.com/JimLiu/baoyu-skills/tree/main/skills`
Fetched commit: `67fa5cd329a5b0685e7305bbea3ca66762ad92c2`

These Baoyu image/drawing-related skills are vendored for this project:

| Skill | Purpose |
| --- | --- |
| `baoyu-image-gen` | General AI image generation backend and CLI. |
| `baoyu-cover-image` | Article cover image workflow. |
| `baoyu-article-illustrator` | Article illustration workflow. |
| `baoyu-xhs-images` | Xiaohongshu / social image card series. |
| `baoyu-infographic` | Publication-ready infographics. |
| `baoyu-comic` | Educational / knowledge comic generation. |
| `baoyu-slide-deck` | Slide deck image generation and export helpers. |
| `baoyu-diagram` | Standalone SVG diagram generation and SVG-to-PNG helper. |

Runtime preparation in the project root:

- `bun`, `node`, `npx`, and `codex` are available on this machine.
- `package.json` and `bun.lock` install helper dependencies:
  - `sharp` for SVG-to-PNG conversion in `baoyu-diagram`.
  - `pdf-lib` for comic / slide image PDF export helpers.
  - `pptxgenjs` for slide image PPTX export helpers.

Not installed by default:

- `baoyu-compress-image`: image optimization/conversion, not drawing.
- `baoyu-youtube-transcript`: can fetch video cover images, but is primarily transcript extraction.
- `baoyu-danger-gemini-web`: reverse-engineered Gemini Web access; install only after explicit risk approval.

Most raster workflows will use the local Codex `imagegen` skill when available, or `baoyu-image-gen` with a configured provider. API keys should stay in environment variables or `.baoyu-skills/.env`, not in skill files.
