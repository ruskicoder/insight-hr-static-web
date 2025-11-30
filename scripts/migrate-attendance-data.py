"""
Migrate attendance data from attendence_history to insighthr-attendance-history-dev
Maps old field names to new schema and adds missing fields
"""

import boto3
from datetime import datetime
from decimal import Decimal
import time

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-1')
old_table = dynamodb.Table('attendence_history')
new_table = dynamodb.Table('insighthr-attendance-history-dev')

def calculate_points_360(check_in, check_out, status):
    """Calculate 360 points based on attendance pattern"""
    if status == 'absent' or status == 'off':
        return 0
    
    if not check_in or not check_out:
        return 0
    
    try:
        # Parse times (format: "H:MM" or "HH:MM")
        check_in_parts = check_in.split(':')
        check_out_parts = check_out.split(':')
        
        check_in_hour = int(check_in_parts[0])
        check_in_min = int(check_in_parts[1]) if len(check_in_parts) > 1 else 0
        
        check_out_hour = int(check_out_parts[0])
        check_out_min = int(check_out_parts[1]) if len(check_out_parts) > 1 else 0
        
        # Calculate total hours worked
        total_minutes = (check_out_hour * 60 + check_out_min) - (check_in_hour * 60 + check_in_min)
        total_hours = total_minutes / 60.0
        
        # Base points: 10 points/hour
        base_points = total_hours * 10
        
        # Early bird bonus (check-in before 6:00 AM): 1.25x for hours before 8:00 AM
        if check_in_hour < 6:
            early_hours = min(8 - check_in_hour, total_hours)
            base_points += early_hours * 10 * 0.25  # Extra 25%
        
        # Overtime bonus (check-out after 17:00): 1.5x for hours after 17:00
        if check_out_hour >= 17:
            ot_minutes = (check_out_hour * 60 + check_out_min) - (17 * 60)
            ot_hours = ot_minutes / 60.0
            base_points += ot_hours * 10 * 0.5  # Extra 50%
        
        return round(base_points, 2)
    except:
        # Default to 80 points for normal work day if calculation fails
        return 80.0

def map_old_to_new(old_item):
    """Map old table structure to new table structure"""
    # Extract fields from old table
    employee_id = old_item.get('employee_id', '')
    date = old_item.get('Date', '')
    check_in = old_item.get('Check in')
    check_out = old_item.get('Check out')
    position = old_item.get('Position', '')
    team = old_item.get('Team', '')  # This is department
    status = old_item.get('Status', 'work')
    reason = old_item.get('Reason')
    
    # Calculate 360 points
    points_360 = calculate_points_360(check_in, check_out, status)
    
    # Create new item with proper field names
    new_item = {
        'employeeId': employee_id,
        'date': date,
        'department': team,
        'position': position,
        'status': status,
        'points360': Decimal(str(points_360)),
        'paidLeave': status == 'off',  # Assume 'off' status means paid leave
        'createdAt': datetime.utcnow().isoformat(),
        'updatedAt': datetime.utcnow().isoformat()
    }
    
    # Add optional fields if they exist
    if check_in:
        new_item['checkIn'] = check_in
    if check_out:
        new_item['checkOut'] = check_out
    if reason:
        new_item['reason'] = reason
    
    return new_item

def migrate_data():
    """Migrate all data from old table to new table"""
    print("Starting migration from attendence_history to insighthr-attendance-history-dev...")
    
    # Scan old table
    scan_kwargs = {}
    migrated_count = 0
    error_count = 0
    batch = []
    
    while True:
        response = old_table.scan(**scan_kwargs)
        items = response.get('Items', [])
        
        print(f"Processing batch of {len(items)} items...")
        
        for old_item in items:
            try:
                new_item = map_old_to_new(old_item)
                batch.append(new_item)
                
                # Batch write every 25 items (DynamoDB limit)
                if len(batch) >= 25:
                    with new_table.batch_writer() as writer:
                        for item in batch:
                            writer.put_item(Item=item)
                    migrated_count += len(batch)
                    print(f"✓ Migrated {migrated_count} records...")
                    batch = []
                    time.sleep(0.1)  # Small delay to avoid throttling
                    
            except Exception as e:
                print(f"✗ Error migrating item {old_item.get('employee_id')}/{old_item.get('Date')}: {e}")
                error_count += 1
        
        # Check if there are more items to scan
        if 'LastEvaluatedKey' not in response:
            break
        scan_kwargs['ExclusiveStartKey'] = response['LastEvaluatedKey']
    
    # Write remaining items in batch
    if batch:
        with new_table.batch_writer() as writer:
            for item in batch:
                writer.put_item(Item=item)
        migrated_count += len(batch)
    
    print(f"\n{'='*60}")
    print(f"Migration complete!")
    print(f"✓ Successfully migrated: {migrated_count} records")
    print(f"✗ Errors: {error_count} records")
    print(f"{'='*60}")

if __name__ == '__main__':
    # Wait for table to be active
    print("Waiting for new table to be ACTIVE...")
    new_table.wait_until_exists()
    print("✓ Table is ACTIVE\n")
    
    migrate_data()
