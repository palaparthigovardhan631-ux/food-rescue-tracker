import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_post_controller.dart';
import '../data/models/food_listing_model.dart';

class QuickPostFoodScreen extends ConsumerStatefulWidget {
  const QuickPostFoodScreen({super.key});

  @override
  ConsumerState<QuickPostFoodScreen> createState() => _QuickPostFoodScreenState();
}

class _QuickPostFoodScreenState extends ConsumerState<QuickPostFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController(text: '10');
  final _addressController = TextEditingController();

  FoodCategory _category = FoodCategory.veg;
  String _quantityUnit = 'servings';
  DateTime _preparedAt = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _bestBefore = DateTime.now().add(const Duration(hours: 4));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _bestBefore,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_bestBefore),
      );

      if (pickedTime != null) {
        setState(() {
          _bestBefore = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(quickPostControllerProvider.notifier);
    final success = await controller.submitListing(
      title: _titleController.text,
      description: _descController.text,
      category: _category,
      quantityValue: double.tryParse(_quantityController.text) ?? 1.0,
      quantityUnit: _quantityUnit,
      preparedAt: _preparedAt,
      bestBefore: _bestBefore,
      address: _addressController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('✅ Surplus food posted successfully! Nearby recipients notified.'),
        ),
      );
      _titleController.clear();
      _descController.clear();
      _quantityController.text = '10';
      _addressController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickPostControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Surplus Food'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Upload Box (Cloudinary)
                GestureDetector(
                  onTap: () => _showPhotoSourceSheet(),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      image: state.selectedImage != null
                          ? DecorationImage(
                              image: FileImage(state.selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: state.isUploading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Compressing & Uploading to Cloudinary (WebP)...'),
                              ],
                            ),
                          )
                        : (state.selectedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 44, color: Colors.grey.shade600),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Take or Upload Food Photo (Auto WebP)',
                                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : null),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Food Title *',
                    hintText: 'e.g., Paneer Butter Masala with Roti',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 14),

                // Category Chips
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: FoodCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name.toUpperCase()),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) setState(() => _category = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Quantity & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter quantity' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _quantityUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: 'servings', child: Text('Servings')),
                          DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
                          DropdownMenuItem(value: 'packets', child: Text('Packets')),
                        ],
                        onChanged: (v) => setState(() => _quantityUnit = v ?? 'servings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Best Before / Expiry Countdown Timer Picker (Mandatory)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Best Before / Expiry Countdown *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(_bestBefore),
                              style: const TextStyle(fontSize: 13, color: Colors.brown),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _selectExpiryTime,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Partial Claims Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Partial Claims', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Allows multiple neighbors or an orphanage to claim custom portions.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: state.allowsPartialClaims,
                  onChanged: (val) {
                    ref.read(quickPostControllerProvider.notifier).togglePartialClaims(val);
                  },
                ),
                const Divider(),

                // Hygiene & Food Safety Declaration Checkbox (Mandatory)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.hygieneAccepted,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'Food Safety & Hygiene Declaration *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'I certify that this food was prepared under clean, hygienic conditions, stored safely, and is completely fit for human consumption.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) {
                    ref.read(quickPostControllerProvider.notifier).toggleHygiene(val);
                  },
                ),
                const SizedBox(height: 18),

                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                ElevatedButton(
                  onPressed: (state.isSubmitting || state.isUploading) ? null : _submit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Publish Surplus Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(quickPostControllerProvider.notifier).pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(quickPostControllerProvider.notifier).pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
