import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class JobApplicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> details;
  const JobApplicationDetailScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final title = details['full_name'] ?? 'Candidature';
    final phone = details['phone_number'] ?? '—';
    final statusText = details['status_text'] ?? details['status'] ?? '—';
    final motivationUrl = details['motivation_letter_url'] as String?;
    final cvUrl = details['cv_url'] as String?;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Détails de la candidature"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.description), text: 'Lettre de motivation'),
              Tab(icon: Icon(Icons.picture_as_pdf), text: 'CV'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Téléphone: $phone'),
                  const SizedBox(height: 2),
                  Text('Statut: $statusText'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PdfPreview(
                      url: motivationUrl, label: 'Lettre de motivation'),
                  _PdfPreview(url: cvUrl, label: 'CV'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final String? url;
  final String label;
  const _PdfPreview({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Center(
        child: Text('Aucun PDF pour $label'),
      );
    }
    return const PDF(
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
    ).fromUrl(
      url!,
      placeholder: (progress) => Center(child: Text('Chargement… $progress%')),
      errorWidget: (error) => Center(child: Text('Erreur: $error')),
    );
  }
}
