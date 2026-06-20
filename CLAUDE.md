# AI Agent Teams Libs · 项目总纲

> 本仓库存放一支 **AI Agent 智能体团队**的角色定义。每个岗位 = 一个 Agent（非真人），按「产品 & 技术线」组织，覆盖 0→1 起步阶段的最小闭环。

---

## 一、目录约定

每个角色是一个独立目录，命名格式为 `NN_<id>_<autonomy>`：

```
01_manager_human/     CTO / 技术负责人   （规格轨·编排中枢）
02_prd_human/         产品经理           （规格轨）
03_backend_auto/      后端工程师         （实现轨）
04_frontend_auto/     前端工程师         （实现轨）
05_fullstack_auto/    全栈工程师         （实现轨）
06_qa_auto/           测试 / QA          （验证轨）
07_design_human/      UI/UX 设计师       （规格轨·UX）
08_data_auto/         数据分析师         （可自主）
09_techlead_auto/     技术 Leader（可选） （默认 enabled:false）
```

命名三段含义：

- **`NN`**：工号 / 排序（按团队拓扑：编排中枢领头 → 产品 → 实现 → 验证 → 设计 → 数据 → 可选）。
- **`<id>`**：逻辑 id，与 `role.json` 的 `id` 字段一致，也是 `collab` 上下游引用的名字。**改文件夹名不会影响协作链路**（引用的是 id，不是路径）。
- **`<autonomy>`**：自主度标识，对应「双轨工作流」——
  - `human`：吃人工注意力、难并行（规格 / UX / 终审）。
  - `auto`：输入齐备后可半自主跑、可并行（实现 / 验证 / 数据）。

---

## 二、双引擎结构（Claude + Codex）

每个角色同时具备 **Claude** 和 **Codex** 两套运行环境，角色定义本身与 runtime 无关，可在编排时选择引擎启动。

每个 agent 目录的标准布局：

```
NN_xxx/
├── role.json          # 角色元数据 + 多 runtime 配置（见下）
├── CLAUDE.md          # Claude 指令文件（persona + 工作要求）
├── AGENTS.md          # Codex  指令文件（persona + Runtime 约束 + 交付要求）
├── RTK.md             # RTK 代理约定（保留，供 Rust Token Killer 使用）
├── .claude/skills/    # Claude 技能目录   ┐
└── .codex/skills/     # Codex  技能目录   ┘ 两者内容必须保持镜像（见第三节）
```

`role.json` 的 runtime 配置：

```json
{
  "default_runtime": "claude",
  "runtimes": {
    "claude": {
      "command": "claude",
      "args": ["--dangerously-skip-permissions"],
      "instructions_file": "CLAUDE.md",
      "skills_dir": ".claude/skills"
    },
    "codex": {
      "command": "codex",
      "args": ["--dangerously-bypass-approvals-and-sandbox"],
      "instructions_file": "AGENTS.md",
      "skills_dir": ".codex/skills"
    }
  }
}
```

- 编排器读 `default_runtime` 决定默认引擎；要切 Codex 就用 `runtimes.codex`。
- 切换引擎**不影响** `id` / `collab` / `autonomy` 等角色语义。

---

## 三、Skill 安装规则（重要）

> ⚠️ **核心约定：安装任何 skill 时，必须同时装进该 agent 的 `.claude/skills/` 和 `.codex/skills/` 两个目录。** 只装一边会导致换引擎后技能缺失，团队不完整。

### 为什么

Claude 从 `.claude/skills/` 读技能，Codex 从 `.codex/skills/` 读技能。两个引擎共享同一个角色，但各自读自己的目录——所以技能必须在两处都存在，内容保持一致。

### 标准安装流程

把一个 skill（例如从外部仓库 vendored 的 `some-skill`）装到角色 `07_design_human` 时：

```bash
AGENT="07_design_human"
SKILL_SRC="/path/to/some-skill"        # 源 skill 目录（含 SKILL.md）

# 1) 同时复制到两个技能目录
for engine in .claude .codex; do
  mkdir -p "$AGENT/$engine/skills"
  rsync -a --exclude '.DS_Store' "$SKILL_SRC" "$AGENT/$engine/skills/"
done

# 2) 在 role.json 的 skills 数组里登记 skill 名（与目录名一致）
#    手动编辑，或用脚本把 "some-skill" 追加进 .skills

# 3) 若 skill 有运行依赖（bun / sharp / pdf-lib 等），在该 agent 目录补 package.json 并安装
#    cd "$AGENT" && bun install
```

### 校验两个目录是否同步

```bash
AGENT="07_design_human"
diff <(cd "$AGENT/.claude/skills" && find . -type f ! -name '.DS_Store' | sort) \
     <(cd "$AGENT/.codex/skills"  && find . -type f ! -name '.DS_Store' | sort) \
  && echo "✅ 两个技能目录已同步" || echo "❌ 不同步，请补齐"
```

### 卸载 skill

同样要两边都删，并从 `role.json` 的 `skills` 数组移除：

```bash
AGENT="07_design_human"; SKILL="some-skill"
rm -rf "$AGENT/.claude/skills/$SKILL" "$AGENT/.codex/skills/$SKILL"
# 再从 role.json 的 skills 数组删掉 "some-skill"
```

---

## 四、协作链路（谁接谁的活）

核心链路：**用户需求 → PM → CTO（拆解分发）→ 工程 Agent（实现）→ QA（验证）→ 交付**。

| Agent | 上游（接活） | 下游（交付） |
|-------|-------------|-------------|
| `02_prd`（PM） | user | manager, design |
| `07_design`（UI/UX） | prd | frontend |
| `01_manager`（CTO） | prd | backend, frontend, fullstack, qa |
| `03_backend` | manager | frontend, qa |
| `04_frontend` | prd, manager | qa |
| `05_fullstack` | manager | qa |
| `06_qa` | backend, frontend, fullstack, prd | manager + 工程 Agent（回报 bug） |
| `08_data` | prd, manager | prd, manager |
| `09_techlead`（可选） | manager | backend, frontend, fullstack |

交接统一通过 `collab.handoff_via` 指定的 `.aiteam/tasks/` 进行，不绕过协作协议直接改代码。

---

## 五、维护原则

1. **职责边界锁死**：每个 Agent 的「不碰」清单写在其 `CLAUDE.md` / `AGENTS.md` 里，不得越界——Agent 边界模糊会互相覆盖或陷入循环。
2. **双引擎对等**：改动 persona（CLAUDE.md）时，记得同步 AGENTS.md；装/卸 skill 时，两个技能目录必须一致。
3. **id 稳定**：可以改文件夹的 `NN` 序号或 `autonomy` 后缀，但**不要轻易改 `id`**——它被 `collab` 引用，改了要全局同步。
4. **techlead 默认关闭**：0→1 阶段由 CTO 兼任编排，`09_techlead` 的 `role.json` 中 `enabled: false`，规模化后再启用。

---

*维护说明：本文件是团队总纲。各角色自身的 persona 见各目录下的 `CLAUDE.md`（Claude）/ `AGENTS.md`（Codex）。*
