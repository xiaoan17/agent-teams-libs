# AI Agent Teams · 角色库

> 一支 **AI Agent 智能体团队**的角色定义库。每个岗位 = 一个 Agent（非真人），按「产品 & 技术线」组织，覆盖一个产品从 0→1 起步阶段的最小闭环：**用户需求 → PM → CTO 拆解 → 工程实现 → QA 验证 → 交付**。

本仓库不是某个具体应用的代码，而是**「怎么用一组 AI Agent 组成一个软件团队」的可复用配置**。每个 Agent 都是一份结构化的角色定义（persona + 协作链路 + 运行时配置 + 技能），编排器读这些定义来启动、分工、协作。

---

## 一、团队构成

按团队拓扑排序：编排中枢领头 → 产品 → 实现 → 验证 → 设计 → 数据 → 可选扩展。

| 工号 | Agent | 职责 | 模式 |
|------|-------|------|------|
| `01_manager_human` | CTO / 技术负责人 | 规格轨 · 编排中枢，拆解需求并分发 | 🧑 human |
| `02_prd_human` | 产品经理 (PM) | 规格轨，把用户需求转成 PRD | 🧑 human |
| `03_backend_auto` | 后端工程师 | 实现轨 | 🤖 auto |
| `04_frontend_auto` | 前端工程师 | 实现轨 | 🤖 auto |
| `05_fullstack_auto` | 全栈工程师 | 实现轨 | 🤖 auto |
| `06_qa_auto` | 测试 / QA | 验证轨 | 🤖 auto |
| `07_design_human` | UI/UX 设计师 | 规格轨 · UX | 🧑 human |
| `08_data_auto` | 数据分析师 | 可自主 | 🤖 auto |
| `09_techlead_auto` | 技术 Leader（可选） | 规模化后启用，默认 `enabled:false` | 🤖 auto |

目录命名格式 `NN_<id>_<autonomy>`：

- **`NN`** — 工号 / 排序。
- **`<id>`** — 逻辑 id，与 `role.json` 的 `id` 字段一致，也是协作链路引用的名字。**改文件夹名不影响协作链路**（引用的是 id，不是路径）。
- **`<autonomy>`** — 自主度标识，见下一节。

---

## 二、核心设计：human vs auto 双轨

团队最关键的一个区分，是把每个 Agent 标记为 **`human`** 或 **`auto`**——这不是「真人 vs AI」（所有岗位都是 AI Agent），而是**这个角色吃多少人工注意力、能不能并行跑**。

### 🧑 `human` — 规格轨 / 终审

- **特征**：吃人工注意力、难并行。负责定义「要做什么」和「做得对不对」——产品需求、UX、最终审核这类**需要人来拍板**的环节。
- **谁是 human**：`manager`(CTO)、`prd`(PM)、`design`(UI/UX)。
- **运行方式**：`permission_mode` 偏向 `configure-before-start`——启动前要人确认目标与约束，过程中需要人参与决策。
- **为什么**：规格和审美是高歧义、高风险的判断，错了会让下游所有 auto Agent 一起跑偏，所以放在人工注意力的关口上。

### 🤖 `auto` — 实现轨 / 验证轨

- **特征**：输入齐备后可半自主跑、可并行。负责「按规格把东西做出来 / 验出来」——编码、测试、数据分析这类**有明确输入就能自动推进**的环节。
- **谁是 auto**：`backend`、`frontend`、`fullstack`、`qa`、`data`、`techlead`。
- **运行方式**：拿到上游交接的任务后可半自主执行，多个 auto Agent 可并行（如前端、后端同时开工）。
- **为什么**：实现和验证有清晰的验收标准，适合让 Agent 放开手脚跑，把人工注意力省下来给规格轨。

> **一句话**：`human` 把关「做什么 / 对不对」，`auto` 负责「怎么做出来」。需求和审美归 human，编码和测试归 auto。

---

## 三、协作链路（谁接谁的活）

核心链路：**用户需求 → PM → CTO（拆解分发）→ 工程 Agent（实现）→ QA（验证）→ 交付**。

| Agent | 上游（接活） | 下游（交付） |
|-------|-------------|-------------|
| `prd`（PM） | user | manager, design |
| `design`（UI/UX） | prd | frontend |
| `manager`（CTO） | prd | backend, frontend, fullstack, qa |
| `backend` | manager | frontend, qa |
| `frontend` | prd, manager | qa |
| `fullstack` | manager | qa |
| `qa` | backend, frontend, fullstack, prd | manager + 工程 Agent（回报 bug） |
| `data` | prd, manager | prd, manager |
| `techlead`（可选） | manager | backend, frontend, fullstack |

交接统一通过 `role.json` 里 `collab.handoff_via` 指定的 `.aiteam/tasks/` 进行，Agent 不绕过协作协议直接改代码。

---

## 四、每个 Agent 的目录结构

每个角色是一个独立目录，标准布局如下：

```
NN_xxx/
├── role.json          # 角色元数据：id / autonomy / 协作链路 / 多 runtime 配置 / 技能清单
├── CLAUDE.md          # Claude 指令文件（persona + 工作要求）
├── AGENTS.md          # Codex  指令文件（persona + Runtime 约束 + 交付要求）
├── .claude/skills/    # Claude 技能目录   ┐ 两者内容互为镜像，
└── .codex/skills/     # Codex  技能目录   ┘ 换引擎不丢技能
```

### 双引擎结构（Claude + Codex）

每个角色同时具备 **Claude** 和 **Codex** 两套运行环境。角色定义本身与 runtime 无关，编排时按需选引擎启动：

```json
{
  "default_runtime": "claude",
  "runtimes": {
    "claude": { "command": "claude", "instructions_file": "CLAUDE.md", "skills_dir": ".claude/skills" },
    "codex":  { "command": "codex",  "instructions_file": "AGENTS.md", "skills_dir": ".codex/skills" }
  }
}
```

- 编排器读 `default_runtime` 决定默认引擎；要切 Codex 就用 `runtimes.codex`。
- 切换引擎**不影响** `id` / `collab` / `autonomy` 等角色语义。
- ⚠️ **技能镜像约定**：安装任何 skill 时，必须同时装进 `.claude/skills/` 和 `.codex/skills/` 两个目录并在 `role.json` 的 `skills` 数组登记，否则换引擎会丢技能。

---

## 五、维护原则

1. **职责边界锁死**：每个 Agent 的「不碰」清单写在其 `CLAUDE.md` / `AGENTS.md` 里，不得越界——边界模糊会让 Agent 互相覆盖或陷入循环。
2. **双引擎对等**：改 persona（CLAUDE.md）时同步 AGENTS.md；装 / 卸 skill 时两个技能目录必须一致。
3. **id 稳定**：可以改文件夹的 `NN` 序号或 `autonomy` 后缀，但**不要轻易改 `id`**——它被 `collab` 引用，改了要全局同步。
4. **techlead 默认关闭**：0→1 阶段由 CTO 兼任编排，`09_techlead` 的 `enabled: false`，规模化后再启用。

---

## 六、说明

- 本仓库仅含**角色定义与配置**，不含任何业务代码或密钥。
- 技能运行所需的本地依赖（Python `.venv/`、Node `node_modules/`）和密钥文件（`.env`）均已在 `.gitignore` 中排除，**不入库**。需要自行按各 skill 的 `.env.example` 配置。

*团队总纲见 `CLAUDE.md`；各角色 persona 见各目录下的 `CLAUDE.md`（Claude）/ `AGENTS.md`（Codex）。*
