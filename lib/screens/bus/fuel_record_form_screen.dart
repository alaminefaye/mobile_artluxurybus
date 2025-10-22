import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/bus_models.dart';
import '../../services/bus_api_service.dart';

class FuelRecordFormScreen extends ConsumerStatefulWidget {
  final int busId;
  final FuelRecord? fuelRecord; // null = création, non-null = modification

  const FuelRecordFormScreen({
    super.key,
    required this.busId,
    this.fuelRecord,
  });

  @override
  ConsumerState<FuelRecordFormScreen> createState() => _FuelRecordFormScreenState();
}

class _FuelRecordFormScreenState extends ConsumerState<FuelRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _stationController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _fuelType;
  File? _invoiceImage;
  bool _isLoading = false;

  final List<String> _fuelTypes = [
    'Essence',
    'Diesel',
    'GPL',
    'Électrique',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fuelRecord != null) {
      // Mode édition - pré-remplir les champs
      final record = widget.fuelRecord!;
      _quantityController.text = record.quantity?.toString() ?? '';
      _costController.text = record.cost?.toString() ?? '';
      _unitPriceController.text = record.unitPrice?.toString() ?? '';
      _stationController.text = record.fuelStation ?? '';
      _mileageController.text = record.mileage?.toString() ?? '';
      _notesController.text = record.notes ?? '';
      _selectedDate = record.fueledAt ?? record.date;
      _fuelType = record.fuelType;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _unitPriceController.dispose();
    _stationController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _invoiceImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _invoiceImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _calculateUnitPrice() {
    final quantity = double.tryParse(_quantityController.text);
    final cost = double.tryParse(_costController.text);
    
    if (quantity != null && cost != null && quantity > 0) {
      final unitPrice = cost / quantity;
      _unitPriceController.text = unitPrice.toStringAsFixed(0);
    }
  }

  void _calculateCost() {
    final quantity = double.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);
    
    if (quantity != null && unitPrice != null) {
      final cost = quantity * unitPrice;
      _costController.text = cost.toStringAsFixed(0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = BusApiService();
      
      if (widget.fuelRecord == null) {
        // Création
        await apiService.addFuelRecord(
          busId: widget.busId,
          quantity: double.parse(_quantityController.text),
          cost: double.parse(_costController.text),
          unitPrice: _unitPriceController.text.isNotEmpty 
              ? double.parse(_unitPriceController.text)
              : null,
          fueledAt: _selectedDate,
          fuelType: _fuelType,
          fuelStation: _stationController.text.isNotEmpty ? _stationController.text : null,
          mileage: _mileageController.text.isNotEmpty 
              ? double.parse(_mileageController.text)
              : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          invoiceImage: _invoiceImage,
        );
      } else {
        // Modification
        await apiService.updateFuelRecord(
          busId: widget.busId,
          recordId: widget.fuelRecord!.id,
          quantity: double.parse(_quantityController.text),
          cost: double.parse(_costController.text),
          unitPrice: _unitPriceController.text.isNotEmpty 
              ? double.parse(_unitPriceController.text)
              : null,
          fueledAt: _selectedDate,
          fuelType: _fuelType,
          fuelStation: _stationController.text.isNotEmpty ? _stationController.text : null,
          mileage: _mileageController.text.isNotEmpty 
              ? double.parse(_mileageController.text)
              : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          invoiceImage: _invoiceImage,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // true = succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fuelRecord == null 
                ? 'Enregistrement ajouté avec succès' 
                : 'Enregistrement modifié avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.fuelRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Carburant' : 'Ajouter Carburant'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: const Text('Date de ravitaillement'),
                subtitle: Text(_formatDate(_selectedDate)),
                trailing: const Icon(Icons.edit),
                onTap: _selectDate,
              ),
            ),

            const SizedBox(height: 16),

            // Quantité
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité (litres) *',
                prefixIcon: Icon(Icons.local_drink),
                border: OutlineInputBorder(),
                suffixText: 'L',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer la quantité';
                }
                if (double.tryParse(value) == null) {
                  return 'Valeur invalide';
                }
                return null;
              },
              onChanged: (_) => _calculateUnitPrice(),
            ),

            const SizedBox(height: 16),

            // Coût total
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Coût total *',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                suffixText: 'FCFA',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le coût';
                }
                if (double.tryParse(value) == null) {
                  return 'Valeur invalide';
                }
                return null;
              },
              onChanged: (_) => _calculateUnitPrice(),
            ),

            const SizedBox(height: 16),

            // Prix unitaire
            TextFormField(
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire',
                prefixIcon: Icon(Icons.price_check),
                border: OutlineInputBorder(),
                suffixText: 'FCFA/L',
                helperText: 'Calculé automatiquement',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateCost(),
            ),

            const SizedBox(height: 16),

            // Type de carburant
            DropdownButtonFormField<String>(
              initialValue: _fuelType,
              decoration: const InputDecoration(
                labelText: 'Type de carburant',
                prefixIcon: Icon(Icons.oil_barrel),
                border: OutlineInputBorder(),
              ),
              items: _fuelTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _fuelType = value);
              },
            ),

            const SizedBox(height: 16),

            // Station-service
            TextFormField(
              controller: _stationController,
              decoration: const InputDecoration(
                labelText: 'Station-service',
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Kilométrage
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Kilométrage',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 16),

            // Photo de facture
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photo de la facture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_invoiceImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _invoiceImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() => _invoiceImage = null);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galerie'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _takePicture,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Caméra'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Bouton Enregistrer
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Modifier' : 'Enregistrer',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
