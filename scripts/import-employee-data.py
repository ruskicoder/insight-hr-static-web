#!/usr/bin/env python3
"""
Import employee data from CSV to DynamoDB Employees table.

This script:
1. Parses employee_quarterly_scores_2025.csv
2. Extracts unique employees (employeeId, position)
3. Derives department from employeeId prefix
4. Batch writes to DynamoDB Employees table
"""

import csv
import boto3
from datetime import datetime
from collections import defaultdict
import sys

# AWS Configuration
AWS_REGION = 'ap-southeast-1'
EMPLOYEES_TABLE = 'insighthr-employees-dev'

# Department mapping from employeeId prefix (using short codes to match existing data)
DEPARTMENT_MAP = {
    'DEV': 'DEV',
    'QA': 'QA',
    'DAT': 'DAT',
    'SEC': 'SEC',
    'AI': 'AI'
}

def derive_department(employee_id):
    """Derive department from employeeId prefix."""
    prefix = employee_id.split('-')[0] if '-' in employee_id else employee_id.split('_')[0]
    return DEPARTMENT_MAP.get(prefix, 'Unknown')

def generate_employee_name(employee_id):
    """Generate employee name from employeeId."""
    return f"Employee {employee_id}"

def parse_csv_and_extract_employees(csv_file_path):
    """Parse CSV and extract unique employees."""
    employees = {}
    
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            employee_id = row['employee_ID'].strip()
            position = row['position'].strip()
            
            # Store unique employee (use first occurrence for position)
            if employee_id not in employees:
                employees[employee_id] = {
                    'employeeId': employee_id,
                    'position': position,
                    'department': derive_department(employee_id),
                    'name': generate_employee_name(employee_id)
                }
    
    return list(employees.values())

def batch_write_to_dynamodb(employees):
    """Batch write employees to DynamoDB."""
    dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
    table = dynamodb.Table(EMPLOYEES_TABLE)
    
    current_time = datetime.utcnow().isoformat() + 'Z'
    
    # DynamoDB batch write limit is 25 items
    batch_size = 25
    total_written = 0
    
    for i in range(0, len(employees), batch_size):
        batch = employees[i:i + batch_size]
        
        with table.batch_writer() as writer:
            for emp in batch:
                item = {
                    'employeeId': emp['employeeId'],
                    'name': emp['name'],
                    'department': emp['department'],
                    'position': emp['position'],
                    'status': 'active',
                    'createdAt': current_time,
                    'updatedAt': current_time
                }
                writer.put_item(Item=item)
                total_written += 1
        
        print(f"Batch {i // batch_size + 1}: Wrote {len(batch)} employees")
    
    return total_written

def main():
    csv_file_path = 'employee_quarterly_scores_2025.csv'
    
    print(f"Parsing CSV file: {csv_file_path}")
    employees = parse_csv_and_extract_employees(csv_file_path)
    
    print(f"\nExtracted {len(employees)} unique employees")
    
    # Show department breakdown
    dept_counts = defaultdict(int)
    position_counts = defaultdict(int)
    
    for emp in employees:
        dept_counts[emp['department']] += 1
        position_counts[emp['position']] += 1
    
    print("\nDepartment breakdown:")
    for dept, count in sorted(dept_counts.items()):
        print(f"  {dept}: {count} employees")
    
    print("\nPosition breakdown:")
    for pos, count in sorted(position_counts.items()):
        print(f"  {pos}: {count} employees")
    
    # Confirm before writing
    response = input(f"\nProceed with writing {len(employees)} employees to DynamoDB table '{EMPLOYEES_TABLE}'? (yes/no): ")
    if response.lower() != 'yes':
        print("Import cancelled.")
        sys.exit(0)
    
    print(f"\nWriting to DynamoDB table: {EMPLOYEES_TABLE}")
    total_written = batch_write_to_dynamodb(employees)
    
    print(f"\n✓ Successfully imported {total_written} employees to DynamoDB")

if __name__ == '__main__':
    main()
