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
  List<RechargeItem> _globalItems = []; // 大会员套餐
  List<RechargeItem> _projectItems = []; // 子会员套餐
  RechargeItem? _selectedItem;
  PaymentOrder? _currentOrder;
  bool _isLoading = true;
  bool _isPaying = false;
  Timer? _pollTimer;

  // LinkDrop 项目ID
  static const int _linkdropProjectId = 1;

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
      // 使用统一接口获取会员价格信息
      final priceResponse = await _apiService.getMembershipPrices(projectCode: 'linkdrop');

      if (priceResponse != null && mounted) {
        setState(() {
          _globalItems = priceResponse.globalItems;
          // 使用 API 返回的项目会员套餐列表
          _projectItems = priceResponse.projectItems;
          _isLoading = false;
          // 默认选中第一个套餐（优先大会员）
          if (_globalItems.isNotEmpty) {
            _selectedItem = _globalItems.first;
          } else if (_projectItems.isNotEmpty) {
            _selectedItem = _projectItems.first;
          }
        });
      } else {
        // 如果统一接口失败，回退到原来的方式
        final results = await Future.wait([
          _apiService.getRechargeItems(membershipType: 'global'),
          _apiService.getRechargeItems(membershipType: 'project', projectId: _linkdropProjectId),
        ]);

        final globalItems = results[0];
        final projectItems = results[1];

        if (mounted) {
          setState(() {
            _globalItems = globalItems;
            _projectItems = projectItems;
            _isLoading = false;
            if (globalItems.isNotEmpty) {
              _selectedItem = globalItems.first;
            } else if (projectItems.isNotEmpty) {
              _selectedItem = projectItems.first;
            }
          });
        }
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

      // 3. 显示支付弹窗
      if (mounted) {
        _showPaymentDialog(paymentOrder);
      }

      // 4. 开始轮询支付状态
      _startPolling(paymentOrder.orderNo);
    } catch (e) {
      _showError('支付失败: $e');
    } finally {
      setState(() => _isPaying = false);
    }
  }

  /// 显示支付二维码弹窗
  void _showPaymentDialog(PaymentOrder paymentOrder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '扫码支付',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '请使用支付宝扫描下方二维码完成支付',
                style: TextStyle(color: LinkDropColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QRCodeDisplay(
                  qrCode: paymentOrder.qrCode!,
                  size: 200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '支付金额：¥${paymentOrder.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
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
          actions: [
            TextButton(
              onPressed: () {
                _pollTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('取消支付'),
            ),
          ],
        ),
      ),
    );
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
      // 关闭支付弹窗（如果还在显示）
      Navigator.of(context, rootNavigator: true).pop();

      // 显示支付成功弹窗
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

  /// 构建套餐列表
  Widget _buildItemList(List<RechargeItem> items, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: items.map((item) {
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
                            color: LinkDropColors.primary.withValues(alpha: 0.2),
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
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : LinkDropColors.textPrimary,
                                ),
                              ),
                              if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '¥${item.originalPrice!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.withValues(alpha: 0.7),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.isMembership ? '会员特权 · ${item.isPermanent ? '永久有效' : '${item.days}天有效期'}' : '下载包 · ${item.downloadCount}次下载',
                            style: TextStyle(
                              fontSize: 12,
                              color: LinkDropColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '¥${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
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
    );
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
            // 大会员套餐标题
            if (_globalItems.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '大会员套餐',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '解锁全部子项目会员功能',
                    style: TextStyle(
                      fontSize: 12,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildItemList(_globalItems, isDark),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

            // 子会员套餐标题
            if (_projectItems.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Icon(Icons.send, color: LinkDropColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'LinkDrop 会员套餐',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '仅解锁 LinkDrop 会员功能',
                    style: TextStyle(
                      fontSize: 12,
                      color: LinkDropColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildItemList(_projectItems, isDark),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // 加载中或无数据
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_globalItems.isEmpty && _projectItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: LinkDropColors.textSecondary.withValues(alpha: 0.5),
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
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                            '立即支付 ¥${_selectedItem?.price.toStringAsFixed(2) ?? '0.00'}',
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
