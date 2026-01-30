# Cursor & Cursor Agent

Cursor uses a structured system for AI customization via `.cursor/` directory files. Official docs: [Cursor Documentation](https://cursor.com/docs) (focus on Context, Rules, Agents sections).

## SKILLS
**What they are**: Reusable, autonomous modules in `SKILL.md` files with YAML frontmatter; agents auto-discover and invoke them for specific workflows (e.g., "generate diagram" or "refactor module").  
**When to use**: For procedural, repeatable tasks needing minimal prompting; prefer over rules for dynamic execution.  
**Applications**: Codebase audits, UI prototyping, testing suites.  
**How to use**: Create `SKILL.md` with `--- description: "Task desc" ---` + instructions; invoke via `/skillname` or auto-trigger. [cursor](https://cursor.com/changelog/2-4)
**Storage/Sharing**: `.cursor/skills/` folder or project root; Git repo syncs team-wide. Export via Cursor Settings → Import/Export.

## RULES
**What they are**: Persistent system prompts (global/file-specific/conditional) for consistent behavior.  
**When to use**: Enforce standards like "use TypeScript everywhere" without per-prompt repetition.  
**Applications**: Coding style, security checks, architecture patterns.  
**How to use**: Settings → Rules or `.cursor/rules/*.mdc`; `@rule` to reference. [builder](https://www.builder.io/blog/cursor-ai-tips-react-nextjs)
**Storage/Sharing**: `.cursor/rules/` dir in repo; team shares via Git branches or shared settings.json.

## AGENTS
**What they are**: Custom AI personas with tailored prompts/tools/models for complex tasks.  
**When to use**: Delegate high-level planning/execution beyond Composer.  
**Applications**: Full feature dev, debugging marathons.  
**How to use**: Define in `.cursor/agents/*.md` with frontmatter (model, tools); invoke via `@agentname`. [cursor](https://www.cursor.fan/tutorial/HowTo/introduction-to-cursor-ai-agents/)
**Storage/Sharing**: `.cursor/agents/` in Git repo; npm package for cross-project.

## SUBAGENTS
**What they are**: Parallel specialist sub-instances spun by main agent (e.g., researcher, executor).  
**When to use**: Break monolithic tasks into concurrent streams.  
**Applications**: Multi-file edits, research+apply cycles.  
**How to use**: Auto-available or custom via agent defs; monitor in Activity panel. [cursor](https://cursor.com/docs/context/subagents)
**Storage/Sharing**: Inherited from agents; share agent configs repo-wide.

## COMMANDS
**What they are**: User-invoked slash actions wrapping skills/scripts.  
**When to use**: Manual triggers for non-auto tasks.  
**Applications**: Quick scaffolds, linters.  
**How to use**: `.cursor/commands/*.md` with args like `$ARG`; `/cmd arg`. [forum.cursor](https://forum.cursor.com/t/skills-vs-commands-vs-rules/148875)
**Storage/Sharing**: `.cursor/commands/` in repo; team Git pull.

**Team Package**: Create `.cursor/` skeleton repo (all above + `package.json` scripts like `cursor-import`); `git clone` + Cursor "Attach Folder" or VS Code sync.

# Opencode

Terminal-based AI coding agent (CLI/TUI); extensible via Markdown files. Official docs: [OpenCode.ai Docs](https://opencode.ai/docs/) | [GitHub](https://github.com/sst/opencode)  [josean](https://www.josean.com/posts/how-to-use-opencode-ai).

## AGENTS
**What they are**: Core personas like Plan/Build in `AGENTS.md` (auto-init via `/init`).  
**When to use**: Switch via Tab/Ctrl+x+a for planning vs. editing.  
**Applications**: Feature planning, code application, testing.  
**How to use**: `/init` generates; edit `AGENTS.md`; `@agent` or hotkeys. [josean](https://www.josean.com/posts/how-to-use-opencode-ai)
**Storage/Sharing**: Project root `AGENTS.md`; Git repo for team.

## COMMANDS
**What they are**: Custom slash actions in `.opencode/command/*.md` with YAML frontmatter + `$ARGUMENTS`.  
**When to use**: Scaffold/domain tasks like "/component MyUI".  
**Applications**: Boilerplate gen, framework-specific creators.  
**How to use**: Create `.opencode/command/task.md`; invoke `/task arg`; optional agent/model override. [josean](https://www.josean.com/posts/how-to-use-opencode-ai)
**Storage/Sharing**: `.opencode/commands/` dir; repo commit.

## SKILLS / RULES / SUBAGENTS
**What they are**: SKILLS/RULES via custom prompts in `~/.config/opencode/agent/*.md` (e.g., task-manager.md); SUBAGENTS in subdirs.  
**When to use**: Extend behaviors globally/per-project (skills for tasks, rules for style).  
**Applications**: Custom QA, docs gen, workflows.  
**How to use**: Edit config dir files; `/models` for integration. [neilpatterson](https://www.neilpatterson.dev/writing/opencode-ai-development-workflow-guide)
**Storage/Sharing**: `~/.config/opencode/` + project overrides; team via dotfiles repo or `opencode init --shared`.

**Team Package**: Shared Git repo with `AGENTS.md`, `.opencode/`, scripts (`npx opencode-init-team`); `curl install` + repo clone. Cross-IDE via VS Code extension. [opencode](https://opencode.ai/docs/ide/)

**Abstract Package**: Unified `.ai-package/` with Cursor `.cursor/` + Opencode files; README install scripts for both (prioritize Cursor). Share via private npm/Git for team.

# RELEVANT REPOS

Here are the most relevant **GitHub repositories** focused on **Claude Code**, **OpenCode**, or **Cursor** ecosystems for agents, subagents, skills, rules, commands, and plugins. I've added the **Get-Shit-Done** system and **Ralph Loops** implementations as requested, and removed all MCP-related repos (e.g., dbt-mcp) since you specified no MCPs.

These provide ready-to-use configs, looping mechanisms for autonomy, and multi-agent patterns—perfect for extending your Analytics Engineer OS with high-autonomy workflows (e.g., persistent loops for DBT tasks, spec-driven delegation).

### Top Additions: Get-Shit-Done & Ralph Loops
1. **glittercowboy/get-shit-done**  
   A lightweight, powerful meta-prompting and context engineering system for Claude Code and OpenCode. Designed for spec-driven, autonomous development ("Get Shit Done" mode) with phases, persistent state, and anti-context-rot techniques. Highly popular for making agents more aggressive and effective on complex tasks—adapt for your Tech Lead/Engineer loops.  
   Stars: ~9k (highly active as of Jan 2026).  
   Link: https://github.com/glittercowboy/get-shit-done

2. **danielsinewe/ralph-cursor**  
   Ralph implementation with direct Cursor Agent support. Enables autonomous AI development loops (fresh agent restarts to avoid context rot) for building features from specs/PRDs. Core for long-running, persistent agentic workflows in Cursor.  
   Link: https://github.com/danielsinewe/ralph-cursor

3. **snarktank/ralph**  
   Ralph as an autonomous AI agent loop that repeatedly runs tools like Claude Code until objectives (e.g., PRD items) are complete. Fresh context per iteration—ideal for reliable, stateful DBT automation without degradation.  
   Link: https://github.com/snarktank/ralph

4. **wenqingyu/ralphy-openspec**  
   Advanced Ralph loop integration with OpenSpec for Cursor, OpenCode, and Claude Code. Focuses on heavy-lifting autonomy and spec-driven execution.  
   Stars: ~200+.  
   Link: https://github.com/wenqingyu/ralphy-openspec

5. **frankbria/ralph-claude-code**  
   Autonomous AI development loop for Claude Code (extendable to OpenCode/Cursor) with monitoring, state files, and bash-driven persistence. Includes dashboard for oversight.  
   Link: https://github.com/frankbria/ralph-claude-code

### Cursor-Focused Repos (Rules, Skills, Agents)
1. **PatrickJS/awesome-cursorrules**  
   Curated collection of .cursorrules files for custom behaviors, including autonomy boosts and best-practice enforcement. Great for DBT-specific rules.  
   Link: https://github.com/PatrickJS/awesome-cursorrules

2. **chrisboden/cursor-skills**  
   Skills and rules for agent roles/orchestration, including delegation patterns (e.g., multi-agent swarms). Adapt for Tech Lead → Engineer in DBT repos.  
   Link: https://github.com/chrisboden/cursor-skills

3. **WonderMr/Agents**  
   Semantic router for dynamic agent/skill loading in Cursor. Includes specialized agents—useful for modular Analytics Engineer setups.  
   Link: https://github.com/WonderMr/Agents

### OpenCode-Focused Repos (Agents, Skills, Plugins, Commands)
1. **awesome-opencode/awesome-opencode**  
   Official curated list of plugins, agents, skills, and configs. Best starting point for multi-agent and command examples.  
   Link: https://github.com/awesome-opencode/awesome-opencode

2. **zenobi-us/opencode-skillful**  
   Plugin for lazy-loaded Agent Skills (Anthropic spec). Enables on-demand discovery for reusable DBT/git skills.  
   Link: https://github.com/zenobi-us/opencode-skillful

3. **joelhooks/opencode-config**  
   Personal config with multi-agent swarms, error-learning loops, and tools. Strong delegation examples for Tech Lead + subagents.  
   Link: https://github.com/joelhooks/opencode-config

4. **darrenhinde/OpenAgentsControl**  
   Framework for custom .opencode architectures (agents, skills, plugins) with interactive builder. Excellent for DBT hierarchies.  
   Link: https://github.com/darrenhinde/OpenAgentsControl

### Claude Code-Focused Repos (Skills, Agents, Rules – Portable to Cursor/OpenCode)
1. **anthropics/skills** (Official)  
   Public repo for the Agent Skills standard. Foundational for building/porting DBT-specific skills.  
   Link: https://github.com/anthropics/skills

2. **VoltAgent/awesome-claude-skills**  
   Huge collection (150+) of skills/agents—many portable to Cursor/OpenCode for data/analytics tasks.  
   Link: https://github.com/VoltAgent/awesome-claude-skills

3. **steipete/agent-rules**  
   Optimized rules and knowledge bases for efficiency—good for best-practice enforcement in loops.  
   Link: https://github.com/steipete/agent-rules

Get-Shit-Done and Ralph Loops are game-changers for autonomy (fresh contexts, persistent loops)—fork glittercowboy/get-shit-done or a Ralph repo first to combine with your skills/agents for DBT workflows. Many are bash-driven for reliability in long tasks. If you want details on a specific one (e.g., files to copy), let me know!