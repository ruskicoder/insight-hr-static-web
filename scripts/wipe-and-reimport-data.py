#!/usr/bin/env python3
"""
Wipe existing data from DynamoDB tables and re-import from CSV
This script:
1. Deletes all items from insighthr-employees-dev table
2. Deletes all items from insighthr-performance-scores-dev table
3. Re-imports data from employee_quarterly_scores_2025.csv
"""

import csv
import boto3
import uuid
from datetime import datetime
from decimal import Decimal

# AWS Configuration
AWS_REGION = 'ap-southeast-1'
EMPLOYEES_TABLE = 'insighthr-employees-dev'
PERFORMANCE_SCORES_TABLE = 'insighthr-performance-scores-dev'

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
employees_table = dynamodb.Table(EMPLOYEES_TABLE)
performance_table = dynamodb.Table(PERFORMANCE_SCORES_TABLE)

def extract_department(employee_id):
    """Extract department code from employee ID (e.g., 'DEV-001' -> 'DEV', 'AI_00001' -> 'AI')"""
    if '-' in employee_id:
        return employee_id.split('-')[0]
    elif '_' in employee_id:
        return employee_id.split('_')[0]
    else:
        return 'UNKNOWN'

def wipe_table(table, table_name, key_schema):
    """Delete all items from a DynamoDB table"""
    print(f"\nWiping table: {table_name}")
    
    # Scan to get all items
    response = table.scan()
    items = response.get('Items', [])
    
    # Handle pagination
    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        items.extend(response.get('Items', []))
    
    print(f"Found {len(items)} items to delete")
    
    # Delete items in batches
    with table.batch_writer() as batch:
        for i, item in enumerate(items, 1):
            # Extract key attributes based on key schema
            key = {k: item[k] for k in key_schema}
            batch.delete_item(Key=key)
            
            if i % 50 == 0:
                print(f"  Deleted {i}/{len(items)} items...")
    
    print(f"✓ Wiped {len(items)} items from {table_name}")

def import_data(csv_file_path):
    """Import data from CSV file to DynamoDB tables"""
    
    # Track unique employees
    employees = {}
    performance_scores = []
    
    # Read CSV file
    print(f"\nReading CSV file: {csv_file_path}")
    with open(csv_file_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        
        for row in reader:
            employee_id = row['employee_ID']
            position = row['position']
            department = extract_department(employee_id)
            season = row['season']
            year = row['year']
            
            # Period format: "YYYY-Q" (e.g., "2025-1", "2025-2", "2025-3")
            period = f"{year}-{season}"
            
            # Track unique employees
            if employee_id not in employees:
                employees[employee_id] = {
                    'employeeId': employee_id,
                    'name': f"Employee {employee_id}",  # Placeholder name
                    'department': department,
                    'position': position,
                    'email': f"{employee_id.lower().replace('-', '.').replace('_', '.')}@insighthr.com",
                    'status': 'active',
                    'createdAt': datetime.utcnow().isoformat(),
                    'updatedAt': datetime.utcnow().isoformat(),
                }
            
            # Create performance score record
            score_record = {
                'scoreId': str(uuid.uuid4()),
                'employeeId': employee_id,
                'employeeName': f"Employee {employee_id}",
                'department': department,
                'position': position,
                'period': period,
                'overallScore': Decimal(str(row['final_score'])),
                'kpiScores': {
                    'KPI': Decimal(str(row['KPI'])),
                    'completed_task': Decimal(str(row['completed_task'])),
                    'feedback_360': Decimal(str(row['feedback_360'])),
                },
                'calculatedAt': datetime.utcnow().isoformat(),
                'createdAt': datetime.utcnow().isoformat(),
                'updatedAt': datetime.utcnow().isoformat(),
            }
            performance_scores.append(score_record)
    
    print(f"Found {len(employees)} unique employees")
    print(f"Found {len(performance_scores)} performance score records")
    
    # Count by department
    dept_counts = {}
    for emp_id, emp_data in employees.items():
        dept = emp_data['department']
        dept_counts[dept] = dept_counts.get(dept, 0) + 1
    
    print("\nEmployee count by department:")
    for dept, count in sorted(dept_counts.items()):
        print(f"  {dept}: {count} employees")
    
    # Import employees
    print("\nImporting employees...")
    for employee_id, employee_data in employees.items():
        try:
            employees_table.put_item(Item=employee_data)
            if len(employees) <= 20 or list(employees.keys()).index(employee_id) % 50 == 0:
                print(f"  ✓ Imported employee: {employee_id} ({employee_data['department']})")
        except Exception as e:
            print(f"  ✗ Failed to import employee {employee_id}: {str(e)}")
    
    # Import performance scores
    print("\nImporting performance scores...")
    for i, score in enumerate(performance_scores, 1):
        try:
            performance_table.put_item(Item=score)
            if i % 100 == 0:
                print(f"  ✓ Imported {i}/{len(performance_scores)} scores...")
        except Exception as e:
            print(f"  ✗ Failed to import score for {score['employeeId']}: {str(e)}")
    
    print(f"\n✓ Import complete!")
    print(f"  - Employees: {len(employees)}")
    print(f"  - Performance scores: {len(performance_scores)}")

if __name__ == '__main__':
    print("=" * 60)
    print("WIPE AND RE-IMPORT PERFORMANCE DATA")
    print("=" * 60)
    
    # Step 1: Wipe employees table
    wipe_table(employees_table, EMPLOYEES_TABLE, ['employeeId'])
    
    # Step 2: Wipe performance scores table
    wipe_table(performance_table, PERFORMANCE_SCORES_TABLE, ['employeeId', 'period'])
    
    # Step 3: Re-import data
    import_data('employee_quarterly_scores_2025.csv')
    
    print("\n" + "=" * 60)
    print("COMPLETE!")
    print("=" * 60)
