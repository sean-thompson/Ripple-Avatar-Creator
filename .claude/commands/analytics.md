---
description: Analyse GA4 analytics data from BigQuery — heatmaps, sessions, actions, insights
allowed-tools: mcp__bigquery__query, Bash, Read, Write, Glob, AskUserQuestion
model: sonnet
---

I'll help you analyse your GA4 analytics data from BigQuery. This command guides you through querying and interpreting your game's analytics.

## Prerequisites Check

Before doing anything else, verify:

1. **BigQuery MCP is available**: Check that the `mcp__bigquery__query` tool is accessible. If not, stop and tell the user:
   ```
   BigQuery MCP server is not connected. To set it up:
   1. Create a service account in Google Cloud with BigQuery Data Viewer + BigQuery Job User roles
   2. Download the JSON key file
   3. Run: claude mcp add bigquery -s user -- npx -y @ergut/mcp-bigquery-server --project-id YOUR_PROJECT --location YOUR_REGION --key-file /path/to/key.json
   4. Restart Claude Code
   ```

2. **Analytics config**: Check if `bigquery/.analytics-config.json` exists. If not, this is the first run — proceed to Dataset Discovery.

## Dataset Discovery (First Run Only)

If `bigquery/.analytics-config.json` doesn't exist:

1. Ask the user for their **BigQuery project ID** (e.g., `roblox-template-analytics`)
2. Query BigQuery to list available datasets: `SELECT schema_name FROM INFORMATION_SCHEMA.SCHEMATA`
3. Show datasets matching `analytics_*` pattern and ask the user to confirm which one
4. Save to `bigquery/.analytics-config.json`:
   ```json
   {
     "projectId": "roblox-template-analytics",
     "dataset": "analytics_528555006"
   }
   ```

## View Setup (First Run Only)

After dataset discovery, check if views exist by querying:
```sql
SELECT table_name FROM `PROJECT.DATASET.INFORMATION_SCHEMA.VIEWS` WHERE table_name LIKE 'v_%'
```

If views are missing, create them by:
1. Reading each SQL file from `bigquery/views/`
2. Replacing `DATASET_PLACEHOLDER` with `PROJECT.DATASET` (from config)
3. Running each CREATE OR REPLACE VIEW statement via `mcp__bigquery__query`

Confirm: "Views created: v_heatmap, v_controller_actions, v_sessions, v_events"

## Analysis Wizard

### Step 1: What do you want to know?

Ask the user what they'd like to explore:

1. **Heatmap** — Where do players spend time? Hot zones, dead zones, spatial patterns.
2. **Action analysis** — Which controller actions are most/least popular? Feature adoption over time.
3. **Session metrics** — Average session length, daily active users, retention patterns.
4. **Player flow** — What do players do first? What sequences lead to leaving? Action ordering.
5. **Demographics** — Player breakdown by country, locale, membership type.
6. **Insights** — Holistic analysis across all data. Identify patterns, anomalies, and actionable findings.
7. **Custom query** — Describe what you want in natural language. I'll write and run the SQL.

### Step 2: Date Range

Ask: "What date range? (default: last 7 days, or specify e.g. '2026-03-10 to 2026-03-17')"

Apply date filtering using `_TABLE_SUFFIX` for cost efficiency:
```sql
WHERE _TABLE_SUFFIX BETWEEN '20260310' AND '20260317'
```

### Step 3: Run Queries and Analyse

**For each analysis type, use the appropriate view:**

#### Heatmap
Query `v_heatmap`. Aggregate by cell_x, cell_z. Identify:
- Hottest cells (highest player_seconds or dwell_seconds)
- Cold/dead zones (cells with zero or near-zero activity)
- Clusters and spatial patterns
- After presenting text analysis, ask: "Would you like me to generate a heatmap image?"

If yes, run the heatmap renderer:
1. Check `bigquery/.venv/` exists. If not, create it:
   ```bash
   cd bigquery && python -m venv .venv && .venv/Scripts/pip install -r requirements.txt
   ```
   (Use `.venv/bin/pip` on macOS/Linux)
2. Format query results as JSON: `[{"cell_x": N, "cell_z": N, "value": N}, ...]`
3. Pipe to heatmap.py:
   ```bash
   echo '<json>' | cd bigquery && .venv/Scripts/python scripts/heatmap.py --title "Player Heatmap (last 7 days)" --output output/heatmap.png
   ```
4. Tell the user: "Heatmap saved to bigquery/output/heatmap.png"

#### Action Analysis
Query `v_controller_actions`. Calculate:
- Total actions by controller_name and action_name (ranked by count)
- Actions per unique user (engagement depth)
- Action frequency over time (daily trend)
- Least-used actions (potential dead features)

#### Session Metrics
Query `v_sessions`. Calculate:
- Total sessions and unique users
- Average, median, min, max session duration
- Sessions per day (trend)
- New vs returning users (based on first_seen date if available)

#### Player Flow
Query `v_controller_actions` ordered by event_time per user. Analyse:
- Most common first action after joining
- Most common action sequences (bigrams)
- Actions that correlate with longer sessions
- Last action before leaving (from player_leave events)

#### Demographics
Query `v_sessions`. Break down by:
- Country distribution (top 10)
- Locale distribution
- Membership type split
- Cross-reference: do certain countries have different session lengths?

#### Insights
Run queries across ALL views. Then provide holistic analysis:
- What stands out? What's surprising?
- Are there dead zones in the map?
- Are there underused features?
- Do certain player demographics behave differently?
- What actionable recommendations can you make?

#### Custom Query
The user describes what they want. Write SQL against the views (v_heatmap, v_controller_actions, v_sessions, v_events) and run it. Explain the results.

## Important Notes

- Always use `_TABLE_SUFFIX` filtering for date ranges to control query costs
- Default to last 7 days if the user doesn't specify
- Present text analysis first, offer visualisations on request
- When showing numbers, include context (e.g., "847 player-seconds in cell (3,5) — that's 3x the average")
- For insights, go beyond raw numbers — identify patterns, anomalies, and make recommendations
- If a query returns no data, suggest the user check their date range or whether the relevant events are being tracked
