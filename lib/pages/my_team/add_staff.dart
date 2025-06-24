import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/loading_spinner.dart';
import '../../models/staff.dart';
import '../../components/success_dialogue.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  _AddStaffPageState createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emplNoController = TextEditingController();
  final _idNoController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  File? _image;
  int? _selectedRoleId;
  List<dynamic> _roles = [];

  final _storage = GetStorage();
  final String _baseUrl = ApiConfig.baseUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final token = _storage.read('token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/staff/roles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _roles = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load roles: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching roles: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emplNoController.dispose();
    _idNoController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(File image) async {
    final token = _storage.read('token');
    if (token == null) {
      throw Exception('No authentication token found');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> _createStaff() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final token = _storage.read('token');
        if (token == null) {
          throw Exception('No authentication token found');
        }

        String? photoUrl;
        if (_image != null) {
          photoUrl = await _uploadImage(_image!);
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/staff'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'emplNo': _emplNoController.text,
            'idNo': int.tryParse(_idNoController.text),
            'roleId': _selectedRoleId,
            'photoUrl': photoUrl,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            showSuccessDialog(
              context: context,
              title: 'Staff Created',
              message: 'The new staff member has been added successfully.',
              onDone: () {
                Navigator.pop(context, true);
              },
            );
          }
        } else {
          final errorData = json.decode(response.body);
          throw Exception(
              'Failed to create staff: ${errorData['message'] ?? response.body}');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $_error')),
          );
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Team Member'),
        backgroundColor: const Color.fromARGB(255, 12, 90, 153),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: _isLoading
          ? const LoadingSpinner.fullScreen(message: 'Creating staff...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _showPicker(context);
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey[800],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emplNoController,
                      decoration:
                          const InputDecoration(labelText: 'Employee Number'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _idNoController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an ID Number.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedRoleId,
                      hint: const Text('Select Role'),
                      items: _roles.map<DropdownMenuItem<int>>((role) {
                        return DropdownMenuItem<int>(
                          value: role['id'],
                          child: Text(role['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoleId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a role' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _createStaff,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 12, 90, 153),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Staff'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
