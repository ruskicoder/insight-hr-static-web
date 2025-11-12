HR Automation Platform (InsightHR)
1. Tóm tắt
Đây là một ứng dụng serverless giúp các doanh nghiệp, đặc biệt trong ngành IT và các lĩnh vực liên quan, có thể tùy biến và tự động hóa quy trình đánh giá, quản lý nguồn nhân sự. Ứng dụng không chỉ trực quan hóa dữ liệu hiệu suất mà còn cung cấp một nền tảng linh hoạt để mỗi công ty có thể áp dụng bộ chỉ số (KPI) và công thức đánh giá độc nhất của riêng mình, từ đó đưa ra những quyết định nhân sự chính xác và công bằng.

2. Tuyên bố vấn đề
Ở các doanh nghiệp hiện tại, đặc biệt là trong lĩnh vực công nghệ nơi các vai trò và chỉ số hiệu suất rất đa dạng, việc đánh giá nhân sự thường tốn nhiều thời gian, mang tính thủ công và dễ bị ảnh hưởng bởi các yếu tố chủ quan, thiên vị. Hơn nữa, các công cụ có sẵn thường áp đặt một quy trình cứng nhắc, không phù hợp với văn hóa và mục tiêu riêng của từng công ty.
InsightHR ra đời để giải quyết vấn đề này. Đây là một ứng dụng serverless, sử dụng các dịch vụ của AWS, cho phép các doanh nghiệp:
Số hóa và tùy chỉnh quy trình đánh giá bằng cách tự định nghĩa các KPI và công thức tính điểm.
Tự động hóa việc chấm điểm và tổng hợp kết quả.
Theo dõi hiệu suất của cá nhân/phòng ban/công ty một cách trực quan qua biểu đồ.
Hỗ trợ HR đưa ra quyết định dựa trên dữ liệu thông qua chatbot trợ lý.
Ứng dụng giúp HR tối ưu hóa thời gian, tăng cường tính minh bạch, công bằng và xây dựng một quy trình quản trị nhân sự linh hoạt, phù hợp với đặc thù của từng doanh nghiệp.

3. Kiến trúc

Dịch vụ sử dụng:
Amazon S3: Lưu trữ trang web tĩnh (frontend) và các file dữ liệu (như file CSV, model AI) do người dùng tải lên.
Lambda: Trái tim của ứng dụng, thực thi toàn bộ logic nghiệp vụ từ xử lý đăng nhập, tính toán điểm số theo công thức tùy biến, đến các chức năng chatbot.
DynamoDB: Lưu trữ dữ liệu có cấu trúc. Sử dụng schema linh hoạt để lưu trữ:
Thông tin người dùng và nhân viên.
Các KPI và công thức tính điểm do mỗi công ty tự định nghĩa.
Kết quả đánh giá hiệu suất.

Amazon Bedrock & Amazon Lex: Cung cấp mô hình ngôn ngữ lớn (LLM) cho chatbot trợ lý HR, giúp truy vấn và tóm tắt dữ liệu một cách tự nhiên.
Amazon SNS: Gửi email thông báo (no-reply) đến các nhân viên khi có yêu cầu (ví dụ: nhắc nhở, thông báo kết quả).
CloudWatch & CloudWatch Logs: Theo dõi hoạt động của các hàm Lambda, hiệu suất của API Gateway và truy xuất database, đảm bảo hệ thống vận hành ổn định.
Amazon CloudFront: Phân phối nội dung web tĩnh và động trên toàn cầu với độ trễ thấp.
Amazon Route 53: Quản lý tên miền và định tuyến DNS.
Amazon API Gateway: Xây dựng, triển khai và quản lý các API, là cổng giao tiếp giữa frontend và backend (Lambda).
Amazon Cognito: Quản lý danh tính và quy trình đăng nhập/đăng ký cho người dùng.
AWS IAM: Quản lý quyền truy cập và phân quyền chi tiết cho các dịch vụ AWS.
AWS KMS: Quản lý và sử dụng khóa mã hóa để bảo vệ dữ liệu nhạy cảm trong DynamoDB và S3.

