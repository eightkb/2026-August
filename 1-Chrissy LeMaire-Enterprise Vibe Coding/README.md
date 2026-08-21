# Enterprise Vibe Coding

While Spotify's top engineers have not written a line of code in 2026 and Claude now authors more than 80% of everything Anthropic merges, a Cursor agent running Claude Opus 4.6 deleted PocketOS's production database and every backup in nine seconds, using an over-permissioned API token it found in an unrelated file.

Meanwhile Liquibase reports that 96.5% of organizations now have AI touching their production databases, and only 28.1% have database change governance that is standardized and actually enforced.

The difference between these outcomes is governance and specifically, automated enforcement baked into the generation step itself. Veracode's Spring 2026 data shows why that matters: across more than 150 models, syntax correctness is above 95%, yet about 55% of AI-generated code still contains a known security vulnerability when no security guidance is given.

This session walks through a concrete methodology for AI-assisted development aimed at DBAs, demonstrated through a neutral SQL Server automation codebase. It shows how a hook system uses events such as UserPromptSubmit, PreToolUse, PostToolUse, and Stop to enforce standards inside the generation loop itself, turning blocked actions into instructions the model can use to correct course before risky changes land.

You'll walk out with the mental model, the hook patterns, and the workflow to bring AI-assisted development into your environment without losing control of it.

## Sources

Stats verified August 2026. Dates matter for this topic: an unqualified 2025 number will get challenged from the floor.

**Adoption**

- Anthropic 80%+ merged code, 8x per-engineer output, quality parity by May 2026: [VentureBeat](https://venturebeat.com/technology/anthropic-says-80-of-its-new-production-code-is-now-authored-by-claude-how-your-enterprise-can-keep-up)
- Spotify: 99%+ weekly AI use, 94% report productivity gain, +76% PR frequency: [Spotify Engineering, June 2026](https://engineering.atspotify.com/2026/6/code-with-claude-coding-is-no-longer-the-constraint); CEO quote via [AOL](https://www.aol.com/articles/spotify-ceo-says-top-developers-103101715.html)
- Shopify AI-first playbook: [Bessemer](https://www.bvp.com/atlas/inside-shopifys-ai-first-engineering-playbook)
- Walmart 4M developer hours, expanding rollout: [CIO Dive](https://www.ciodive.com/news/Walmart-generative-AI-agents-coding-tool/740545/), [Walmart Global Tech](https://tech.walmart.com/content/walmart-global-tech/en_us/blog/post/empowering-developers-with-ai.html)
- Torvalds, July 17 2026: [Tom's Hardware](https://www.tomshardware.com/software/linux/linus-torvalds-rebukes-anti-ai-stances-in-the-linux-kernel-code-review-process-says-linux-is-not-one-of-those-anti-ai-projects-creator-embraces-ai-as-just-a-tool-and-clearly-a-useful-one), [The Decoder](https://the-decoder.com/linus-torvalds-tells-ai-critics-in-the-linux-kernel-community-to-fork-off/), [Slashdot](https://linux.slashdot.org/story/26/07/17/1830258/linus-torvalds-to-critics-of-ai-coding-on-linux-fork-it-or-just-walk-away)
- Market sizing (note the conflicting scopes): [Mordor Intelligence](https://www.mordorintelligence.com/industry-reports/vibe-coding-market)

**Incidents**

- PocketOS, April 25 2026: [The Register](https://www.theregister.com/2026/04/27/cursoropus_agent_snuffs_out_pocketos/), [Euronews](https://www.euronews.com/next/2026/04/28/an-ai-agent-deleted-a-companys-entire-database-in-9-seconds-then-wrote-an-apology), [Zenity analysis](https://zenity.io/blog/current-events/ai-agent-database-deletion-pocketos)
- SQL Server community coverage of PocketOS: [sqlfingers.com](https://www.sqlfingers.com/2026/05/ai-agent-nine-seconds-one-production.html)

**Evidence**

- Veracode Spring 2026 GenAI Code Security Report (150+ models, ~55% vulnerable, 95%+ syntactically correct): [Veracode](https://www.veracode.com/blog/spring-2026-genai-code-security/)
- Liquibase 2026 State of Database Change Governance (426 respondents; 96.5% / 28.1% / 42.3% / 68.1%): [Liquibase](https://www.liquibase.com/resources/reports/2026-state-of-database-change-governance-report), [Business Wire](https://www.businesswire.com/news/home/20260311497754/en/Liquibase-2026-Report-Finds-AI-Now-Interacts-With-Production-Databases-in-96.5-of-Organizations-as-Governance-Automation-Lags)
- METR original, July 2025: [METR](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/); **design change and revised figures, Feb 24 2026**: [METR](https://metr.org/blog/2026-02-24-uplift-update/)

**Governance and open source**

- Sashiko: 53% of 1,000 unfiltered upstream bugs, ~20% false positives: [The Register](https://www.theregister.com/2026/03/20/sashiko_code_review_linux/), [Phoronix](https://www.phoronix.com/news/Sashiko-Linux-AI-Code-Review), [GitHub](https://github.com/sashiko-dev/sashiko)
- curl bug bounty shutdown: [The Register](https://www.theregister.com/2026/01/21/curl_ends_bug_bounty/), [BleepingComputer](https://www.bleepingcomputer.com/news/security/curl-ending-bug-bounty-program-after-flood-of-ai-slop-reports/); **current policy in Stenberg's own words**: [curl.se/docs/bugbounty.html](https://curl.se/docs/bugbounty.html), [daniel.haxx.se](https://daniel.haxx.se/blog/)
- GCC LLM policy, July 29 2026: [Phoronix](https://www.phoronix.com/news/GCC-Declining-AI-Contributions), [Linuxiac](https://linuxiac.com/gcc-adopts-policy-rejecting-significant-ai-generated-code/)
- Cross-project policy comparison (curl, Ghostty, tldraw, kernel, LLVM, QEMU, Zig, typescript-eslint): [codenote.net](https://codenote.net/en/posts/oss-ai-slop-contribution-policy-shift/)
- David Fowler, *AI Made Us Faster. That Was the Problem*: [LinkedIn](https://www.linkedin.com/pulse/ai-made-us-faster-problem-david-fowler-mgnzc)
