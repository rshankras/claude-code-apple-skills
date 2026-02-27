---
name: indie-business
description: Business fundamentals for indie app developers — LLC/entity setup, taxes, Apple Small Business Program, revenue tracking, hiring contractors, and financial planning for sustainability. Use when user asks about business setup, tax implications, hiring, or financial planning for their app business.
allowed-tools: [Read, Glob, Grep, AskUserQuestion, WebSearch]
---

# Indie Business Operations

Business fundamentals for indie Apple app developers. Covers the non-code aspects of running an app business — entity setup, taxes, revenue tracking, hiring, and financial planning.

**Disclaimer:** This skill provides general guidance, not legal or tax advice. Always consult a qualified accountant or attorney for your specific situation.

## When This Skill Activates

Use this skill when the user:
- Asks about business setup for their app (LLC, S-Corp)
- Wants to understand tax implications of app revenue
- Asks when to form an LLC or incorporate
- Wants guidance on hiring contractors or freelancers
- Asks about financial planning for going indie
- Mentions the Apple Small Business Program
- Wants to understand Apple's payment schedule and revenue tracking

## Process

### Step 1: Gather Context

Ask the user via AskUserQuestion:

1. **Location**: What country/state are you in? (tax implications vary significantly)
2. **Current status**: Full-time employed, part-time indie, or full-time indie?
3. **Revenue level**: Approximate monthly/annual app revenue (or expected if pre-launch)
4. **Business entity**: Do you currently have an LLC or company? Filing as sole proprietor?
5. **Specific question**: What business aspect are you trying to figure out?

### Step 2: Business Entity Options

#### United States

| Entity | Setup Cost | Annual Cost | Liability Protection | Tax Complexity | Best For |
|--------|-----------|-------------|---------------------|---------------|----------|
| Sole Proprietor | $0 | $0 | None | Lowest (Schedule C) | Hobby / early stage / < $10K/year |
| Single-Member LLC | $50-500 (state-dependent) | $0-800/year (state-dependent) | Yes | Low (pass-through) | Most indie developers |
| Multi-Member LLC | $50-500 | $0-800/year | Yes | Medium | Partnerships, co-founders |
| S-Corporation | $100-500 + legal fees | $500-2,000/year (payroll, filings) | Yes | High (payroll + corp return) | Revenue > $80-100K/year |

**Sole Proprietor**
- How: Just start earning. Report on Schedule C of personal tax return.
- Pros: Zero paperwork, zero cost, simplest possible setup.
- Cons: No personal liability protection. Your personal assets are at risk if someone sues.
- When to use: Testing the waters, revenue < $10K/year, minimal risk app (no user data, no health claims).

**Single-Member LLC (Recommended for Most Indie Devs)**
- How: File articles of organization with your state. Get an EIN from the IRS (free).
- Pros: Personal liability protection, flexible tax treatment, professional credibility, separate bank account.
- Cons: Annual state fees ($0 in many states, $800/year in California), must maintain separation between personal and business finances.
- When to upgrade from sole proprietor: Revenue exceeds $10-20K/year, OR you handle user data, OR users rely on your app for health/finance/safety.

**S-Corporation Election**
- How: Form an LLC, then file Form 2553 to elect S-Corp tax treatment.
- Pros: Payroll tax savings on profits above "reasonable salary." At $150K revenue, could save $10-15K/year in self-employment tax.
- Cons: Must pay yourself a "reasonable salary" with payroll, quarterly payroll tax filings, more complex bookkeeping, annual corporate tax return.
- When to consider: Net profit consistently exceeds $80-100K/year.

**When to upgrade entity (decision tree):**
```
Revenue < $10K/year and low-risk app?
├── YES → Sole proprietor is fine
└── NO → Do you handle sensitive user data or have liability risk?
    ├── YES → Form an LLC now
    └── NO → Revenue > $20K/year?
        ├── YES → Form an LLC
        └── NO → Sole proprietor, but plan for LLC soon

Already have an LLC and net profit > $80K/year?
├── YES → Talk to a CPA about S-Corp election
└── NO → Stay as LLC
```

#### United Kingdom

| Entity | Best For |
|--------|----------|
| Sole Trader | Revenue < GBP 50K, simple setup |
| Limited Company (Ltd) | Revenue > GBP 50K, liability protection, tax efficiency |

- Sole trader: Register with HMRC for Self Assessment. Simple but no liability protection.
- Ltd company: Register with Companies House. Corporation tax on profits (25%), then dividend tax on drawings. More tax-efficient at higher revenue.

