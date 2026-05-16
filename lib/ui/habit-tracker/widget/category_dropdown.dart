import 'package:flutter/material.dart';
import 'package:purewill/domain/model/category_model.dart';

class CategoryDropdown extends StatelessWidget {
  final List<CategoryModel> userCategories;
  final int? selectedCategoryId;
  final void Function(int? value) onChanged;

  const CategoryDropdown({
    super.key,
    required this.userCategories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    
      if (userCategories.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No categories available',
                  style: TextStyle(color: Colors.orange),
                ),
                SizedBox(height: 4),
                Text(
                  'You can still create a habit without category',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
      }


  

        return DropdownButtonFormField<int>(
          value: selectedCategoryId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Select a category',
            filled: true,
            fillColor: Colors.transparent,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text(
                'Select a category (Optional)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ...userCategories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(
                  category.name,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ],
          onChanged: onChanged, 
        );
      }
      
}