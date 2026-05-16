import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:purewill/domain/model/daily_log_model.dart';

class HabitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final LogStatus status;
  final bool isDefault;
  final String category; 
  final VoidCallback? onTap;
  final VoidCallback? onCheckboxTap;

  const HabitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.progress,
    required this.status,
    required this.category, 
    this.isDefault = false,
    this.onTap,
    this.onCheckboxTap,
  });

  @override
  Widget build(BuildContext context) {
    // final isCompleted = status;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: isDefault ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: status == LogStatus.success
                      ? color.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  child: Icon(
                    icon,
                    color: status == LogStatus.success ? color : color.withOpacity(0.7),
                    size: 22,
                  ),
                ),
                if (isDefault)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                if (status == LogStatus.success) 
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),

                if (status == LogStatus.failed) 
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: status == LogStatus.success ? Colors.grey : Colors.black,
                            decoration: status == LogStatus.success
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.blue, size: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: status == LogStatus.success ? Colors.green : status == LogStatus.failed ? Colors.red : Colors.grey,
                            fontWeight: status == LogStatus.success
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      
                      // Kategori
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 6,
                    percent: 1,
                    progressColor: status == LogStatus.success ? Colors.green : status == LogStatus.failed ? Colors.red : color,
                    backgroundColor: Colors.grey[200]!,
                    barRadius: const Radius.circular(8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: onCheckboxTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: status == LogStatus.success? Colors.green : status == LogStatus.failed ? Colors.red : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: status == LogStatus.success? Colors.green : status == LogStatus.failed ? Colors.red :  Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: status == LogStatus.success
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : status == LogStatus.failed
                          ? const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
