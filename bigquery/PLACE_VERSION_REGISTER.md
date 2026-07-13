# Place Version Register

A register of Roblox `place_version` numbers seen in analytics, what shipped in
each, and when it went live. **Every GA4 event carries `place_version`** (stamped
in `event_params` by `AnalyticsService`). Analytics that don't segment by version
will silently mix pre- and post-change behaviour.

> **Why this exists:** a code change and an analytics pass can race — data
> collected on the *old* build gets read as if it reflected the *new* one, and a
> correct baseline looks like a broken feature. Segment every experiment/economy
> metric by `place_version` and check this register before attributing a result
> to a change.
>
> `place_version` is Roblox's own publish counter (`game.PlaceVersion`): it
> auto-increments on every Studio publish, is monotonic (so BigQuery can
> range-filter "everything since v45"), and is `0` in unpublished Studio
> sessions. `place_id` rides alongside it to tell dev and prod places apart.

## Register

_Add a row each time you publish a build whose behaviour you'll want to isolate
in analytics. Map the version to the git commit/tag that produced it._

| place_version | Live from (UTC) | Live to (UTC) | Summary | Notes for analytics |
|---|---|---|---|---|
| _(none recorded yet)_ | | | | |

## Detecting a new version (run at the start of any analytics pass)

Replace `PROJECT.DATASET` with your values from `bigquery/.analytics-config.json`
and `YYYYMMDD` with a recent table date.

```sql
SELECT
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key='place_version') AS place_version,
  COUNT(*) AS events,
  COUNT(DISTINCT user_id) AS users,
  TIMESTAMP_MICROS(MIN(event_timestamp)) AS first_utc,
  TIMESTAMP_MICROS(MAX(event_timestamp)) AS last_utc
FROM `PROJECT.DATASET.events_YYYYMMDD`
GROUP BY place_version
ORDER BY place_version
```

If a `place_version` appears that isn't in the table above, add a row (map it to
the git commit/tag that published it) before drawing conclusions from that day's
data.
