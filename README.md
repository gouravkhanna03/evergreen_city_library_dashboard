# 📚 Library Management Analytics Dashboard (End-to-End Power BI Project)

> A complete **data analytics project** built using **PostgreSQL and Power BI**, designed to analyze library operations — book loans, inventory, members, payments, reviews, and staff insights.

---

## 🧩 Project Overview

This project simulates how a real library system can utilise data to monitor daily operations and enhance decision-making—showcasing a realistic, business-ready dashboard that a library manager can use daily.



📊 **Goal:**  
I built the project end-to-end — from **SQL data modelling and views** to **interactive Power BI dashboards** — to answer key business questions like:
- Which books and authors are most in demand?
- How many books are overdue and why?
- Is inventory sufficient to meet demand?
- How active and valuable are library members?
- How do reviews and ratings reflect book quality?

---

## ⚙️ Tech Stack

| Tool | Purpose |
|------|--------|
| 🐙 **Excel** | Data Audit & Data Preparation |
| 🗃️ **PostgreSQL** | Data storage, joins, aggregations, SQL Views |
| 📊 **Power BI** | Data modeling, DAX, dashboard visualization |
| 🧮 **DAX** | KPIs, measures, parameters, logic |
| 🐙 **Figma** | Dashboard UI/UX |
| ☁️ **Power BI Service** | Publishing & scheduled refresh |
| 🐙 **GitHub** | Project documentation & portfolio |


---

## 🧮 Dataset Overview

The dataset represents a complete library ecosystem and includes the following tables:

| Table | Description |
|------|-------------|
| **books** | Book details, price, and stock |
| **authors** | Author names and nationality |
| **genres** | Book genres |
| **book_loans** | Loan, due date, return date, and fines |
| **payments** | Member payments and payment types |
| **reservations** | Book reservation status |
| **members** | Member details and membership type |
| **reviews** | Book ratings and comments |
| **staff** | Staff position and salary |

📊 **Total Rows:** ~21,000+ across all tables  
📅 **Time Range:** 2022-2025

---

## 🧹 Data Processing Workflow

### Key Steps:
1. Exported data into **PostgreSQL**
2. Created **SQL VIEWS** to:
   - Join related tables
   - Perform aggregations
   - Optimize Power BI performance
3. Built a **Calendar table** for time intelligence
4. Imported SQL Views into Power BI
5. Created DAX measures for KPIs and logic
6. Designed interactive dashboards

---

## 📈 Dashboard Overview

### 🧭 **Page 1: Navigation**
- Custom library-themed landing page
- Button-based navigation between report pages
- Improves usability and report flow

---

### 📊 **Page 2: Overview**
**Purpose:** Quick understanding of overall library performance

- KPIs: Total Loans, Active Loans, Returned Loans
- KPIs: Overdue Loans & Overdue %
- KPI: Total Revenue (Payments)
- Line Chart: Loans by Month (Year slicer)
- Donut Chart: Membership Type distribution
- Bar Chart: Top 5 Authors
- Matrix: Weekly Loan Distribution (busy weeks/months)
- Genre slicer applied only to Top Authors

---

### 📦 **Page 3: Inventory**
**Purpose:** Inventory control and stock risk monitoring

- KPIs: Available Copies, Stock-Out Risk %
- Table: Book stock, active loans, reservations, next available date
- Conditional formatting highlights stock risk
- Bar Chart: Loans by Published Year with target KPI
- Bar + Line Chart: Genre vs Loan Count & Avg Price
- KPI Card: Selected book availability

---

### 👥 **Page 4: Members**
**Purpose:** Member activity and revenue insights

- KPIs: New Members (6 months), Avg Revenue per Member, Total Members
- Clustered Column Chart: Membership growth
- Stacked Column Chart: Payments by type
- Donut Chart: Payments by category
- Table: Member activity with progress bar
- What-If parameter to check requested book availability
- Gauge & KPI showing availability result

---

### ⭐ **Page 5: Insights & Reviews**
**Purpose:** Quality, reviews, and staff analysis

- KPIs: Total Staff, Avg Salary, Total Reviews, Avg Rating
- Line + Stacked Column Chart: Rating vs Loans by Genre
- Area Chart: Staff by Position
- Star rating slicer (1–5)
- Interactive review navigation using bookmarks
- KPI cards showing recent reviews with star icons
- Donut Charts: Highest and lowest review months

---

## 📊 Sample SQL Views
The following **SQL VIEWS** were created in PostgreSQL and imported into Power BI:

```sql
CREATE OR REPLACE VIEW book_inventory_status AS
SELECT
  b.book_id,
  b.title,
  b.stock,
  COUNT(bl.loan_id) FILTER (WHERE bl.return_date IS NULL) AS active_loans,
  b.stock - COUNT(bl.loan_id) FILTER (WHERE bl.return_date IS NULL) AS available_copies
FROM books b
LEFT JOIN book_loans bl ON b.book_id = bl.book_id
GROUP BY b.book_id, b.title, b.stock;
```

---

## 🔹 Deployment & Refresh
- Report published to **Power BI Service**
- Scheduled refresh:
  - **9:00 AM**
  - **9:00 PM**

---

## 🔹 Key Skills Demonstrated
- SQL Views & joins
- Data modeling in Power BI
- Advanced DAX measures
- Conditional formatting
- Bookmarks & parameters
- Inventory and availability logic
- End-to-end BI workflow

---

## 🔹 Outcome
This dashboard helps library management:
- Reduce overdue books
- Manage inventory efficiently
- Understand member activity
- Improve decision-making using data
