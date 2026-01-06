import 'package:flutter/material.dart';
import '../models/ai_models.dart';
import '../services/ai_service.dart';

/// AI学习助手页面
class AIAnalysisPage extends StatefulWidget {
  const AIAnalysisPage({Key? key}) : super(key: key);

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  bool _isLoading = false;
  AIAnalysisResult? _latestAnalysis;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestAnalysis();
  }

  /// 加载最新的分析
  Future<void> _loadLatestAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AIService.getLatestAnalysis();
      setState(() {
        _latestAnalysis = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 生成新的分析
  Future<void> _generateAnalysis(String timeRange) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('🤖 AI正在分析您的学习数据...'),
                SizedBox(height: 8),
                Text(
                  '这可能需要1-2分钟，请稍候',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await AIService.generateAnalysis(
        analysisType: 'weakness',
        timeRange: timeRange,
      );

      // 关闭加载对话框
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        setState(() {
          _latestAnalysis = result['data'];
        });
        
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 分析完成！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.pop(context);

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 生成分析失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🤖 AI 学习助手'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLatestAnalysis,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLatestAnalysis,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildQuickAnalysisSection(),
              if (_latestAnalysis != null) ...[
                _buildDataStatsCard(),
                _buildWeakPointsSection(),
                _buildStrongPointsSection(),
                _buildSuggestionsCard(),
              ],
              if (_errorMessage != null) _buildErrorCard(),
              if (_isLoading) _buildLoadingCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 快速分析区域
  Widget _buildQuickAnalysisSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 快速分析',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('本周分析'),
                    onPressed: () => _generateAnalysis('week'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('本月分析'),
                    onPressed: () => _generateAnalysis('month'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 数据统计卡片
  Widget _buildDataStatsCard() {
    final stats = _latestAnalysis!.dataStats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 学习数据统计 (${_latestAnalysis!.timeRange == 'week' ? '本周' : '本月'})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('测验', '${stats['quizCount']}次'),
                _buildStatItem('作业', '${stats['assignmentCount']}次'),
                _buildStatItem('准确率', '${stats['accuracy']}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// 薄弱点区域
  Widget _buildWeakPointsSection() {
    if (_latestAnalysis!.weakPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📉 我的薄弱点',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._latestAnalysis!.weakPoints.map((wp) => _buildWeakPointCard(wp)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakPointCard(WeakPoint weakPoint) {
    Color severityColor;
    IconData severityIcon;

    switch (weakPoint.severity) {
      case 'high':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'medium':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case 'low':
        severityColor = Colors.yellow.shade700;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.grey;
        severityIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: severityColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weakPoint.knowledgePoint,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '准确率: ${weakPoint.accuracy.toStringAsFixed(1)}% • ${weakPoint.questionCount}题',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (weakPoint.analysis != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    weakPoint.analysis!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 优势点区域
  Widget _buildStrongPointsSection() {
    if (_latestAnalysis!.strongPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⭐ 我的优势',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._latestAnalysis!.strongPoints.take(3).map((sp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sp.knowledgePoint,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '准确率: ${sp.accuracy.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// AI建议卡片
  Widget _buildSuggestionsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 AI 学习建议',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _latestAnalysis!.aiSuggestions,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 错误提示卡片
  Widget _buildErrorCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage!),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载提示卡片
  Widget _buildLoadingCard() {
    return const Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载中...'),
            ],
          ),
        ),
      ),
    );
  }
}

