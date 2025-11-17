# Requirements Document

## Introduction

This document describes the requirements for developing the Static UI Web Interface of InsightHR - an HR automation platform based on AWS serverless architecture. The web interface will be hosted on Amazon S3 and distributed via CloudFront, providing user experience for three main groups: Admin/HR, Manager, and Employee.

**Project Scope:** This is an MVP (Minimum Viable Product) with a 1-month development timeline. The focus is on core functionality with a modern, clean UI using an Apple Blue theme inspired by Apple's design language.

**Tech Stack:** React + TypeScript, integrated with Python Lambda functions via API Gateway and DynamoDB.

**AWS Infrastructure:** All AWS services are deployed in the ap-southeast-1 (Singapore) region for optimal performance and data residency.

**Development Workflow:** For each major feature, development follows this order:
1. Create static frontend framework (UI components with full styling)
2. Create stub function (fully working local API server for demo/testing)
3. Create AWS infrastructure (Lambda, DynamoDB, API Gateway)
4. Deploy to cloud (deploy Lambda functions and connect to API Gateway)
5. Test (verify end-to-end functionality with real AWS services)

**Testing Environment:** All test/demo pages are accessible at `localhost:5173/test/*` (e.g., `/test/login`, `/test/dashboard`) with a separate test folder structure. Production routes use `localhost:5173/*` without the `/test` prefix.

## Glossary

- **InsightHR_System**: Hệ thống nền tảng tự động hóa HR serverless trên AWS
- **Static_Web_Interface**: Giao diện web tĩnh được lưu trữ trên S3 và phân phối qua CloudFront
- **Admin_Panel**: Giao diện quản trị dành cho HR để cấu hình KPI và công thức
- **User_Dashboard**: Giao diện hiển thị dữ liệu hiệu suất cho người dùng
- **KPI**: Key Performance Indicator - Chỉ số đánh giá hiệu suất
- **Performance_Formula**: Công thức tính điểm hiệu suất dựa trên KPI và trọng số
- **API_Gateway**: Cổng API kết nối giữa frontend và Lambda functions
- **Cognito_Auth**: Dịch vụ xác thực và phân quyền người dùng của AWS
- **File_Upload_Component**: Thành phần cho phép tải lên file CSV/Excel
- **Column_Mapping_Interface**: Giao diện ánh xạ cột dữ liệu với KPI
- **Chatbot_Widget**: Widget tích hợp chatbot HR Assistant

## Requirements

### Requirement 1

**User Story:** As an HR Admin, I want to log in to the system with clearly defined role-based permissions, so that I can access administrative functions appropriate to my authority

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL integrate with Cognito_Auth for user authentication supporting both email/password and Google OAuth
2. THE Static_Web_Interface SHALL provide both self-registration and HR admin-created account options
3. WHEN a user submits valid credentials, THE Static_Web_Interface SHALL redirect the user to the appropriate dashboard based on their role (Admin, Manager, or Employee)
4. WHEN authentication fails, THE Static_Web_Interface SHALL display an error message indicating invalid credentials
5. THE Static_Web_Interface SHALL provide password reset functionality through Cognito_Auth
6. WHILE a user session is active, THE Static_Web_Interface SHALL maintain authentication state across page navigation

### Requirement 2

**User Story:** As a user, I want to manage my profile information, so that my personal details are up-to-date in the system

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL provide a profile page where users can view and edit their personal information
2. THE Static_Web_Interface SHALL allow users to update their photo, contact information, and other personal details
3. WHERE the user is not an HR Admin, THE Static_Web_Interface SHALL prevent editing of company-assigned fields such as employee ID, department, and role
4. WHERE the user is an HR Admin, THE Static_Web_Interface SHALL allow editing of all user profile fields including company-assigned information
5. WHEN a user saves profile changes, THE Static_Web_Interface SHALL send the updated data to API_Gateway and display confirmation upon success

### Requirement 3

**User Story:** As an HR Admin, I want to manage customizable KPIs for the company, so that I can define evaluation metrics that fit our business needs

#### Acceptance Criteria

1. THE Admin_Panel SHALL provide a form interface for creating new KPI entries with name, description, and data type fields (number, percentage, boolean, text)
2. THE Admin_Panel SHALL allow KPIs to be organized into categories for better organization
3. WHEN an Admin submits a new KPI, THE Static_Web_Interface SHALL send the data to API_Gateway and display confirmation upon successful creation
4. THE Admin_Panel SHALL display a list of all KPIs with edit and disable actions
5. WHEN an Admin disables a KPI, THE Static_Web_Interface SHALL mark it as disabled in DynamoDB rather than deleting it, maintaining data traceability
6. THE Admin_Panel SHALL validate KPI name uniqueness before submission

### Requirement 4

**User Story:** As an HR Admin, I want to build performance scoring formulas by selecting KPIs and assigning weights, so that I can automate the scoring process according to our company's unique rules

#### Acceptance Criteria

