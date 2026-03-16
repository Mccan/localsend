import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localsend_app/model/payment_order.dart';
import 'package:localsend_app/provider/auth_provider.dart';
import 'package:localsend_app/services/api_service.dart';
import 'package:localsend_app/theme/linkdrop_theme.dart';
import 'package:localsend_app/widget/qr_code_display.dart';
import 'package:provider/provider.dart' as provider;

/// 支付页面
///
/// 提供会员套餐选择和支付宝扫码支付功能
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ApiService _apiService = ApiService();
  List<RechargeItem> _items = [];
  RechargeItem? _selectedItem;
  PaymentOrder? _currentOrder;
  bool _isLoading = true;
  bool _isPaying = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.getRechargeItems();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
          if (items.isNotEmpty) {
            _selectedItem = items.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('加载商品失败: $e');
      }
    }
  }

  Future<void> _startPayment() async {
    if (_selectedItem == null) return;

    setState(() => _isPaying = true);

    try {
      // 1. 创建订单
      final order = await _apiService.createRechargeOrder(_selectedItem!.id);
      if (order == null) {
        _showError('创建订单失败');
        return;
      }

      // 2. 创建支付（获取二维码）
      final paymentOrder = await _apiService.createPayment(int.parse(order.orderId));
      if (paymentOrder == null || paymentOrder.qrCode == null) {
        _showError('创建支付失败');
        return;
      }

      setState(() {
        _currentOrder = paymentOrder;
      });

      // 3. 开始轮询支付状态
      _startPolling(paymentOrder.orderNo);
    } catch (e) {
      _showError('支付失败: $e');
    } finally {
      setState(() => _isPaying = false);
    }
  }

  void _startPolling(String orderNo) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final order = await _apiService.queryPaymentStatus(orderNo);
      if (order != null && order.isPaid) {
        timer.cancel();
        _onPaymentSuccess();
      }
    });
  }

  void _onPaymentSuccess() {
    // 刷新用户信息
    provider.Provider.of<AuthProvider>(context, listen: false).refreshUser();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                '支付成功',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('您的会员权益已生效'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinkDropColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = provider.Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? LinkDropColors.zinc950 : LinkDropColors.zinc50,
        ),
        child: CustomScrollView(
          slivers: [
            // 顶部标题栏
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, MediaQuery.of(context).padding.top + 16, 32, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '开通会员',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : LinkDropColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 用户当前状态
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Card(
                  color: isDark ? LinkDropColors.zinc800 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: user?.isVipActive == true ? LinkDropColors.primaryGradient : null,
                            color: user?.isVipActive == true ? null : LinkDropColors.textSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            user?.isVipActive == true ? Icons.workspace_premium : Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? '用户',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.isVipActive == true ? 'VIP会员 · 剩余${user?.vipRemainingDays ?? 0}天' : '普通用户',
                                style: TextStyle(
                                  color: user?.isVipActive == true ? LinkDropColors.primary : LinkDropColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 套餐选择标题
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '选择套餐',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 套餐列表
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: LinkDropColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无可用套餐',
                            style: TextStyle(
                              fontSize: 16,
                              color: LinkDropColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重新加载'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LinkDropColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: _items.map((item) {
                          final isSelected = _selectedItem == item;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => setState(() => _selectedItem = item),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? LinkDropColors.zinc800 : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? LinkDropColors.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: LinkDropColors.primary.withOpacity(0.2),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.isMembership ? '会员特权 · 每日${item.dailyLimit}次下载' : '下载包 · ${item.downloadCount}次下载',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: LinkDropColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '¥${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: LinkDropColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 支付二维码区域
            if (_currentOrder != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Card(
                    color: isDark ? LinkDropColors.zinc800 : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            '扫码支付',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '请使用支付宝扫描下方二维码完成支付',
                            style: TextStyle(color: LinkDropColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          QRCodeDisplay(
                            qrCode: _currentOrder!.qrCode!,
                            size: 200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '支付金额：¥${_currentOrder!.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: LinkDropColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('等待支付中...'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 底部支付按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isPaying || _selectedItem == null ? null : _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LinkDropColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isPaying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _currentOrder != null ? '重新选择套餐' : '立即支付 ¥${_selectedItem?.price.toStringAsFixed(0) ?? 0}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