4. Triển khai kỹ thuật
Cụm chức năng Đăng nhập & Bảo mật:
Sử dụng Cognito để quản lý người dùng (đăng ký, đăng nhập, quên mật khẩu).
Quyền truy cập được phân chia rõ ràng (ví dụ: Admin/HR, Manager, Employee) thông qua IAM, giới hạn các hành động người dùng có thể thực hiện.
Cụm chức năng Quản trị & Tùy biến (Admin Panel - Dành cho HR):
Quản lý KPI: Giao diện cho phép HR tạo, sửa, xóa các chỉ số đánh giá (KPIs) riêng cho công ty (ví dụ: Tasks Completed, Code Quality Score, Customer Satisfaction).
Xây dựng công thức: Giao diện trực quan cho phép HR xây dựng công thức tính điểm hiệu suất bằng cách chọn các KPI đã tạo và gán trọng số cho chúng. Công thức này được lưu vào DynamoDB.
Cụm chức năng chính (User-facing):
Tải lên dữ liệu: Người dùng (HR/Manager) có thể tải lên file dữ liệu hiệu suất (CSV, Excel). Giao diện sẽ yêu cầu họ ánh xạ (map) các cột trong file với các KPI đã được định nghĩa trong hệ thống.
Chấm điểm tự động: Khi dữ liệu được tải lên, một hàm Lambda sẽ được kích hoạt. Hàm này sẽ:
Đọc dữ liệu từ file.
Truy xuất công thức tính điểm đang hoạt động của công ty từ DynamoDB.
Áp dụng công thức lên dữ liệu để tính toán điểm số cuối cùng cho từng nhân viên.
Lưu kết quả vào bảng Performance Score trong DynamoDB.
Dashboard & Biểu đồ: Trực quan hóa dữ liệu điểm số đã được xử lý, giúp theo dõi hiệu suất cá nhân, phòng ban theo thời gian.
Quản lý và thông báo: Chức năng tự động lọc và gửi thông báo (qua SNS) đến các nhân viên dựa trên các điều kiện được định sẵn (ví dụ: nhân viên vắng mặt, nhân viên chưa hoàn thành khảo sát).
Chatbot (HR Assistant): Tích hợp chatbot (Lex + Bedrock) cho phép người dùng truy vấn dữ liệu bằng ngôn ngữ tự nhiên, ví dụ: "Tóm tắt hiệu suất của team A trong quý 4?" hoặc "Những nhân viên nào có điểm hiệu suất cao nhất tháng này?".

5. Lộ trình và mốc triển khai
Giai đoạn 1: Xây dựng Nền tảng Tùy biến - MVP (Tháng 1 & 2)
Hoàn thiện luồng đăng nhập, phân quyền cơ bản (Admin, User).
Xây dựng Admin Panel cho phép HR tạo KPI và xây dựng công thức tính điểm động.
Triển khai chức năng tải file dữ liệu, ánh xạ cột và chấm điểm tự động dựa trên công thức tùy biến.
Xây dựng một dashboard cơ bản để hiển thị kết quả dạng bảng và biểu đồ đơn giản.
Giai đoạn 2: Hoàn thiện và Mở rộng tính năng (Tháng 3 & 4)
Tích hợp Chatbot (HR Assistant) để truy vấn dữ liệu.
Hoàn thiện chức năng gửi thông báo tự động qua SNS.
Nâng cấp dashboard với các bộ lọc và biểu đồ phân tích sâu hơn.
Tiến hành kiểm thử toàn diện, thu thập phản hồi và tinh chỉnh ứng dụng.

