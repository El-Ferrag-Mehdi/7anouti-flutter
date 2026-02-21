class AdminStats {
  const AdminStats({
    required this.usersTotal,
    required this.usersByRole,
    required this.hanoutsTotal,
    required this.hanoutsOpen,
    required this.hanoutsClosed,
    required this.ordersTotal,
    required this.ordersRevenue,
    required this.ordersByStatus,
    required this.carnetsTotal,
    required this.carnetsActive,
    required this.topHanouts,
    required this.topLivreurs,
    required this.quartiers,
  });

  final int usersTotal;
  final Map<String, int> usersByRole;
  final int hanoutsTotal;
  final int hanoutsOpen;
  final int hanoutsClosed;
  final int ordersTotal;
  final double ordersRevenue;
  final Map<String, int> ordersByStatus;
  final int carnetsTotal;
  final int carnetsActive;
  final List<AdminTopHanout> topHanouts;
  final List<AdminTopLivreur> topLivreurs;
  final List<AdminQuartierStat> quartiers;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>;
    final hanouts = json['hanouts'] as Map<String, dynamic>;
    final orders = json['orders'] as Map<String, dynamic>;
    final carnets = json['carnets'] as Map<String, dynamic>;

    return AdminStats(
      usersTotal: (users['total'] as num).toInt(),
      usersByRole: _toIntMap(users['byRole'] as Map<String, dynamic>),
      hanoutsTotal: (hanouts['total'] as num).toInt(),
      hanoutsOpen: (hanouts['open'] as num).toInt(),
      hanoutsClosed: (hanouts['closed'] as num).toInt(),
      ordersTotal: (orders['total'] as num).toInt(),
      ordersRevenue: (orders['revenue'] as num).toDouble(),
      ordersByStatus: _toIntMap(orders['byStatus'] as Map<String, dynamic>),
      carnetsTotal: (carnets['total'] as num).toInt(),
      carnetsActive: (carnets['active'] as num).toInt(),
      topHanouts: (json['topHanouts'] as List<dynamic>)
          .map((e) => AdminTopHanout.fromJson(e as Map<String, dynamic>))
          .toList(),
      topLivreurs: (json['topLivreurs'] as List<dynamic>)
          .map((e) => AdminTopLivreur.fromJson(e as Map<String, dynamic>))
          .toList(),
      quartiers: (json['quartiers'] as List<dynamic>)
          .map((e) => AdminQuartierStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, int> _toIntMap(Map<String, dynamic> json) {
    return json.map((key, value) => MapEntry(key, (value as num).toInt()));
  }
}

class AdminTopHanout {
  const AdminTopHanout({
    required this.hanoutId,
    required this.name,
    required this.orders,
    required this.revenue,
  });

  final String hanoutId;
  final String name;
  final int orders;
  final double revenue;

  factory AdminTopHanout.fromJson(Map<String, dynamic> json) {
    return AdminTopHanout(
      hanoutId: json['hanoutId'] as String,
      name: json['name'] as String,
      orders: (json['orders'] as num).toInt(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class AdminTopLivreur {
  const AdminTopLivreur({
    required this.livreurId,
    required this.name,
    required this.orders,
  });

  final String livreurId;
  final String name;
  final int orders;

  factory AdminTopLivreur.fromJson(Map<String, dynamic> json) {
    return AdminTopLivreur(
      livreurId: json['livreurId'] as String,
      name: json['name'] as String,
      orders: (json['orders'] as num).toInt(),
    );
  }
}

class AdminQuartierStat {
  const AdminQuartierStat({
    required this.name,
    required this.hanouts,
    required this.orders,
  });

  final String name;
  final int hanouts;
  final int orders;

  factory AdminQuartierStat.fromJson(Map<String, dynamic> json) {
    return AdminQuartierStat(
      name: json['name'] as String,
      hanouts: (json['hanouts'] as num).toInt(),
      orders: (json['orders'] as num).toInt(),
    );
  }
}
