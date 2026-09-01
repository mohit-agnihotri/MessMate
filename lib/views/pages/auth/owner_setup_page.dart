import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../models/app_models.dart';
import '../../../viewmodels/all_viewmodels.dart';
import '../owner/owner_main_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class OwnerSetupPage extends ConsumerStatefulWidget {
  const OwnerSetupPage({super.key});

  @override
  ConsumerState<OwnerSetupPage> createState() => _OwnerSetupPageState();
}

class _OwnerSetupPageState extends ConsumerState<OwnerSetupPage> {
  final _messNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '50');
  final _monthlyFeeCtrl = TextEditingController(text: '3000');
  final _perMealRateCtrl = TextEditingController(text: '50');
  final _cutoffCtrl = TextEditingController(text: '2');
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _imageExtension;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null) {
        _ownerNameCtrl.text = user.displayName!;
      }
    }
  }

  @override
  void dispose() {
    _messNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _capacityCtrl.dispose();
    _monthlyFeeCtrl.dispose();
    _perMealRateCtrl.dispose();
    _cutoffCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messNameCtrl.text.trim().isEmpty || _ownerNameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Generate a strictly unique 6-digit numeric code from the backend
      final messCode = await ref.read(appServiceProvider).generateUniqueMessCode();

      final newMessId = FirebaseFirestore.instance.collection('messes').doc().id;

      String? photoUrl;
      try {
        if (_selectedImageBytes != null && _imageExtension != null) {
          photoUrl = await ref.read(appServiceProvider).uploadImage('profiles', _selectedImageBytes!, _imageExtension!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
          setState(() => _isLoading = false);
        }
        return; // Stop mess creation if photo upload fails
      }

      final newMess = MessModel(
        messId: newMessId,
        name: _messNameCtrl.text.trim(),
        ownerId: user.uid,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerPhone: _phoneCtrl.text.trim(),
        ownerPhotoUrl: photoUrl,
        gpsLat: 0.0,
        gpsLng: 0.0,
        capacity: int.tryParse(_capacityCtrl.text) ?? 50,
        monthlyFee: double.tryParse(_monthlyFeeCtrl.text) ?? 3000.0,
        perMealRate: double.tryParse(_perMealRateCtrl.text) ?? 50.0,
        cutoffHours: int.tryParse(_cutoffCtrl.text) ?? 2,
        messCode: messCode,
        isListedOnMap: true,
        showMenuToOutsiders: true,
        showMenuToStudents: true,
        language: 'en',
      );

      await ref.read(appServiceProvider).createMess(newMess);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerMainPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Setup Mess Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome! 🎉', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Let\'s set up your mess details. You can always change these later.', style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF6B7280))),
              const SizedBox(height: 32),
              
              _buildTextField('Mess Name', _messNameCtrl, 'e.g. Sharma Bhojnalaya'),
              _buildTextField('Owner Full Name', _ownerNameCtrl, 'e.g. Raj Sharma'),
              _buildTextField('Phone Number', _phoneCtrl, 'e.g. 9876543210', isNumber: true),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Capacity', _capacityCtrl, 'e.g. 50', isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Monthly Fee (Rs)', _monthlyFeeCtrl, 'e.g. 3000', isNumber: true)),
                ],
              ),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Per Meal Rate (Rs)', _perMealRateCtrl, 'e.g. 50', isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Cutoff (Hours)', _cutoffCtrl, 'e.g. 2', isNumber: true)),
                ],
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Create Mess Profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22C55E))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final picker = ImagePicker();
          final file = await picker.pickImage(source: ImageSource.gallery);
          if (file != null) {
            final bytes = await file.readAsBytes();
            setState(() {
              _selectedImageBytes = bytes;
              _imageExtension = file.name.split('.').last;
            });
          }
        },
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            image: _selectedImageBytes != null
              ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover)
              : null,
          ),
          child: _selectedImageBytes == null
            ? const Icon(Icons.add_a_photo, color: Color(0xFF9CA3AF), size: 32)
            : null,
        ),
      ),
    );
  }
}