6. Ước tính ngân sách
Phân tích dưới đây dựa trên mô hình định giá của AWS tại thời điểm đề xuất và ước tính cho một kịch bản sử dụng ở quy mô nhỏ (MVP/Demo).
Chi phí hạ tầng (giá tham khảo tại thời điểm đề xuất)
Amazon Route 53: Dịch vụ DNS, quản lý tên miền: $0.5 cho mỗi hosted zone/tháng.
Amazon CloudFront: Dịch vụ phân phối nội dung (CDN): 0.009$ cho mỗi 10000 HTTP request, 0.12$ cho mỗi GB dữ liệu truyền ra (data out).
Amazon API Gateway: Quản lý và phân phối API: $1.0 cho mỗi 1 triệu HTTP request.
Amazon S3 Standard: Lưu trữ trang web tĩnh và file: $0.025 mỗi GB/tháng.
Amazon DynamoDB: Lưu trữ cơ sở dữ liệu NoSQL: $0.0074 mỗi GB/tháng (cho Indexed Storage).
Amazon CloudWatch: Dịch vụ giám sát: $0.30 mỗi metric/tháng.
Amazon SNS: Dịch vụ gửi thông báo: $0.5 mỗi 1 triệu request/tháng (sau free tier).
Amazon Cognito: Dịch vụ quản lý danh tính người dùng: Miễn phí 10,000 người dùng hoạt động hàng tháng (MAU), sau đó $0.015 cho mỗi MAU.
AWS IAM: Quản lý quyền truy cập: Miễn phí.
AWS KMS: Dịch vụ mã hóa: $1.0 cho mỗi 10,000 API call.
Amazon Bedrock (Claude 3 Sonnet): 0.003$ / 1,000 input tokens, 0.015$ / 1,000 output tokens.
AWS Lambda (On-demand): Miễn phí 1 triệu request + 400,000 GB-giây mỗi tháng. Sau đó:
Kiến trúc x86: $0.00001667 / GB-giây.
Kiến trúc Arm: $0.00001333 / GB-giây.
Requests: $0.2 / 1 triệu request.
Amazon Lex: Xây dựng chatbot: $0.004 cho mỗi text request (một tin nhắn từ người dùng).
CloudWatch Logs: Thu thập và lưu trữ log: $0.5 / GiB cho 30 ngày lưu trữ và phân tích. Miễn phí 50 GiB đầu tiên.
Ước tính chi tiết (kịch bản mẫu cho MVP - USD/tháng)
Giả sử ứng dụng có lưu lượng truy cập nhỏ trong giai đoạn đầu:
Route 53: $0.50
CloudFront (requests): $0.09 (ước tính 100,000 requests)
CloudFront (data out): $0.60 (ước tính 5 GB)
API Gateway: $0.10 (ước tính 100,000 requests)
S3 Storage: $0.25 (ước tính 10 GB)
DynamoDB Indexed Storage: $0.0074 (ước tính 1 GB)
CloudWatch Metrics: $3.00 (ước tính 10 metrics)
SNS: $0.025 (ước tính 50,000 requests)
Cognito: $0.00 (nằm trong free tier)
KMS: $0.50 (ước tính 5,000 API calls)
Bedrock (Claude 3 Sonnet): $1.35 (input 200k tokens → $0.60; output 50k tokens → $0.75)
Lambda: $0.00 (toàn bộ nằm trong free tier)
Amazon Lex: $8.00 (ước tính 2,000 tin nhắn chatbot)
CloudWatch Logs: $0.00 (nằm trong free tier 50 GiB)

Tổng chi phí ước tính (kịch bản mẫu): ≈ $14.57/tháng

