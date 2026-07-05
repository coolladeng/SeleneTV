/// 预置服务配置 - 来自 hafrey1/LunaTV-config
class PresetService {
  final String name;
  final String description;
  final String type; // 'subscription' or 'server'
  final String url;
  final String? icon;

  const PresetService({
    required this.name,
    required this.description,
    required this.type,
    required this.url,
    this.icon,
  });
}

/// 预置的公共服务列表
class PresetServices {
  static const List<PresetService> services = [
    PresetService(
      name: '精简版 (无成人)',
      description: '31个视频源，仅普通内容，每日自动检测',
      type: 'subscription',
      url: 'https://raw.githubusercontent.com/hafrey1/LunaTV-config/refs/heads/main/jin18.txt',
      icon: 'movie',
    ),
    PresetService(
      name: '精简版+成人',
      description: '61个视频源，剔除无效和污染源',
      type: 'subscription',
      url: 'https://raw.githubusercontent.com/hafrey1/LunaTV-config/refs/heads/main/jingjian.txt',
      icon: 'movie_filter',
    ),
    PresetService(
      name: '完整版',
      description: '88个视频源，全部可用源',
      type: 'subscription',
      url: 'https://raw.githubusercontent.com/hafrey1/LunaTV-config/refs/heads/main/LunaTV-config.txt',
      icon: 'live_tv',
    ),
  ];
}
