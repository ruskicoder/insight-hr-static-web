#!/usr/bin/env python3
"""Update CloudFront distribution with custom domain and SSL certificate"""

import boto3
import sys
import time

# Configuration
DISTRIBUTION_ID = "E3MHW5VALWTOCI"
CERTIFICATE_ARN = "arn:aws:acm:us-east-1:151507815244:certificate/a94eebf5-5edf-4658-9d5c-5ea48ffda11c"
DOMAIN_NAME = "insight-hr.io.vn"
WWW_DOMAIN = f"www.{DOMAIN_NAME}"

def main():
    print("=" * 50)
    print("Updating CloudFront Distribution")
    print("=" * 50)
    print()
    
    # Create CloudFront client
    client = boto3.client('cloudfront')
    
    try:
        # Get current distribution config
        print(f"Getting distribution config for {DISTRIBUTION_ID}...")
        response = client.get_distribution_config(Id=DISTRIBUTION_ID)
        config = response['DistributionConfig']
        etag = response['ETag']
        print(f"✓ Current config retrieved (ETag: {etag})")
        
        # Update aliases
        print(f"\nUpdating alternate domain names...")
        config['Aliases'] = {
            'Quantity': 2,
            'Items': [DOMAIN_NAME, WWW_DOMAIN]
        }
        print(f"  + {DOMAIN_NAME}")
        print(f"  + {WWW_DOMAIN}")
        
        # Update viewer certificate
        print(f"\nUpdating SSL certificate...")
        config['ViewerCertificate'] = {
            'ACMCertificateArn': CERTIFICATE_ARN,
            'Certificate': CERTIFICATE_ARN,
            'CertificateSource': 'acm',
            'MinimumProtocolVersion': 'TLSv1.2_2021',
            'SSLSupportMethod': 'sni-only'
        }
        print(f"  Certificate: {CERTIFICATE_ARN[:50]}...")
        
        # Update distribution
        print(f"\nApplying changes to CloudFront...")
        update_response = client.update_distribution(
            Id=DISTRIBUTION_ID,
            DistributionConfig=config,
            IfMatch=etag
        )
        
        print("✓ CloudFront distribution updated successfully!")
        print()
        
        # Wait for deployment
        print("Waiting for deployment to complete...")
        print("This typically takes 10-15 minutes...")
        print()
        
        attempts = 0
        max_attempts = 30
        
        while attempts < max_attempts:
            time.sleep(30)
            attempts += 1
            
            dist_response = client.get_distribution(Id=DISTRIBUTION_ID)
            status = dist_response['Distribution']['Status']
            
            if status == 'Deployed':
                print(f"✓ Deployment complete!")
                break
            else:
                print(f"  Status: {status} (check {attempts}/{max_attempts})")
        
        if status != 'Deployed':
            print(f"\n⚠ Deployment is taking longer than expected")
            print(f"Current status: {status}")
            print(f"Check AWS Console for progress")
        
        # Success message
        print()
        print("=" * 50)
        print("SETUP COMPLETE!")
        print("=" * 50)
        print()
        print("Your site is now accessible at:")
        print(f"  ✓ https://{DOMAIN_NAME}")
        print(f"  ✓ https://{WWW_DOMAIN}")
        print()
        print("Note: DNS propagation may take up to 48 hours globally")
        print()
        
        return 0
        
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        print()
        print("If you see a certificate error, the certificate may not be fully validated yet.")
        print("Wait a few more minutes and try again.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