7. Đánh giá rủi ro và Giải pháp
Thách thức lớn nhất của các công cụ HR trên thị trường là sự khác biệt trong quy trình và hệ số đánh giá giữa các công ty. Một giải pháp "one-size-fits-all" thường không hiệu quả.
Ứng dụng của chúng tôi không xem đây là rủi ro, mà là vấn đề cốt lõi cần giải quyết. Bằng cách cung cấp một nền tảng tùy biến linh hoạt, chúng tôi cho phép mỗi doanh nghiệp số hóa và tự động hóa chính quy trình đánh giá độc nhất của họ. Giải pháp này biến thách thức về sự đa dạng thành lợi thế cạnh tranh cốt lõi của sản phẩm.
Rủi ro về dữ liệu huấn luyện mô hình AI ban đầu được giảm thiểu bằng cách tập trung vào hệ thống chấm điểm dựa trên quy tắc (rule-based) tùy biến. Mô hình AI/LLM (Bedrock) chỉ đóng vai trò trợ lý thông minh để truy vấn và tóm tắt dữ liệu đã được xử lý, không tham gia trực tiếp vào việc ra quyết định chấm điểm, đảm bảo tính minh bạch và dễ kiểm soát.

8. Kết quả kỳ vọng & Kế hoạch tương lai (Future Plan)
Kết quả kỳ vọng:
Một sản phẩm MVP hoạt động ổn định, chứng minh được tính khả thi của kiến trúc serverless và giải pháp nền tảng tùy biến.
Cung cấp một công cụ mạnh mẽ, tiết kiệm chi phí cho các doanh nghiệp vừa và nhỏ để hiện đại hóa quy trình quản trị nhân sự.
Kế hoạch tương lai:
Cải tiến AI: Khi có đủ dữ liệu, sẽ phát triển các mô hình AI có khả năng đưa ra gợi ý về các mẫu hiệu suất (performance patterns) hoặc dự báo rủi ro nhân sự (ví dụ: nguy cơ nghỉ việc).
Phát triển API công khai (Public APIs): Xây dựng bộ API cho phép các hệ thống nội bộ khác của doanh nghiệp (như phần mềm quản lý dự án Jira, CRM Salesforce, hoặc phần mềm chấm công) có thể đẩy dữ liệu hiệu suất vào InsightHR một cách tự động. Điều này sẽ biến ứng dụng thành trung tâm xử lý dữ liệu nhân sự, tạo ra một hệ sinh thái quản trị đồng bộ và toàn diện.


HR Automation Platform (InsightHR)
1. Tóm tắt
Đây là một ứng dụng serverless giúp các doanh nghiệp, đặc biệt trong ngành IT và các lĩnh vực liên quan, có thể tùy biến và tự động hóa quy trình đánh giá, quản lý nguồn nhân sự. Ứng dụng không chỉ trực quan hóa dữ liệu hiệu suất mà còn cung cấp một nền tảng linh hoạt để mỗi công ty có thể áp dụng bộ chỉ số (KPI) và công thức đánh giá độc nhất của riêng mình, từ đó đưa ra những quyết định nhân sự chính xác và công bằng.

2. Tuyên bố vấn đề
Ở các doanh nghiệp hiện tại, đặc biệt là trong lĩnh vực công nghệ nơi các vai trò và chỉ số hiệu suất rất đa dạng, việc đánh giá nhân sự thường tốn nhiều thời gian, mang tính thủ công và dễ bị ảnh hưởng bởi các yếu tố chủ quan, thiên vị. Hơn nữa, các công cụ có sẵn thường áp đặt một quy trình cứng nhắc, không phù hợp với văn hóa và mục tiêu riêng của từng công ty.
InsightHR ra đời để giải quyết vấn đề này. Đây là một ứng dụng serverless, sử dụng các dịch vụ của AWS, cho phép các doanh nghiệp:
Số hóa và tùy chỉnh quy trình đánh giá bằng cách tự định nghĩa các KPI và công thức tính điểm.
Tự động hóa việc chấm điểm và tổng hợp kết quả.
Theo dõi hiệu suất của cá nhân/phòng ban/công ty một cách trực quan qua biểu đồ.
Hỗ trợ HR đưa ra quyết định dựa trên dữ liệu thông qua chatbot trợ lý.
Ứng dụng giúp HR tối ưu hóa thời gian, tăng cường tính minh bạch, công bằng và xây dựng một quy trình quản trị nhân sự linh hoạt, phù hợp với đặc thù của từng doanh nghiệp.

