import 'package:securexresidence/models/product_model.dart';
import 'package:securexresidence/services/api_service.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    return await ApiService.getProducts();
  }
}
