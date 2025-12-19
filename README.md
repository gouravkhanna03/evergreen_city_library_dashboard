# 📚 Library Management Analytics Dashboard
**Power BI | PostgreSQL | End-to-End BI Project**

---

## 🔹 Project Overview
This is an end-to-end **Library Analytics Dashboard** built using **PostgreSQL and Power BI**.

The project analyzes:
- Book loans and overdues
- Inventory availability and stock risk
- Member activity and revenue
- Reviews, ratings, and staff insights

All data is stored in PostgreSQL and visualized in Power BI using SQL Views and DAX.

---

## 🔹 Source Data (PostgreSQL Tables)
The dataset comes from the following tables:

- **books** (book details, price, stock)
- **authors** (author name, nationality)
- **genres** (genre names)
- **book_loans** (loan, due date, return date, fine)
- **payments** (member payments and types)
- **reservations** (book reservation status)
- **members** (member details and membership type)
- **reviews** (ratings and comments)
- **staff** (staff position and salary)

---

## 🔹 Data Preparation (SQL)
- Data was exported into **PostgreSQL**
- Multiple **SQL VIEWS** were created to:
  - Join related tables
  - Aggregate data for KPIs
  - Improve Power BI performance
  - Simplify data modeling
- Power BI connects only to **SQL Views**, not raw tables
- A **Calendar (Date) table** was created for time analysis

---

## 🔹 Dashboard Pages & Explanation

### 🧭 Page 1: Navigation
**Purpose:** Easy report navigation  
- Custom library-themed background
- Buttons to move between dashboard pages
- Improves user experience

---

### 📊 Page 2: Overview
**Problem solved:** Understand overall library performance quickly

**Visuals used:**
- KPI Cards: Total Loans, Active Loans, Returned Loans
- KPI Cards: Overdue Loans & Overdue %
- KPI Card: Total Revenue
- Line Chart: Loans by Month (Year slicer)
- Donut Chart: Membership Type distribution
- Bar Chart: Top 5 Authors
- Matrix: Weekly Loan Distribution (Months vs Weeks)
- Slicer: Genre (works only for Top 5 Authors)

---

### 📦 Page 3: Inventory
**Problem solved:** Track book availability and stock risk

**Visuals used:**
- KPI Cards: Available Copies, Stock Out Risk %
- Table: Book stock, active loans, reservations, next available date
- Conditional formatting for stock risk levels
- Bar Chart: Loans by Published Year (with target KPI)
- Bar + Line Chart: Genre vs Loan Count & Avg Price
- KPI Card: Selected Book & Available Copies

---

### 👥 Page 4: Members
**Problem solved:** Analyze member behavior and revenue

**Visuals used:**
- KPI Cards: New Members (6 months), Avg Revenue per Member, Total Members
- Clustered Column Chart: Membership growth
- Stacked Column Chart: Payments by type
- Stacked Bar Chart: Average Rating per Genre
- Donut Chart: Payments by category
- Table: Member activity with progress bar
- What-If parameter to check book quantity availability
- KPI & Gauge showing availability result

---

### ⭐ Page 5: Insights & Reviews
**Problem solved:** Understand quality, reviews, and staff insights

**Visuals used:**
- KPI Cards: Total Staff, Avg Salary, Total Reviews, Avg Rating
- Line + Stacked Column Chart: Rating vs Loans by Genre
- Area Chart: Staff by Position
- Star Rating slicer (1–5)
- Interactive review navigation using arrows & bookmarks
- KPI Cards showing last 30 days reviews with star icons
- Donut Charts: Highest and Lowest review months

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