3. Kiến trúc

![Kiến trúc hệ thống](/static/images/architecture.png)

Dịch vụ sử dụng:
Amazon S3: Lưu trữ trang web tĩnh (frontend) và các file dữ liệu (như file CSV, model AI) do người dùng tải lên.
Lambda: Trái tim của ứng dụng, thực thi toàn bộ logic nghiệp vụ từ xử lý đăng nhập, tính toán điểm số theo công thức tùy biến, đến các chức năng chatbot.
DynamoDB: Lưu trữ dữ liệu có cấu trúc. Sử dụng schema linh hoạt để lưu trữ:
Thông tin người dùng và nhân viên.
Các KPI và công thức tính điểm do mỗi công ty tự định nghĩa.
Kết quả đánh giá hiệu suất.

Amazon Bedrock & Amazon Lex: Cung cấp mô hình ngôn ngữ lớn (LLM) cho chatbot trợ lý HR, giúp truy vấn và tóm tắt dữ liệu một cách tự nhiên.
Amazon SNS: Gửi email thông báo (no-reply) đến các nhân viên khi có yêu cầu (ví dụ: nhắc nhở, thông báo kết quả).
CloudWatch & CloudWatch Logs: Theo dõi hoạt động của các hàm Lambda, hiệu suất của API Gateway và truy xuất database, đảm bảo hệ thống vận hành ổn định.
Amazon CloudFront: Phân phối nội dung web tĩnh và động trên toàn cầu với độ trễ thấp.
Amazon Route 53: Quản lý tên miền và định tuyến DNS.
Amazon API Gateway: Xây dựng, triển khai và quản lý các API, là cổng giao tiếp giữa frontend và backend (Lambda).
Amazon Cognito: Quản lý danh tính và quy trình đăng nhập/đăng ký cho người dùng.
AWS IAM: Quản lý quyền truy cập và phân quyền chi tiết cho các dịch vụ AWS.
AWS KMS: Quản lý và sử dụng khóa mã hóa để bảo vệ dữ liệu nhạy cảm trong DynamoDB và S3.

4. Triển khai kỹ thuật
Cụm chức năng Đăng nhập & Bảo mật:
Sử dụng Cognito để quản lý người dùng (đăng ký, đăng nhập, quên mật khẩu).
Quyền truy cập được phân chia rõ ràng (ví dụ: Admin/HR, Manager, Employee) thông qua IAM, giới hạn các hành động người dùng có thể thực hiện.
Cụm chức năng Quản trị & Tùy biến (Admin Panel - Dành cho HR):
Quản lý KPI: Giao diện cho phép HR tạo, sửa, xóa các chỉ số đánh giá (KPIs) riêng cho công ty (ví dụ: Tasks Completed, Code Quality Score, Customer Satisfaction).
Xây dựng công thức: Giao diện trực quan cho phép HR xây dựng công thức tính điểm hiệu suất bằng cách chọn các KPI đã tạo và gán trọng số cho chúng. Công thức này được lưu vào DynamoDB.
Cụm chức năng chính (User-facing):
Tải lên dữ liệu: Người dùng (HR/Manager) có thể tải lên file dữ liệu hiệu suất (CSV, Excel). Giao diện sẽ yêu cầu họ ánh xạ (map) các cột trong file với các KPI đã được định nghĩa trong hệ thống.
Chấm điểm tự động: Khi dữ liệu được tải lên, một hàm Lambda sẽ được kích hoạt. Hàm này sẽ:
Đọc dữ liệu từ file.
Truy xuất công thức tính điểm đang hoạt động của công ty từ DynamoDB.
Áp dụng công thức lên dữ liệu để tính toán điểm số cuối cùng cho từng nhân viên.
Lưu kết quả vào bảng Performance Score trong DynamoDB.
Dashboard & Biểu đồ: Trực quan hóa dữ liệu điểm số đã được xử lý, giúp theo dõi hiệu suất cá nhân, phòng ban theo thời gian.
Quản lý và thông báo: Chức năng tự động lọc và gửi thông báo (qua SNS) đến các nhân viên dựa trên các điều kiện được định sẵn (ví dụ: nhân viên vắng mặt, nhân viên chưa hoàn thành khảo sát).
Chatbot (HR Assistant): Tích hợp chatbot (Lex + Bedrock) cho phép người dùng truy vấn dữ liệu bằng ngôn ngữ tự nhiên, ví dụ: "Tóm tắt hiệu suất của team A trong quý 4?" hoặc "Những nhân viên nào có điểm hiệu suất cao nhất tháng này?".

