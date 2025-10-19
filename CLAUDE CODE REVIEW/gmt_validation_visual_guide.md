# Green Man Tavern - Validation Visual Reference
**Quick Visual Guides for Your Quality Assurance System**

---

## 📊 Complete System at a Glance

```
YOUR DEVELOPMENT PROCESS

┌─────────────────────────────────────────────────────────────┐
│                      You Write Code                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│         Check Against .claude/project_standards.md          │
│         ✓ LiveView→Context→DB pattern?                      │
│         ✓ User ownership filter?                            │
│         ✓ Documented?                                       │
│         ✓ Tests added?                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Commit Code to Git                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │  Every Monday │
                    │   (5 min)     │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│        WEEKLY: Health Check (minor issues only)             │
│        Claude Code: "Quick structural health check"         │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │ Every Thursday│
                    │   (10 min)    │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│     BI-WEEKLY: Architecture Drift (patterns working?)       │
│     Claude Code: "Architecture drift detection"             │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │  1st of Month │
                    │   (15 min)    │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│      MONTHLY: Integration Test (everything working?)        │
│      Claude Code: "Full end-to-end integration test"        │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ┌───────────────┐
                    │ Quarter End   │
                    │   (30 min)    │
                    └───────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  QUARTERLY: Deep Audit (compare to baseline, trends?)       │
│  Claude Code: "Comprehensive quarterly deep audit"          │
└─────────────────────────────────────────────────────────────┘
                            ↓
                        READY TO SHIP?
                     (Before Deployment)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│   PRE-DEPLOYMENT: Security + Performance + Checklist        │
│   Claude Code: "Pre-deployment checklist"                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    PASS? YES → DEPLOY
                    FAIL? NO → FIX FIRST
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Ship to Production Confidently                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Issue Severity Color Codes

```
🔴 CRITICAL (Fix Immediately)
   - Data breach vulnerability
   - User A accessing User B's data
   - SQL injection risk
   - Authentication bypass
   - Direct database queries in LiveView
   - Fix: BEFORE any other work

🟡 HIGH (Fix This Sprint)
   - Missing user ownership filters
   - Performance regression (>20% slower)
   - Missing tests for core features
   - Architectural pattern violation
   - Security weakness (not critical)
   - Fix: Within 1 sprint

🟠 MEDIUM (Fix This Quarter)
   - Code duplication
   - Missing @doc comments
   - Suboptimal database queries
   - Technical debt
   - Nice-to-have refactoring
   - Fix: Before next release

🟢 LOW (Nice to Have)
   - Style improvements
   - Documentation enhancement
   - Minor optimization
   - Code cleanup
   - Fix: When you have time

IGNORE (Already Good)
   - ✅ Pattern working correctly
   - ✅ Code well documented
   - ✅ Tests comprehensive
   - ✅ No issues found
   - Action: Continue current practice
```

---

## 📅 Audit Schedule Calendar

```
         January
Su Mo Tu We Th Fr Sa
             1  2  3
 4  5  6  7  8  9 10
11 12 13 14 15 16 17
18 19 20 21 22 23 24  ← Weekly check (Mon 9am)
25 26 27 28 29 30 31  ← Quarterly deep audit (end of month)

WEEKLY (Every Monday):
Mon: 🟢 Weekly Health (5 min)
  
BI-WEEKLY (Every Thursday):
Thu: 🟢 Architecture Drift (10 min)
  
MONTHLY (1st of month):
1st: 🟡 Full Integration Test (15 min)
  
QUARTERLY (End of each quarter):
31st: 🟠 Deep Audit (30 min)
  
BEFORE DEPLOYMENT:
Any day: 🔴 Pre-Deployment Checklist (20 min)
```

---

## 📊 Metrics Dashboard Template

```
GREEN MAN TAVERN - CODE QUALITY DASHBOARD
Last Updated: 2025-01-20

┌────────────────────────────────────┐
│ Test Coverage: 58% (Target: 75%)   │
│ ▓▓▓▓▓░░░░░░░░░░░░░░░░             │
│ ↑ Up 3% from last week             │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Critical Issues: 0 (Target: 0)     │
│ Status: ✅ HEALTHY                 │
│ ↓ Down from 3 last week (FIXED!)   │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ High-Priority Issues: 2 (Target: 0)│
│ • Missing index on user_systems    │
│ • MindsDB context overflow risk    │
│ Expected fix: This week            │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Architecture Conformance: 95%       │
│ ▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░        │
│ ↑ Improved after fixing violation  │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Avg Page Load Time: 1.2s           │
│ Target: < 2s  ✅ PASS              │
│ ↓ Down from 1.4s (optimization!)   │
└────────────────────────────────────┘

┌────────────────────────────────────┐
│ Last Deployment: 3 days ago        │
│ Time to deploy: 45 minutes         │
│ Issues caught pre-deployment: 2    │
│ Issues found by users post-deploy: 0 ✅
└────────────────────────────────────┘
```

---

## 🔄 Document Flow

```
START HERE (You are here →)

    ↓
    
MASTER SUMMARY
├─ What are we building?
├─ How does it work?
└─ 30,000 foot view (this doc)
    
    ↓ YES, I'm ready to start
    
QUICK START GUIDE
├─ Step 1: Create project_standards.md
├─ Step 2: Create AUDIT_