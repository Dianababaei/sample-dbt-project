# Artemis Sample Project - Documentation Index

## Quick Links

| Document | Purpose | Time |
|----------|---------|------|
| **ARTEMIS_START_HERE.md** | Entry point - navigation & overview | 2 min |
| **PROJECT_SUMMARY.txt** | Project statistics & status | 3 min |
| **README_FOR_ARTEMIS.md** | How to run & optimize | 5 min |
| **ARTEMIS_SAMPLE_PROJECT.md** | Complete technical reference | 15 min |
| **HANDOFF_TO_ARTEMIS.md** | Optimization guidelines & checklists | 10 min |

---

## What to Read First

👉 **Start with**: `ARTEMIS_START_HERE.md`

This file:
- Explains what the project is
- Shows how to run it in 60 seconds
- Points you to the right document for your needs

---

## What This Project Is

A **production-ready dbt project** with:
- ✅ 14 working models (100% pass rate)
- ✅ 65 automated tests (100% passing)
- ✅ Realistic SQL optimization opportunities
- ✅ Clear aggregated output table
- ✅ Complete documentation

**Output**: `BAIN_ANALYTICS.DEV.FACT_CASHFLOW_SUMMARY` (monthly portfolio cashflows)

---

## Running the Project

```bash
bash RUN_NOW.sh
```

Expected: ~30 seconds, ~0.5 Snowflake credits, 14/14 models ✅

---

## Optimization Task

**Goal**: Rewrite models to be faster/cheaper while producing identical output.

**Main target**: `models/pipeline_a/marts/fact_cashflow_summary.sql`

**Success criteria**:
- All 14 models build ✅
- All 65 tests pass ✅
- Output is identical ✅
- Faster execution ⚡
- Lower cost 💰

---

## Files in This Project

```
📁 models/
   └── pipeline_a/
       ├── staging/          (9 data transformation views)
       └── marts/
           └── fact_cashflow_summary.sql  (MAIN OPTIMIZATION TARGET)

📁 seeds/
   └── [13 CSV data files]  (financial data 2020-2024)

📄 dbt_project.yml         (configuration)
📄 profiles.yml            (Snowflake connection)
🚀 RUN_NOW.sh             (execute everything)
```

---

## Documentation Guide

Choose based on your needs:

### "I want a quick overview"
→ Read: `ARTEMIS_START_HERE.md` (2 minutes)

### "I want to run the project"
→ Read: `README_FOR_ARTEMIS.md` (5 minutes)

### "I want all the details"
→ Read: `ARTEMIS_SAMPLE_PROJECT.md` (15 minutes)

### "I want optimization guidelines"
→ Read: `HANDOFF_TO_ARTEMIS.md` (10 minutes)

### "I want project statistics"
→ Read: `PROJECT_SUMMARY.txt` (3 minutes)

---

## Status: ✅ Ready for Artemis

Everything is complete, functional, and documented.

**Next step**: Open `ARTEMIS_START_HERE.md`
