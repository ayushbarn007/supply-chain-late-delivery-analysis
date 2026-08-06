# Supply Chain Late Delivery Analysis (SQL Project)

## 📌 Overview
This project analyses a supply chain dataset to identify what actually drives **late deliveries**, using SQL for data cleaning, transformation, and bivariate analysis. The dataset covers 180,516 orders, including order, shipping, customer, product, and financial details.

The goal was not just to report percentages, but to test *which variables genuinely explain late delivery* versus which ones only appear to — a distinction that emerged as the central finding of this project.

---

## 🗂️ Dataset
- **Source file:** `supply_co_supply_chain_cleaned.csv`
- **Rows:** 180,516
- **Final cleaned table:** `supply_chain`

### Data Preparation Steps
- Dropped `Order State` (duplicate/unused) and `Product Image` (irrelevant to analysis)
- Merged `Order Date` + `Order Time` → `order_datetime`; `Shipping Date` + `Shipping Time` → `shipping_datetime`; original separate columns removed
- Renamed all columns to `snake_case`
- Moved `late_delivery_risk` to the last column, marking it as the target/outcome variable
- Removed **Canceled** and **Suspected Fraud** orders from delivery-related analysis, since these orders were never actually fulfilled

---

## ❓ Key Questions Answered
1. What percentage of orders are delivered late overall, and which order statuses should be excluded from this analysis?
2. Does shipping mode affect the likelihood of late delivery?
3. Are `shipping_mode` and `days_for_shipment_scheduled` actually two different variables, or the same information encoded twice?
4. Once shipping mode is accounted for, do region, category, customer state, market, segment, day of week, or month still meaningfully affect late delivery — or is shipping mode the dominant driver?
5. Which financial columns (`sales`, `order_item_total`, `order_profit_per_order`, etc.) are independently meaningful, and which are derived/redundant?
6. How much transaction value and profit is tied up in Canceled/Fraudulent orders that were never actually delivered?
7. Does profit margin vary meaningfully across shipping modes — and does that create a real trade-off between profitability and on-time delivery?

---

## 🔎 Methodology
1. **Univariate analysis** — examined each column individually against `late_delivery_risk` (shipping mode, scheduled/real shipping days, region, category, customer state/country, segment, payment type, product price, discount rate, profit ratio, weekday/month/year trends).
2. **Redundancy checks** — identified columns that were mathematically derived from others (e.g. `sales`, `order_item_total`, `order_profit_per_order`) and columns that encoded the same information twice (e.g. `shipping_mode` ≡ `days_for_shipment_scheduled`).
3. **Bivariate / combination analysis** — crossed `shipping_mode` against every other candidate variable (region, category, customer state, market, segment, day type, month) to test whether those variables added independent explanatory value or were simply riding on shipping mode.
4. **Anomaly investigation** — drilled into the most extreme finding (First Class = 100% late) to determine its root cause.

---

## 📊 Key Findings

### 1. Shipping mode is the dominant driver of late delivery
| Shipping Mode | Late Delivery % |
|---|---|
| First Class | 100.00% |
| Second Class | ~78–83% |
| Standard Class | ~36–42% |
| Same Day | ~44–52% |

No other variable came close to this spread on its own.

### 2. `shipping_mode` and `days_for_shipment_scheduled` are the same variable
Each shipping mode maps to exactly one scheduled-day value with zero overlap (e.g. First Class → 1 day, Standard Class → 4 days). They should be treated as a single feature, not two.

### 3. Nearly every other variable is flat once shipping mode is controlled for
Region, category, customer state, market, customer segment, weekday/weekend, and month were tested against `late_delivery_risk` **within** each shipping mode. In every case, the spread collapsed to a narrow few points (e.g. category spread narrowed from ~19.6 points standalone to ~6 points within Standard Class). These variables are secondary at best — shipping mode explains the overwhelming majority of the outcome.

### 4. First Class's 100% late rate is a structural artifact, not an operational failure
Investigation showed **all 27,813 First Class orders took exactly 2 days to ship, with zero variation** (std dev = 0), while the shipping promise (`days_for_shipment_scheduled`) is set at 1 day. Every First Class order is therefore guaranteed to be "late" by definition — the promised window is structurally shorter than the fixed real fulfillment time. This is confirmed by the fact that `late_delivery_risk = 1` matches `days_for_shipping_real > days_for_shipment_scheduled` for 100% of First Class rows.

By contrast, Same Day, Second Class, and Standard Class all show genuine variability in real shipping time (std dev 0.50–1.42 days), meaning late delivery in those modes reflects real, meaningful variation — not a fixed artifact.

### 5. Financial columns are largely derived, not independent
```
sales = product_price × order_item_quantity
order_item_discount = sales × order_item_discount_rate
order_item_total = sales − order_item_discount        (actual amount charged)
order_profit_per_order = order_item_total × order_item_profit_ratio   (actual profit)
```
`order_item_total` and `order_profit_per_order` are the meaningful "actual" transaction/profit figures; `sales` and `order_item_discount` are intermediate values feeding into them.

### 6. Profit margin is nearly flat across shipping modes
| Shipping Mode | Total Transaction Value | Total Profit | Margin % |
|---|---|---|---|
| Standard Class | $18,956,034.52 | $2,272,709.40 | 11.99% |
| First Class | $4,860,760.04 | $616,530.35 | 12.68% |
| Second Class | $6,160,630.86 | $722,861.47 | 11.73% |
| Same Day | $1,666,710.75 | $194,182.13 | 11.65% |

Shipping mode drives lateness dramatically (a 60+ point swing) but barely moves profit margin (about 1 point of spread) — meaning the "faster shipping = guaranteed late" problem isn't a profitable trade-off, it's a pure fulfillment/SLA design flaw.

---

## 💡 Business Recommendation
Since real First Class fulfillment consistently takes 2 days (not 1), the most effective and lowest-cost fix isn't necessarily switching customers to a different shipping mode (which would cost ~1 point of margin) — it's **correcting the First Class SLA to reflect the true 2-day fulfillment time**. This would eliminate the 100% late-delivery outcome for that tier at no cost to margin, since the operational cost/speed doesn't change — only the promise made to the customer does.

---

## 🗒️ Data Quality Notes
- `customer_country` contains only two values: `"United States"` and `"Trivial"` — the latter appears to be a placeholder/corrupted value rather than a genuine country (likely intended to represent Puerto Rico, given the high order volume under `PR` in `customer_state`).
- `late_delivery_risk` is likely partially or fully rule-derived (from `days_for_shipping_real` vs `days_for_shipment_scheduled`) rather than an independently observed outcome — a limitation worth noting when interpreting results as "real-world" behavior.
- `product_name` (118 unique values), `category_name` (50), and `department_name` (11) form a hierarchy; `category_name` was used as the representative product-type feature as the best balance between granularity and generalizability.

---

## 🛠️ Tools Used
- MySQL (data cleaning, transformation, and all analytical queries)
- Aggregate functions, `CASE WHEN` binning, `GROUP BY`/`HAVING`, window-style date functions (`DAYOFWEEK`, `MONTHNAME`, `DATE_FORMAT`)

---

## 📁 Files
- `supply_chain_cleaned_final.csv` — cleaned, transformed dataset used for all SQL analysis
