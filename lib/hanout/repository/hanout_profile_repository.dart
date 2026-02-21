import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/hanout_model.dart';
import 'package:http_parser/http_parser.dart';

class HanoutProfileRepository {
  HanoutProfileRepository(this._apiService);

  final ApiService _apiService;

  Future<HanoutModel> getMyHanout() async {
    final dynamic response = await _apiService.get('/hanouts/me');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<HanoutModel> updateMyHanout({
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? image,
    bool? hasCarnet,
    double? deliveryFee,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (phone != null) body['phone'] = phone;
    if (image != null) body['image'] = image;
    if (hasCarnet != null) body['hasCarnet'] = hasCarnet;
    if (deliveryFee != null) body['deliveryFee'] = deliveryFee;

    final dynamic response = await _apiService.put(
      '/hanouts/me',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<String> uploadHanoutImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final lower = filename.toLowerCase();
    MediaType contentType = MediaType('image', 'jpeg');
    if (lower.endsWith('.png')) {
      contentType = MediaType('image', 'png');
    } else if (lower.endsWith('.webp')) {
      contentType = MediaType('image', 'webp');
    } else if (lower.endsWith('.gif')) {
      contentType = MediaType('image', 'gif');
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      contentType = MediaType('image', 'jpeg');
    }
    final dynamic response = await _apiService.postMultipart(
      '/hanouts/me/image',
      fileField: 'image',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final Map<String, dynamic> data =
        responseMap['data'] as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<void> deleteMyAccount() async {
    await _apiService.delete('/auth/me');
  }
}