5. Lộ trình và mốc triển khai
Giai đoạn 1: Xây dựng Nền tảng Tùy biến - MVP (Tháng 1 & 2)
Hoàn thiện luồng đăng nhập, phân quyền cơ bản (Admin, User).
Xây dựng Admin Panel cho phép HR tạo KPI và xây dựng công thức tính điểm động.
Triển khai chức năng tải file dữ liệu, ánh xạ cột và chấm điểm tự động dựa trên công thức tùy biến.
Xây dựng một dashboard cơ bản để hiển thị kết quả dạng bảng và biểu đồ đơn giản.
Giai đoạn 2: Hoàn thiện và Mở rộng tính năng (Tháng 3 & 4)
Tích hợp Chatbot (HR Assistant) để truy vấn dữ liệu.
Hoàn thiện chức năng gửi thông báo tự động qua SNS.
Nâng cấp dashboard với các bộ lọc và biểu đồ phân tích sâu hơn.
Tiến hành kiểm thử toàn diện, thu thập phản hồi và tinh chỉnh ứng dụng.

6. Ước tính ngân sách
Phân tích dưới đây dựa trên mô hình định giá của AWS tại thời điểm đề xuất và ước tính cho một kịch bản sử dụng ở quy mô nhỏ (MVP/Demo).
Chi phí hạ tầng (giá tham khảo tại thời điểm đề xuất)
Amazon Route 53: Dịch vụ DNS, quản lý tên miền: $0.5 cho mỗi hosted zone/tháng.
Amazon CloudFront: Dịch vụ phân phối nội dung (CDN): 0.009$ cho mỗi 10000 HTTP request, 0.12$ cho mỗi GB dữ liệu truyền ra (data out).
Amazon API Gateway: Quản lý và phân phối API: $1.0 cho mỗi 1 triệu HTTP request.
Amazon S3 Standard: Lưu trữ trang web tĩnh và file: $0.025 mỗi GB/tháng.
Amazon DynamoDB: Lưu trữ cơ sở dữ liệu NoSQL: $0.0074 mỗi GB/tháng (cho Indexed Storage).
Amazon CloudWatch: Dịch vụ giám sát: $0.30 mỗi metric/tháng.
Amazon SNS: Dịch vụ gửi thông báo: $0.5 mỗi 1 triệu request/tháng (sau free tier).
Amazon Cognito: Dịch vụ quản lý danh tính người dùng: Miễn phí 10,000 người dùng hoạt động hàng tháng (MAU), sau đó $0.015 cho mỗi MAU.
AWS IAM: Quản lý quyền truy cập: Miễn phí.
AWS KMS: Dịch vụ mã hóa: $1.0 cho mỗi 10,000 API call.
Amazon Bedrock (Claude 3 Sonnet): 0.003$ / 1,000 input tokens, 0.015$ / 1,000 output tokens.
AWS Lambda (On-demand): Miễn phí 1 triệu request + 400,000 GB-giây mỗi tháng. Sau đó:
Kiến trúc x86: $0.00001667 / GB-giây.
Kiến trúc Arm: $0.00001333 / GB-giây.
Requests: $0.2 / 1 triệu request.
Amazon Lex: Xây dựng chatbot: $0.004 cho mỗi text request (một tin nhắn từ người dùng).
CloudWatch Logs: Thu thập và lưu trữ log: $0.5 / GiB cho 30 ngày lưu trữ và phân tích. Miễn phí 50 GiB đầu tiên.
Ước tính chi tiết (kịch bản mẫu cho MVP - USD/tháng)
Giả sử ứng dụng có lưu lượng truy cập nhỏ trong giai đoạn đầu:
Route 53: $0.50
CloudFront (requests): $0.09 (ước tính 100,000 requests)
CloudFront (data out): $0.60 (ước tính 5 GB)
API Gateway: $0.10 (ước tính 100,000 requests)
S3 Storage: $0.25 (ước tính 10 GB)
DynamoDB Indexed Storage: $0.0074 (ước tính 1 GB)
CloudWatch Metrics: $3.00 (ước tính 10 metrics)
SNS: $0.025 (ước tính 50,000 requests)
Cognito: $0.00 (nằm trong free tier)
KMS: $0.50 (ước tính 5,000 API calls)
Bedrock (Claude 3 Sonnet): $1.35 (input 200k tokens → $0.60; output 50k tokens → $0.75)
Lambda: $0.00 (toàn bộ nằm trong free tier)
Amazon Lex: $8.00 (ước tính 2,000 tin nhắn chatbot)
CloudWatch Logs: $0.00 (nằm trong free tier 50 GiB)

