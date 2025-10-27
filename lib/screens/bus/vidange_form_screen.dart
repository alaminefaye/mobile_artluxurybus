import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/bus_api_service.dart';
import '../../models/bus_models.dart';

class VidangeFormScreen extends StatefulWidget {
  final int busId;
  final BusVidange? vidange;

  const VidangeFormScreen({
    super.key,
    required this.busId,
    this.vidange,
  });

  @override
  State<VidangeFormScreen> createState() => _VidangeFormScreenState();
}

class _VidangeFormScreenState extends State<VidangeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = BusApiService();
  
  late DateTime _lastVidangeDate;
  DateTime? _nextVidangeDate;
  String? _notes;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vidange != null) {
      // Mode édition
      _lastVidangeDate = widget.vidange!.lastVidangeDate;
      _nextVidangeDate = widget.vidange!.nextVidangeDate;
      _notes = widget.vidange!.notes;
    } else {
      _lastVidangeDate = DateTime.now();
      _nextVidangeDate = DateTime.now().add(const Duration(days: 10)); // 10 jours par défaut
    }
  }

  Future<void> _selectDate(BuildContext context, bool isLastDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isLastDate ? _lastVidangeDate : (_nextVidangeDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null) {
      setState(() {
        if (isLastDate) {
          _lastVidangeDate = picked;
          // Auto-calculer +10 jours si next n'est pas défini
          _nextVidangeDate ??= picked.add(const Duration(days: 10));
        } else {
          _nextVidangeDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      final data = {
        'last_vidange_date': DateFormat('yyyy-MM-dd').format(_lastVidangeDate),
        if (_nextVidangeDate != null) 
          'next_vidange_date': DateFormat('yyyy-MM-dd').format(_nextVidangeDate!),
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      if (widget.vidange == null) {
        await _apiService.scheduleVidange(widget.busId, data);
      } else {
        await _apiService.updateVidange(widget.busId, widget.vidange!.id, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vidange == null ? 'Vidange ajoutée' : 'Vidange modifiée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Signaler qu'il faut rafraîchir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vidange == null ? 'Nouvelle vidange' : 'Modifier vidange'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Dernière vidange *'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_lastVidangeDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Prochaine vidange'),
              subtitle: Text(_nextVidangeDate != null 
                ? DateFormat('dd/MM/yyyy').format(_nextVidangeDate!)
                : 'Auto-calculé (+10 jours)'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Vidange moteur, filtre à huile...',
              ),
              maxLines: 3,
              onSaved: (v) => _notes = v,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(widget.vidange == null ? 'Ajouter' : 'Modifier', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
