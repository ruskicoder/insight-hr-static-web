#!/usr/bin/env python3
"""
Verify employee data in DynamoDB matches the CSV file.

This script:
1. Parses employee_quarterly_scores_2025.csv to get expected employees
2. Scans DynamoDB insighthr-employees-dev table
3. Compares and reports any discrepancies
"""

import csv
import boto3
from collections import defaultdict

# AWS Configuration
AWS_REGION = 'ap-southeast-1'
EMPLOYEES_TABLE = 'insighthr-employees-dev'

def parse_csv_employees(csv_file_path):
    """Parse CSV and extract unique employees."""
    employees = {}
    
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            employee_id = row['employee_ID'].strip()
            position = row['position'].strip()
            
            if employee_id not in employees:
                employees[employee_id] = position
    
    return employees

def scan_dynamodb_employees():
    """Scan all employees from DynamoDB."""
    dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
    table = dynamodb.Table(EMPLOYEES_TABLE)
    
    employees = {}
    
    response = table.scan()
    for item in response['Items']:
        employees[item['employeeId']] = item['position']
    
    # Handle pagination
    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        for item in response['Items']:
            employees[item['employeeId']] = item['position']
    
    return employees

def main():
    csv_file_path = 'employee_quarterly_scores_2025.csv'
    
    print("=" * 70)
    print("EMPLOYEE DATA VERIFICATION")
    print("=" * 70)
    
    print(f"\n1. Parsing CSV file: {csv_file_path}")
    csv_employees = parse_csv_employees(csv_file_path)
    print(f"   Found {len(csv_employees)} unique employees in CSV")
    
    print(f"\n2. Scanning DynamoDB table: {EMPLOYEES_TABLE}")
    db_employees = scan_dynamodb_employees()
    print(f"   Found {len(db_employees)} employees in DynamoDB")
    
    # Compare
    print("\n3. Comparing data...")
    
    csv_ids = set(csv_employees.keys())
    db_ids = set(db_employees.keys())
    
    missing_in_db = csv_ids - db_ids
    extra_in_db = db_ids - csv_ids
    
    if missing_in_db:
        print(f"\n   ⚠ WARNING: {len(missing_in_db)} employees in CSV but NOT in DynamoDB:")
        for emp_id in sorted(list(missing_in_db)[:10]):
            print(f"      - {emp_id} ({csv_employees[emp_id]})")
        if len(missing_in_db) > 10:
            print(f"      ... and {len(missing_in_db) - 10} more")
    
    if extra_in_db:
        print(f"\n   ⚠ WARNING: {len(extra_in_db)} employees in DynamoDB but NOT in CSV:")
        for emp_id in sorted(list(extra_in_db)[:10]):
            print(f"      - {emp_id} ({db_employees[emp_id]})")
        if len(extra_in_db) > 10:
            print(f"      ... and {len(extra_in_db) - 10} more")
    
    # Check position mismatches
    common_ids = csv_ids & db_ids
    position_mismatches = []
    
    for emp_id in common_ids:
        if csv_employees[emp_id] != db_employees[emp_id]:
            position_mismatches.append((emp_id, csv_employees[emp_id], db_employees[emp_id]))
    
    if position_mismatches:
        print(f"\n   ⚠ WARNING: {len(position_mismatches)} employees with position mismatches:")
        for emp_id, csv_pos, db_pos in position_mismatches[:10]:
            print(f"      - {emp_id}: CSV={csv_pos}, DB={db_pos}")
        if len(position_mismatches) > 10:
            print(f"      ... and {len(position_mismatches) - 10} more")
    
    # Department breakdown
    print("\n4. Department breakdown in DynamoDB:")
    dept_counts = defaultdict(int)
    position_counts = defaultdict(int)
    
    for emp_id in db_employees:
        prefix = emp_id.split('-')[0] if '-' in emp_id else emp_id.split('_')[0]
        dept_counts[prefix] += 1
        position_counts[db_employees[emp_id]] += 1
    
    for dept, count in sorted(dept_counts.items()):
        print(f"   {dept}: {count} employees")
    
    print("\n5. Position breakdown in DynamoDB:")
    for pos, count in sorted(position_counts.items()):
        print(f"   {pos}: {count} employees")
    
    # Final verdict
    print("\n" + "=" * 70)
    if not missing_in_db and not extra_in_db and not position_mismatches:
        print("✓ VERIFICATION PASSED: All data matches perfectly!")
    else:
        print("⚠ VERIFICATION COMPLETED WITH WARNINGS (see above)")
    print("=" * 70)

if __name__ == '__main__':
    main()
