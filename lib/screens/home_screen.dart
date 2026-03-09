import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/dashboard/metric_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final dashboardProvider =
    Provider.of<DashboardProvider>(context, listen: false);

    await dashboardProvider.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (user?.selectedCCode != null)
              Text(
                '${user?.selectedCCode}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboard, child) {
          if (dashboard.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboard.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${dashboard.error}'),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = dashboard.data;
          if (data == null) {
            return const Center(child: Text('No data available'));
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome back, ${user?.name.split(' ')[0] ?? "User"}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    "Here's what's happening today.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Metrics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3,
                    children: [
                      MetricCard(
                        title: data.metrics[0].title,
                        value: data.metrics[0].value,
                        change: data.metrics[0].change,
                        trend: data.metrics[0].trend,
                        icon: Icons.people,
                      ),
                      MetricCard(
                        title: data.metrics[1].title,
                        value: data.metrics[1].value,
                        change: data.metrics[1].change,
                        trend: data.metrics[1].trend,
                        icon: Icons.person_add,
                      ),
                      MetricCard(
                        title: data.metrics[2].title,
                        value: data.metrics[2].value,
                        change: data.metrics[2].change,
                        trend: data.metrics[2].trend,
                        icon: Icons.work,
                      ),
                      MetricCard(
                        title: data.metrics[3].title,
                        value: data.metrics[3].value,
                        change: data.metrics[3].change,
                        trend: data.metrics[3].trend,
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Recent Activity
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.recentActivities.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final activity = data.recentActivities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              activity.name.substring(0, 1),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: RichText(
                            text: TextSpan(
                              text: activity.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: ' ${activity.description}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(
                              activity.createdAt,
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Department Stats
                  const Text(
                    'Department Growth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: data.departmentStats.map((dept) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    dept.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: (dept.employees / 100)
                                                .clamp(0.0, 1.0),
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    dept.employees.toString(),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