Tổng chi phí ước tính (kịch bản mẫu): ≈ $14.57/tháng

7. Đánh giá rủi ro và Giải pháp
Thách thức lớn nhất của các công cụ HR trên thị trường là sự khác biệt trong quy trình và hệ số đánh giá giữa các công ty. Một giải pháp "one-size-fits-all" thường không hiệu quả.
Ứng dụng của chúng tôi không xem đây là rủi ro, mà là vấn đề cốt lõi cần giải quyết. Bằng cách cung cấp một nền tảng tùy biến linh hoạt, chúng tôi cho phép mỗi doanh nghiệp số hóa và tự động hóa chính quy trình đánh giá độc nhất của họ. Giải pháp này biến thách thức về sự đa dạng thành lợi thế cạnh tranh cốt lõi của sản phẩm.
Rủi ro về dữ liệu huấn luyện mô hình AI ban đầu được giảm thiểu bằng cách tập trung vào hệ thống chấm điểm dựa trên quy tắc (rule-based) tùy biến. Mô hình AI/LLM (Bedrock) chỉ đóng vai trò trợ lý thông minh để truy vấn và tóm tắt dữ liệu đã được xử lý, không tham gia trực tiếp vào việc ra quyết định chấm điểm, đảm bảo tính minh bạch và dễ kiểm soát.

8. Kết quả kỳ vọng & Kế hoạch tương lai (Future Plan)
Kết quả kỳ vọng:
Một sản phẩm MVP hoạt động ổn định, chứng minh được tính khả thi của kiến trúc serverless và giải pháp nền tảng tùy biến.
Cung cấp một công cụ mạnh mẽ, tiết kiệm chi phí cho các doanh nghiệp vừa và nhỏ để hiện đại hóa quy trình quản trị nhân sự.
Kế hoạch tương lai:
Cải tiến AI: Khi có đủ dữ liệu, sẽ phát triển các mô hình AI có khả năng đưa ra gợi ý về các mẫu hiệu suất (performance patterns) hoặc dự báo rủi ro nhân sự (ví dụ: nguy cơ nghỉ việc).
Phát triển API công khai (Public APIs): Xây dựng bộ API cho phép các hệ thống nội bộ khác của doanh nghiệp (như phần mềm quản lý dự án Jira, CRM Salesforce, hoặc phần mềm chấm công) có thể đẩy dữ liệu hiệu suất vào InsightHR một cách tự động. Điều này sẽ biến ứng dụng thành trung tâm xử lý dữ liệu nhân sự, tạo ra một hệ sinh thái quản trị đồng bộ và toàn diện.


