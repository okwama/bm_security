import 'package:bm_security/models/product_model.dart';
import 'package:bm_security/services/api_service.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    return await ApiService.getProducts();
  }
}