#### European Union (General Guidance)

- Most EU countries have sole proprietor equivalents and limited liability company options.
- VAT registration thresholds vary by country (but Apple handles VAT on app sales).
- Consider your country's social security implications for self-employment income.
- Consult a local accountant — EU tax rules are country-specific.

#### India

| Entity | Best For |
|--------|----------|
| Sole Proprietor | Starting out, simple |
| LLP (Limited Liability Partnership) | Liability protection, flexible |
| Private Limited Company | Scale, investors, credibility |

- GST registration may be required above threshold (currently INR 20 lakh).
- TDS (Tax Deducted at Source) applies to payments from Apple (check DTAA with Ireland/US).
- Private Limited preferred if you plan to raise investment.

### Step 3: Apple Small Business Program

#### Overview

- Commission reduced from 30% to 15% on the first $1M in annual proceeds.
- Applies to all app and in-app purchase revenue.
- Auto-enrollment: Apple enrolls you when you are eligible. No application needed if under $1M.
- Resets annually on January 1.

#### Impact Calculation

| Annual Revenue | Standard (30%) | Small Business (15%) | You Save |
|---------------|----------------|---------------------|----------|
| $10,000 | $3,000 | $1,500 | $1,500 |
| $50,000 | $15,000 | $7,500 | $7,500 |
| $100,000 | $30,000 | $15,000 | $15,000 |
| $500,000 | $150,000 | $75,000 | $75,000 |
| $1,000,000 | $300,000 | $150,000 | $150,000 |

For year-2+ subscribers, Apple takes only 15% regardless of program enrollment. So the Small Business Program primarily benefits:
- Paid upfront apps
- One-time IAP revenue
- First-year subscription revenue

#### Important Details

- If you exceed $1M in a calendar year, the standard 30% rate applies for the remainder of that year.
- Revenue from all apps under your developer account is combined for the $1M threshold.
- If you have multiple developer accounts (e.g., personal + company), each is evaluated separately.

### Step 4: Tax Basics for App Revenue

#### What Apple Handles (You Don't Need to Worry About)

- **Sales tax / VAT**: Apple collects and remits sales tax, VAT, and equivalent taxes in virtually all jurisdictions. The price users pay includes these taxes, and Apple deducts them before your payout.
- **Tax forms to developers**: Apple provides 1099-MISC (US) or equivalent tax documentation annually.

#### What You Must Handle

**Reporting Income (US)**

Apple pays you monthly. All payouts are taxable income.

| Entity | How to Report | Tax Form |
|--------|--------------|----------|
| Sole Proprietor | Schedule C on personal return (1040) | 1040 + Schedule C + Schedule SE |
| Single-Member LLC | Same as sole proprietor (disregarded entity) | 1040 + Schedule C + Schedule SE |
| Multi-Member LLC | Partnership return | 1065 + K-1s |
| S-Corporation | Corporate return + salary W-2 | 1120-S + W-2 |

**Quarterly Estimated Taxes (US)**

If you expect to owe more than $1,000 in taxes for the year, you must make quarterly estimated payments. Missing these results in penalties.

| Quarter | Covers | Due Date |
|---------|--------|----------|
| Q1 | Jan-Mar | April 15 |
| Q2 | Apr-May | June 15 |
| Q3 | Jun-Aug | September 15 |
| Q4 | Sep-Dec | January 15 (next year) |

**How to estimate:** Take your expected annual net profit, multiply by your effective tax rate (federal + state + self-employment). Divide by 4.

**Deductible Expenses**

These reduce your taxable income. Keep receipts and records for everything.

| Expense | Example | Deductible? |
|---------|---------|------------|
| Apple Developer Program | $99/year | Yes |
| Hardware | Mac, iPhone, iPad for development | Yes (may need to depreciate) |
| Software | Xcode is free, but design tools, analytics, etc. | Yes |
| Hosting | Server costs, API services, CDN | Yes |
| Design | Freelance designer for app icon, screenshots | Yes |
| Marketing | Ad spend, press kit costs | Yes |
| Home office | Portion of rent/mortgage (if dedicated space) | Yes (with rules) |
| Conference travel | WWDC, local meetups | Yes |
| Education | Courses, books, tutorials for development skills | Yes |
| Professional services | Accountant, lawyer fees | Yes |
| Internet | Business portion of home internet | Partially |
| Health insurance (US) | Self-employed health insurance deduction | Yes (if self-employed) |

**International Considerations**

