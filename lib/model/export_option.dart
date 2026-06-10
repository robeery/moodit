import 'package:flutter/material.dart';

enum ExportOption {
  gallery('Save to gallery', Icons.photo_library_outlined, true),
  preset('Save as preset', Icons.layers_outlined, true),
  project('Save as project', Icons.folder_outlined, true);

  final String label;
  final IconData icon;
  final bool implemented;
  const ExportOption(this.label, this.icon, this.implemented);
}