1. THE Admin_Panel SHALL provide a formula builder interface with semantic mathematical input supporting standard operators
2. THE Admin_Panel SHALL provide autocomplete functionality (triggered by Ctrl+space) for KPI column selection similar to SQL Server data input
3. WHEN an Admin selects a KPI, THE Static_Web_Interface SHALL display an input field for entering the weight value
4. THE Static_Web_Interface SHALL validate that the sum of all KPI weights equals 100 percent before allowing formula submission
5. THE Static_Web_Interface SHALL support multiple active formulas simultaneously for different departments or evaluation criteria
6. WHEN an Admin saves a Performance_Formula, THE Static_Web_Interface SHALL send the formula configuration to API_Gateway
7. THE Admin_Panel SHALL display all active Performance_Formulas with the ability to edit or disable them

### Requirement 5

**User Story:** As an HR or Manager, I want to upload performance data files and map columns to KPIs, so that the system can automatically score employees

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL provide a File_Upload_Component that accepts CSV and Excel file formats with support for at least 10,000 records
2. WHEN a user uploads a file for the first time, THE Static_Web_Interface SHALL automatically define a table structure based on the file pattern
3. WHEN a user uploads a file with an exact pattern match to an existing table, THE Static_Web_Interface SHALL automatically add records to that table
4. WHEN a user uploads a file with a similar pattern to an existing table, THE Static_Web_Interface SHALL prompt the user to either add to the existing table with missing fields or create a new table
5. THE Static_Web_Interface SHALL validate uploaded data for missing values and invalid formats before processing
6. WHEN mapping is complete and user confirms, THE Static_Web_Interface SHALL upload the file to S3 and send mapping configuration to API_Gateway to trigger Lambda processing

### Requirement 6

**User Story:** As a user (HR, Manager, or Employee), I want to view performance data visualized through charts and tables, so that I can easily track and analyze performance

#### Acceptance Criteria

1. THE User_Dashboard SHALL retrieve performance data from API_Gateway upon page load
2. THE User_Dashboard SHALL display performance scores in table format with three chart types: line charts, bar charts, and pie charts
3. WHERE the user is an Admin or Manager, THE User_Dashboard SHALL provide filtering options by department, time period, and employee
4. WHERE the user is an Employee, THE User_Dashboard SHALL display only their personal performance data
5. THE User_Dashboard SHALL provide export functionality for data in CSV format
6. THE User_Dashboard SHALL support manual refresh of visualizations

### Requirement 7

**User Story:** As a user, I want to interact with the HR Assistant chatbot to query data using natural language, so that I can quickly get the information I need without manual searching

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL provide a dedicated Chatbot tab for the HR Assistant
2. WHEN a user types a message, THE Chatbot_Widget SHALL send the query to API_Gateway which connects to Amazon Lex and Bedrock
3. THE Chatbot_Widget SHALL retrieve relevant data from DynamoDB to provide accurate answers based on actual performance data
4. THE Chatbot_Widget SHALL display the chatbot response in a conversational format
5. THE Chatbot_Widget SHALL maintain conversation history during the user session

### Requirement 8

**User Story:** As an HR or Manager, I want the system to send automatic notifications to employees based on predefined conditions, so that employees are informed in a timely manner

#### Acceptance Criteria

1. THE Admin_Panel SHALL provide an interface for configuring notification rules with conditions and recipient criteria
2. WHEN an Admin creates a notification rule, THE Static_Web_Interface SHALL send the configuration to API_Gateway for email delivery via SNS
3. THE Static_Web_Interface SHALL display a list of configured notification rules with status indicators
4. THE Admin_Panel SHALL allow Admins to enable or disable notification rules
5. THE Static_Web_Interface SHALL display a notification history log showing sent email notifications and their recipients

### Requirement 9

**User Story:** As a user, I want the web interface to load quickly and operate smoothly, so that I have a good user experience regardless of geographic location

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL be hosted on S3 and distributed through CloudFront for global content delivery
2. THE Static_Web_Interface SHALL implement lazy loading for images and non-critical resources
3. THE Static_Web_Interface SHALL cache static assets with appropriate cache headers
4. THE Static_Web_Interface SHALL achieve a page load time of less than 3 seconds on standard broadband connections
5. THE Static_Web_Interface SHALL be responsive and functional on desktop, tablet, and mobile devices

### Requirement 10

**User Story:** As a user, I want the interface to have a consistent and easy-to-use design, so that I can navigate and perform tasks efficiently

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL implement a consistent navigation menu across all pages
2. THE Static_Web_Interface SHALL use an Apple Blue theme with modern typography throughout the application inspired by Apple's design language
3. THE Static_Web_Interface SHALL default to light mode
4. THE Static_Web_Interface SHALL provide clear visual feedback for user actions such as button clicks and form submissions
5. THE Static_Web_Interface SHALL display loading indicators during asynchronous operations
6. THE Static_Web_Interface SHALL implement error handling with user-friendly error messages in English

### Requirement 11

**User Story:** As a developer, I want the web interface to be built with a modular architecture that is easy to maintain, so that it supports future development and feature expansion

#### Acceptance Criteria

1. THE Static_Web_Interface SHALL be built using React with TypeScript for component-based architecture
2. THE Static_Web_Interface SHALL separate business logic from presentation components
3. THE Static_Web_Interface SHALL implement a centralized state management solution for application data
4. THE Static_Web_Interface SHALL use environment variables for API Gateway endpoints and configuration values
5. THE Static_Web_Interface SHALL include code documentation and follow consistent TypeScript coding standards
6. THE Static_Web_Interface SHALL be structured to facilitate easy integration with Python Lambda functions via API Gateway
