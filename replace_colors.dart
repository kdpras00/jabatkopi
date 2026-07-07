// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  if (!dir.existsSync()) {
    print('lib directory not found.');
    return;
  }
  
  final entities = dir.listSync(recursive: true);
  int count = 0;
  
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool changed = false;
      
      if (content.contains('AppColors.glassBorder')) {
        content = content.replaceAll('AppColors.glassBorder', 'AppColors.borderGrey');
        changed = true;
      }
      
      if (content.contains('AppColors.glassBackground')) {
        content = content.replaceAll('AppColors.glassBackground', 'AppColors.darkGrey');
        changed = true;
      }
      
      if (changed) {
        entity.writeAsStringSync(content);
        count++;
        print('Updated: ${entity.path}');
      }
    }
  }
  print('Total files updated: $count');
}
