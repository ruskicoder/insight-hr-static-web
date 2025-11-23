#!/usr/bin/env python3
"""
Import performance data from CSV to DynamoDB
This script reads employee_quarterly_scores_2025.csv and imports data into:
1. insighthr-employees-dev table
2. insighthr-performance-scores-dev table
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

def import_data(csv_file_path):
    """Import data from CSV file to DynamoDB tables"""
    
    # Track unique employees
    employees = {}
    performance_scores = []
    
    # Read CSV file
    print(f"Reading CSV file: {csv_file_path}")
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
                    'email': f"{employee_id.lower().replace('-', '.')}@insighthr.com",
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
    
    # Import employees
    print("\nImporting employees...")
    for employee_id, employee_data in employees.items():
        try:
            employees_table.put_item(Item=employee_data)
            print(f"  ✓ Imported employee: {employee_id}")
        except Exception as e:
            print(f"  ✗ Failed to import employee {employee_id}: {str(e)}")
    
    # Import performance scores
    print("\nImporting performance scores...")
    for i, score in enumerate(performance_scores, 1):
        try:
            performance_table.put_item(Item=score)
            if i % 50 == 0:
                print(f"  ✓ Imported {i}/{len(performance_scores)} scores...")
        except Exception as e:
            print(f"  ✗ Failed to import score for {score['employeeId']}: {str(e)}")
    
    print(f"\n✓ Import complete!")
    print(f"  - Employees: {len(employees)}")
    print(f"  - Performance scores: {len(performance_scores)}")

if __name__ == '__main__':
    import_data('employee_quarterly_scores_2025.csv')