- If you sell apps globally, Apple handles international tax collection.
- US developers: file W-9 with Apple. Non-US developers: file W-8BEN or W-8BEN-E.
- Tax treaties between your country and Ireland/US may reduce withholding.
- Some countries require you to report worldwide income, including Apple payouts.

### Step 5: Revenue Tracking and Bookkeeping

#### Apple's Payment Schedule

- Apple pays monthly, approximately 33 days after the end of their fiscal month.
- Apple's fiscal months don't always align with calendar months (check your agreement).
- Payments are made via direct deposit to your bank account.
- Minimum payout threshold varies by region (often $10-150 depending on country).

#### Bookkeeping Setup

**Option 1: Spreadsheet (Free, < $50K revenue)**

Track monthly:
```
Month | Gross Revenue | Apple Commission | Net Revenue | Expenses | Net Profit
Jan   | $1,200        | $180             | $1,020      | $150     | $870
Feb   | $1,350        | $203             | $1,148      | $99      | $1,049
...
```

Categories to track:
- Gross revenue (total sales)
- Apple commission (15% or 30%)
- Net revenue (what Apple pays you)
- Development expenses
- Marketing expenses
- Tools and services
- Professional services
- Net profit (net revenue minus all expenses)
- Tax set-aside (25-35% of net profit)

**Option 2: Accounting Software ($50K+ revenue or if you want automation)**

| Software | Cost | Best For |
|----------|------|----------|
| Wave | Free | Simple invoicing and tracking |
| QuickBooks Self-Employed | $15/mo | US sole proprietors, auto-categorization |
| QuickBooks Online | $30/mo | LLCs and S-Corps, full accounting |
| Xero | $13/mo | International, clean interface |
| Bench | $249/mo | Full bookkeeping service (they do it for you) |

**Tax Reserve Rule**

