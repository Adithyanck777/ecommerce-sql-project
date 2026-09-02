# E-Commerce Performance Review — Key Insights & Recommendations

*Analysis period: Jan 2023 – Dec 2024 · 25,008 completed orders · 7,405 customers · R$48.1M revenue*
*Full queries: `/sql` · Interactive dashboard: `dashboard.html`*

## Key insights

**1. Revenue growth is real but decelerating, and heavily seasonal.**
Monthly revenue grew from R$0.8K (Jan 2023) to a peak of R$5.8M (Nov 2024) —
but month-over-month growth cooled from 500%+ in early 2023 (small-base
effect) to a steady 8–15% through most of 2024. Every November shows a
sharp spike (Black Friday / holiday shopping) followed by a December
pull-back, most visible in 2024 (Nov R$5.79M → Dec R$4.71M, a 19% drop).
**Recommendation:** build inventory and support staffing plans around the
November peak specifically, and treat December's dip as expected seasonality
rather than a demand problem.

**2. Two categories drive 60% of revenue but sit on the thinnest margins.**
`electronics` (R$16.7M, 13.1% margin) and `computers_tablets` (R$12.1M,
8.5% margin) together generate ~60% of gross revenue but only ~28% of
gross profit. By contrast, `fashion_accessories` (33.8% margin) and
`beauty_health` (28.9% margin) are comparatively small revenue lines with
2–4x the margin. **Recommendation:** don't chase more electronics volume
at current terms — push merchandising and bundle offers toward the
high-margin categories, and renegotiate supplier costs on electronics/
computers before scaling that spend further.

**3. Regional and order-frequency segments don't meaningfully change
average order value.** AOV varies only ~5% across regions (Central-West
R$1,980 vs. North R$1,879) and only ~3% across purchase-frequency segments.
**Recommendation:** don't build region-specific pricing or promotions
expecting an AOV lift — regional and frequency-based personalization
should target *what* customers buy, not how much they spend per order.

**4. Retention is healthy in aggregate (69.3% of customers are repeat
buyers) but churn risk is concentrated in high-value accounts.** 3,391
customers (46%) haven't ordered in 90+ days, representing R$13.5M in
historical lifetime value. Critically, RFM segmentation shows 832
customers (11%) sit in **"At-Risk High Value"** — they've historically
spent heavily (top monetary quartile) but have gone quiet — worth R$7.5M,
nearly as much as the entire "Loyal Customers" segment. **Recommendation:**
prioritize a targeted win-back campaign for the At-Risk High Value segment
specifically (not a blanket "come back" email) — the ROI per contact is far
higher than generic reactivation.

**5. Revenue is concentrated in a small "Champions" segment.** 2,118
customers (28.6% of the base) — recent, frequent, high-spend buyers — drive
60.5% of total revenue. **Recommendation:** protect this segment first:
a loyalty/VIP program or early-access perks for Champions likely has
better payback than acquisition spend, since losing even a small fraction
of this group has an outsized revenue impact.

## Suggested next steps
1. Stand up an automated "At-Risk High Value" alert (customers crossing
   the 90-day mark with historical LTV above the 75th percentile) feeding
   directly into a retention/CRM workflow.
2. Review electronics/computers supplier costs — a 3–5pt margin
   improvement there is worth more than a proportional revenue increase
   in low-margin categories.
3. Re-run the cohort retention query (`sql/04_cohort_retention.sql`)
   quarterly to track whether retention is improving or eroding as the
   customer base scales past its early cohorts.

