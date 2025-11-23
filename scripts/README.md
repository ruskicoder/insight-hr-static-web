# Scripts Documentation

This folder contains Python scripts for data management and import operations.

## Employee Data Import

### Overview

Employee data is imported from `employee_quarterly_scores_2025.csv` into the DynamoDB `insighthr-employees-dev` table.

### Scripts

#### 1. `import-employee-data.py`

Imports employee data from CSV to DynamoDB.

**What it does:**
- Parses `employee_quarterly_scores_2025.csv`
- Extracts unique employees (employeeId, position)
- Derives department from employeeId prefix:
  - `DEV-*` → DEV (Development)
  - `QA-*` → QA (Quality Assurance)
  - `DAT-*` → DAT (Data Analytics)
  - `SEC-*` → SEC (Security)
  - `AI_*` → AI (Artificial Intelligence)
- Generates employee records with fields:
  - `employeeId`: From CSV (e.g., "DEV-01013", "AI_00001")
  - `name`: Generated as "Employee {employeeId}"
  - `position`: From CSV (Junior, Mid, Senior, Lead, Manager, AI Engineer, ML Engineer, MLOps Engineer, Research Scientist)
  - `department`: Derived from prefix
  - `status`: "active"
  - `email`: Generated as "{dept}.{id}@insighthr.com"
  - `createdAt`: Current timestamp
  - `updatedAt`: Current timestamp
- Batch writes to DynamoDB (25 items per batch)

**Usage:**
```bash
python scripts/import-employee-data.py
```

**Prerequisites:**
- AWS credentials configured
- boto3 installed: `pip install boto3`
- CSV file at root: `employee_quarterly_scores_2025.csv`

#### 2. `verify-employee-data.py`

Verifies that DynamoDB data matches the CSV file.

**What it does:**
- Parses CSV to get expected employees
- Scans DynamoDB table
- Compares and reports:
  - Missing employees (in CSV but not in DB)
  - Extra employees (in DB but not in CSV)
  - Position mismatches
  - Department and position breakdowns

**Usage:**
```bash
python scripts/verify-employee-data.py
```

**Sample Output:**
```
======================================================================
EMPLOYEE DATA VERIFICATION
======================================================================

1. Parsing CSV file: employee_quarterly_scores_2025.csv
   Found 300 unique employees in CSV

2. Scanning DynamoDB table: insighthr-employees-dev
   Found 300 employees in DynamoDB

3. Comparing data...

4. Department breakdown in DynamoDB:
   AI: 56 employees
   DAT: 54 employees
   DEV: 99 employees
   QA: 49 employees
   SEC: 42 employees

5. Position breakdown in DynamoDB:
   AI Engineer: 11 employees
   Junior: 43 employees
   Lead: 33 employees
   ML Engineer: 9 employees
   MLOps Engineer: 12 employees
   Manager: 8 employees
   Mid: 89 employees
   Research Scientist: 24 employees
   Senior: 71 employees

======================================================================
✓ VERIFICATION PASSED: All data matches perfectly!
======================================================================
```

### Current Status

✅ **Employee data is already imported** (as of 2025-11-22)
- Table: `insighthr-employees-dev`
- Region: `ap-southeast-1`
- Total employees: 300
- All data verified and matches CSV perfectly

### Data Structure

**DynamoDB Table: `insighthr-employees-dev`**

- **Partition Key:** `employeeId` (String)
- **GSI:** `department-index` (Partition Key: `department`)
- **Attributes:**
  - `employeeId`: Unique employee identifier
  - `name`: Employee name
  - `department`: Department code (DEV, QA, DAT, SEC, AI)
  - `position`: Job position/level
  - `email`: Employee email
  - `status`: Employee status (active/inactive)
  - `createdAt`: ISO 8601 timestamp
  - `updatedAt`: ISO 8601 timestamp

### Department Breakdown

| Department | Code | Count |
|------------|------|-------|
| Development | DEV | 99 |
| Artificial Intelligence | AI | 56 |
| Data Analytics | DAT | 54 |
| Quality Assurance | QA | 49 |
| Security | SEC | 42 |
| **Total** | | **300** |

### Position Breakdown

| Position | Count |
|----------|-------|
| Mid | 89 |
| Senior | 71 |
| Junior | 43 |
| Lead | 33 |
| Research Scientist | 24 |
| MLOps Engineer | 12 |
| AI Engineer | 11 |
| ML Engineer | 9 |
| Manager | 8 |
| **Total** | **300** |

## Performance Data Import

### `import-performance-data.py`

Imports performance scores from CSV to DynamoDB `insighthr-performance-scores-dev` table.

**Usage:**
```bash
python scripts/import-performance-data.py
```

## Other Scripts

### `wipe-and-reimport-data.py`

Utility script for wiping and reimporting data (use with caution).

**Usage:**
```bash
python scripts/wipe-and-reimport-data.py
```

⚠️ **Warning:** This script deletes existing data. Use only in development environments.