Set aside 25-35% of net revenue (after Apple's cut) for taxes.

| Tax Component (US) | Approximate Rate |
|--------------------|-----------------|
| Federal income tax | 12-37% (bracket-dependent) |
| Self-employment tax | 15.3% (on first ~$160K) |
| State income tax | 0-13% (state-dependent) |
| **Combined effective rate** | **25-40%** |

Open a separate savings account. Every time Apple pays you, transfer 30% of the payout into the savings account. Use this account only for quarterly tax payments.

### Step 6: When to Hire

Hiring too early burns cash. Hiring too late burns you out. Use these guidelines.

#### Designers

**When to hire:**
- Your app icon looks amateurish compared to competitors
- Users comment on visual design in reviews
- You have maxed out SF Symbols and system UI components
- You need a marketing website, press kit, or App Store screenshots

**What to pay:**
- App icon: $200-1,000 (one-time)
- Full app design: $2,000-10,000 (one-time)
- Ongoing design: $50-150/hour (contract)

**Where to find:**
- Dribbble, Behance (portfolios)
- Twitter/X indie design community
- Referrals from other indie developers

#### Customer Support

**When to hire:**
- You spend > 5 hours/week on support emails
- Response time > 48 hours (users notice)
- Support is taking time away from development

**What to pay:**
- Part-time VA: $15-30/hour
- Dedicated support: $2,000-4,000/month

**Where to find:**
- Online communities for virtual assistants
- Referrals from other indie developers
- Start with a part-time contractor, not full-time

#### Marketing

**When to hire:**
- You have confirmed product-market fit (good retention)
- You know your acquisition cost and LTV
- Growth is limited by awareness, not product quality

**What to pay:**
- Freelance marketing: $50-150/hour
- ASO consultant: $500-2,000/month
- Content creator: $100-500/post

#### Contract Developers

**When to hire:**
- One-time platform expansion (watchOS, macOS port, widgets)
- Feature that requires expertise you lack (ML, AR, accessibility)
- You want to ship faster for a specific launch window

**What to pay:**
- iOS developer (contract): $75-200/hour
- Specialized (ML, AR): $100-250/hour
- Fixed-price project: define scope clearly, include revisions

#### Budget Rule

Do not hire until you can pay for 3 months from app revenue. Do not use personal savings to hire for a side project. The app should fund its own growth.

```
Can you pay this person for 3 months from app revenue alone?
├── YES → Hire (start with a trial project / 1-month contract)
└── NO → Wait until revenue supports it, or do it yourself
```

### Step 7: Insurance and Liability

#### Professional Liability Insurance (Errors and Omissions)

- Covers claims that your app caused harm due to errors, bugs, or bad advice.
- Cost: $500-1,500/year for indie developers.
- Consider if: your app gives health, financial, or safety-related advice.
- Providers: Hiscox, Hartford, biBERK, general business insurance brokers.

#### Cyber Liability Insurance

- Covers data breach costs (notification, credit monitoring, legal defense).
- Cost: $500-2,000/year depending on data volume.
- Consider if: you store personal user data on your servers.
- Less relevant if: your app is fully offline / on-device only.

#### LLC as Liability Shield

- An LLC separates your personal assets from business liabilities.
- If someone sues your app business, they cannot (generally) take your house or personal savings.
- Must maintain separation: separate bank account, do not commingle funds, sign contracts as the LLC.
- An LLC does NOT protect you from personal negligence or fraud.

### Step 8: Financial Planning for Indie Sustainability

#### Before Going Full-Time Indie

Checklist:
- [ ] 6 months of personal expenses saved (emergency fund)
- [ ] App revenue covers at least 50% of personal expenses (and growing)
- [ ] Health insurance sorted (US: marketplace, spouse's plan, or COBRA)
- [ ] Tax situation understood (talked to CPA)
- [ ] Spouse/partner on board with the plan and timeline
- [ ] Defined a "go back" threshold (if revenue drops below $X for Y months)

#### Revenue Milestones

| Monthly Net Revenue | What It Means | Action |
|--------------------|---------------|--------|
| $100-500/mo | Hobby money | Reinvest in tools, keep your day job |
| $500-2,000/mo | Side income | Cover app-related expenses, start saving |
| $2,000-5,000/mo | Part-time viable | Could reduce day job hours (if flexible) |
| $5,000-10,000/mo | Full-time viable (LCOL) | Full-time possible with lower cost of living |
| $10,000+/mo | Full-time viable (most areas) | Sustainable indie business |

Note: These are NET revenue figures (after Apple's cut and expenses, before taxes). Adjust for your location's cost of living.

#### Multiple Revenue Streams

Do not depend on a single app for your entire income. Strategies for diversification:

| Stream | Effort | Revenue Potential | Risk |
|--------|--------|-------------------|------|
| Second app | High | High | Platform risk |
| Consulting/freelancing | Medium | Medium-High | Time-limited |
| Technical writing | Low-Medium | Low-Medium | Consistent |
| Course/tutorial creation | High (upfront) | Medium (recurring) | One-time effort |
| Open source sponsorship | Low | Low | Unpredictable |
| Conference speaking | Low | Low (+ networking) | Seasonal |

**Recommended portfolio for sustainability:**
- 1-2 apps generating recurring revenue (primary income)
- Part-time consulting/freelancing (stable fallback)
- Content creation / writing (builds authority, generates leads for consulting)

#### Runway Calculation

```
Monthly personal expenses:        $______
Monthly app net revenue:           $______
Monthly consulting revenue:        $______
Total monthly income:              $______

Monthly surplus/deficit:           $______ (income - expenses)
Emergency fund balance:            $______
Runway (months):                   emergency fund / monthly expenses = ______ months

Sustainability ratio:              monthly income / monthly expenses = ______
                                   > 1.0 = sustainable
                                   > 1.5 = comfortable
                                   > 2.0 = thriving
```

## Output Format

Present business guidance as:

```markdown
# Indie Business Assessment: [User's Situation]

## Current Status
**Location:** [Country/State]
**Entity:** [Current entity type]
**Revenue:** [Approximate level]
**Status:** [Full-time employed / Part-time indie / Full-time indie]

## Recommendations

### Business Entity
**Recommendation:** [Entity type]
**Why:** [1-2 sentences]
**Action items:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Tax Obligations
- [ ] [Specific tax obligation based on their situation]
- [ ] [Another obligation]
**Estimated tax rate:** [X-X%]
**Quarterly payment amount:** ~$[X]

### Financial Health
| Metric | Current | Target |
|--------|---------|--------|
| Monthly net revenue | $X | $X |
| Expense ratio | X% | < 30% |
| Tax reserve | $X | $X |
| Emergency fund | X months | 6 months |
| Sustainability ratio | X.X | > 1.5 |

### Next Steps (Priority Order)
1. 🔴 [Most urgent action]
2. 🟠 [Important but not urgent]
3. 🟡 [Plan for this quarter]
```

## References

- **analytics-interpretation/** — For understanding if your metrics support business decisions
- **monetization/** — For pricing strategy and revenue model selection
- **community-building/** — For organic growth that reduces acquisition costs
- Apple Small Business Program: https://developer.apple.com/app-store/small-business-program/
