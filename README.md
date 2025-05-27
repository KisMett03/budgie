# BudgieAI Notification Detection API

A FastAPI-based web service for detecting expense notifications and extracting amounts using a trained BERT model.

## Features

- **Notification Classification**: Determines if a notification text represents an expense transaction
- **Amount Extraction**: Extracts monetary amounts from expense notifications using NER
- **Batch Processing**: Process multiple notifications at once
- **CORS Support**: Ready for integration with Flutter mobile apps
- **Health Monitoring**: Built-in health check endpoints
- **Automatic Model Loading**: Loads the trained BERT model on startup

## API Endpoints

### 1. Health Check
- **GET** `/` - Basic health check
- **GET** `/health` - Detailed health check with model status

### 2. Single Prediction
- **POST** `/predict` - Classify a single notification text
  ```json
  {
    "text": "Your transaction at Starbucks for RM 15.50 has been processed"
  }
  ```

### 3. Batch Prediction
- **POST** `/predict-batch` - Process multiple notifications (max 100)
  ```json
  {
    "texts": [
      "Payment of $25.00 at McDonald's",
      "Your salary has been credited",
      "Coffee purchase RM 8.90"
    ]
  }
  ```

### 4. Model Information
- **GET** `/model-info` - Get details about the loaded model

## Setup and Installation

### Prerequisites
- Python 3.8 or higher
- All dependencies from `requirements.txt`
- Trained BERT model files in `models/notification_model/final_model/`

### 1. Install Dependencies
```powershell
pip install -r requirements.txt
```

### 2. Verify Model Files
Ensure these files exist:
```
models/notification_model/final_model/
├── notification_bert_model_best.pt
└── notification_bert_tokenizer_best/
    ├── vocab.txt
    ├── special_tokens_map.json
    └── tokenizer_config.json
```

### 3. Run the API Server
```powershell
python main.py
```

Or using uvicorn directly:
```powershell
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at:
- **API Server**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs
- **OpenAPI Schema**: http://localhost:8000/openapi.json

## Flutter Integration

### 1. Add HTTP Package to Flutter
Add to your `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  flutter:
    sdk: flutter
```

### 2. Flutter Service Class Example
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationDetectionService {
  // Update this URL to match your API server
  static const String baseUrl = 'http://localhost:8000';
  
  // For Android emulator, use: 'http://10.0.2.2:8000'
  // For iOS simulator, use: 'http://localhost:8000'
  // For physical device, use your computer's IP: 'http://192.168.1.xxx:8000'
  
  static Future<NotificationResponse> predictNotification(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );
      
      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to predict: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<BatchNotificationResponse> predictBatch(List<String> texts) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict-batch'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'texts': texts,
        }),
      );
      
      if (response.statusCode == 200) {
        return BatchNotificationResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to predict batch: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
```

### 3. Flutter Data Models
```dart
class NotificationResponse {
  final bool isExpense;
  final double confidence;
  final int predictedClass;
  final String? extractedAmount;
  final String message;
  
  NotificationResponse({
    required this.isExpense,
    required this.confidence,
    required this.predictedClass,
    this.extractedAmount,
    required this.message,
  });
  
  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      isExpense: json['is_expense'],
      confidence: json['confidence'].toDouble(),
      predictedClass: json['predicted_class'],
      extractedAmount: json['extracted_amount'],
      message: json['message'],
    );
  }
}

class BatchNotificationResponse {
  final List<NotificationResponse> results;
  final int totalProcessed;
  
  BatchNotificationResponse({
    required this.results,
    required this.totalProcessed,
  });
  
  factory BatchNotificationResponse.fromJson(Map<String, dynamic> json) {
    return BatchNotificationResponse(
      results: (json['results'] as List)
          .map((item) => NotificationResponse.fromJson(item))
          .toList(),
      totalProcessed: json['total_processed'],
    );
  }
}
```

