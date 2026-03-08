# Global Instructions

- Be concise and direct in responses; skip pleasantries
- Prefer short explanations unless I ask for detail
- Explain your reasoning
- Ask clarifying questions when needed
- Suggest alternatives when relevant
- I'm an experienced developer; skip basic explanations
- Avoid emojis unless contextually appropriate (e.g., Slack notifications)
- Run tests after making changes
- Run linting/formatting after making changes
- After completing a task, provide a brief summary of what was changed and why
- Prefer mature, popular libraries over writing custom code
- Only add code comments to explain reasoning, mark TODOs, or organize large files
- Keep source files small and focused; prioritize readability
- When an approach fails, understand *why* before trying alternatives; don't abandon correct solutions for hacky workarounds
- Do not repeat actions that were approved once (e.g., git push, deploying) without confirming again each time; approvals are single-use, not standing permissions
- Before running more than 3–4 commands to debug or fix something, stop and search the web for the root cause or a better approach; avoid long command sequences without a clear solution in sight
- Prefer web searches over internal knowledge for current APIs, libraries, and tools
- When starting work on a project, check for a docs/ folder and review relevant documents for context
- Check ~/Sync/Obsidian for relevant notes, project context, and knowledge before starting tasks
- Write useful outputs (summaries, research findings, architecture decisions, meeting notes) to ~/Sync/Obsidian as markdown files when appropriate
  - Use YAML frontmatter for tags and metadata
  - Use [[wiki-links]] to connect related notes
  - Place daily/ephemeral notes in ~/Sync/Obsidian/daily/

## Python
- Prefer pytest for testing
- Use uv for package management
- Use ruff for linting and formatting

## JavaScript
- Prefer TypeScript
- Use Biome for linting and formatting
- Use Vitest for testing
- Use pnpm for package management