### 4. Usage Example in Flutter Widget
```dart
class NotificationDetectorWidget extends StatefulWidget {
  @override
  _NotificationDetectorWidgetState createState() => _NotificationDetectorWidgetState();
}

class _NotificationDetectorWidgetState extends State<NotificationDetectorWidget> {
  final TextEditingController _textController = TextEditingController();
  NotificationResponse? _result;
  bool _isLoading = false;
  
  Future<void> _detectNotification() async {
    if (_textController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _result = null;
    });
    
    try {
      final result = await NotificationDetectionService.predictNotification(
        _textController.text
      );
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Enter notification text',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _detectNotification,
            child: _isLoading 
              ? CircularProgressIndicator() 
              : Text('Detect Expense'),
          ),
          SizedBox(height: 16),
          if (_result != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result: ${_result!.isExpense ? "EXPENSE" : "NOT EXPENSE"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _result!.isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Confidence: ${(_result!.confidence * 100).toStringAsFixed(1)}%'),
                    if (_result!.extractedAmount != null) ...[
                      SizedBox(height: 8),
                      Text('Amount: ${_result!.extractedAmount}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## Network Configuration for Flutter

### Android Emulator
Use `http://10.0.2.2:8000` instead of `localhost`

### iOS Simulator
Use `http://localhost:8000`

### Physical Devices
1. Find your computer's IP address:
   ```powershell
   ipconfig
   ```
2. Use `http://YOUR_IP_ADDRESS:8000`
3. Make sure both devices are on the same network
4. Ensure Windows Firewall allows the connection

### Testing with Postman/cURL
```bash
# Health check
curl http://localhost:8000/health

# Single prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Your payment of RM 25.50 at Starbucks has been processed"}'

# Batch prediction
curl -X POST http://localhost:8000/predict-batch \
  -H "Content-Type: application/json" \
  -d '{"texts": ["Payment RM 15.00", "Salary credited"]}'
```

## Model Information

The API uses a BERT-based model trained for:
- **Binary Classification**: Expense vs Non-expense notifications
- **Named Entity Recognition**: Extracting amounts and merchant names
- **Multi-currency Support**: RM, USD, EUR, GBP
- **Confidence Threshold**: 0.5 (configurable)

## Troubleshooting

### Common Issues

1. **Model Not Loading**
   - Check if model files exist in the correct directory
   - Verify file permissions
   - Check console logs for detailed error messages

2. **Connection Refused from Flutter**
   - Verify the API server is running
   - Check the correct IP address/port
   - Ensure network connectivity
   - Check firewall settings

3. **CORS Errors**
   - The API includes CORS middleware for all origins
   - For production, update `allow_origins` to specific domains

4. **Memory Issues**
   - The BERT model requires significant RAM (~2GB)
   - Close other applications if needed
   - Consider using CPU instead of GPU for inference

### Logs and Debugging
- API logs are printed to console
- Check startup logs to ensure model loads successfully
- Use `/health` endpoint to verify model status

## Production Deployment

For production deployment:
1. Update CORS origins to specific domains
2. Add authentication/authorization
3. Implement rate limiting
4. Use a production WSGI server (e.g., Gunicorn)
5. Add monitoring and logging
6. Use HTTPS with SSL certificates

## API Response Examples

### Single Prediction Response
```json
{
  "is_expense": true,
  "confidence": 0.9234,
  "predicted_class": 1,
  "extracted_amount": "RM 25.50",
  "message": "Prediction completed successfully"
}
```

### Batch Prediction Response
```json
{
  "results": [
    {
      "is_expense": true,
      "confidence": 0.8567,
      "predicted_class": 1,
      "extracted_amount": "$15.00",
      "message": "Prediction completed successfully"
    },
    {
      "is_expense": false,
      "confidence": 0.9123,
      "predicted_class": 0,
      "extracted_amount": null,
      "message": "Prediction completed successfully"
    }
  ],
  "total_processed": 2
}
``` 