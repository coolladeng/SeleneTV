import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import '../services/user_data_service.dart';
import '../services/local_mode_storage_service.dart';
import '../services/subscription_service.dart';
import '../utils/device_utils.dart';
import '../utils/font_utils.dart';
import '../widgets/windows_title_bar.dart';
import 'home_screen.dart';
import '../models/preset_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subscriptionUrlController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isLocalMode = false;

  // 鐐瑰嚮璁℃暟鍣ㄧ浉鍏?
  int _logoTapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_validateForm);
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _subscriptionUrlController.addListener(_validateForm);
    _loadSavedUserData();
  }

  void _loadSavedUserData() async {
    final userData = await UserDataService.getAllUserData();
    if (!mounted) return;

    bool hasData = false;

    if (userData['serverUrl'] != null) {
      _urlController.text = userData['serverUrl']!;
      hasData = true;
    }
    if (userData['username'] != null) {
      _usernameController.text = userData['username']!;
      hasData = true;
    }
    if (userData['password'] != null) {
      _passwordController.text = userData['password']!;
      hasData = true;
    }

    // 鍔犺浇璁㈤槄閾炬帴锛堢敤浜庡洖濉級
    final subscriptionUrl = await LocalModeStorageService.getSubscriptionUrl();
    if (!mounted) return;

    if (subscriptionUrl != null && subscriptionUrl.isNotEmpty) {
      _subscriptionUrlController.text = subscriptionUrl;
      hasData = true;
    }

    // 濡傛灉鏈夋暟鎹鍔犺浇锛屾洿鏂癠I鐘舵€?
    if (hasData && mounted) {
      _validateForm();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _subscriptionUrlController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleLogoTap() {
    _logoTapCount++;

    // 鍙栨秷涔嬪墠鐨勮鏃跺櫒
    _tapTimer?.cancel();

    // 濡傛灉杈惧埌10娆★紝鍒囨崲鍒版湰鍦版ā寮?
    if (_logoTapCount >= 10) {
      setState(() {
        _isLocalMode = !_isLocalMode;
        _validateForm();
        _logoTapCount = 0;
      });
      _showToast(
        _isLocalMode ? '宸插垏鎹㈠埌鏈湴妯″紡' : '宸插垏鎹㈠埌鏈嶅姟鍣ㄦā寮?,
        const Color(0xFF27ae60),
      );
    } else {
      // 璁剧疆鏂扮殑璁℃椂鍣紝2绉掑悗閲嶇疆璁℃暟
      _tapTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _logoTapCount = 0;
        });
      });
    }
  }
锘? // 棰勭疆鏈嶅姟閫夋嫨
  void _handleServiceSelect(PresetService service) async {
    if (service.type == 'subscription') {
      final content = await _fetchSubscriptionContent(service.url);
      if (content != null && mounted) {
        setState(() {
          _isLocalMode = true;
          _subscriptionUrlController.text = service.url;
        });
        _showToast('宸查€夋嫨: ${service.name}', const Color(0xFF27ae60));
      }
    }
  }

  Future<String?> _fetchSubscriptionContent(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      _showToast('鍔犺浇澶辫触: 缃戠粶涓嶅彲鐢?, const Color(0xFFe74c3c));
    }
    return null;
  }

  // 鏈嶅姟閫夋嫨鍣ㄧ粍浠?
  Widget _buildServiceSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '鍏叡鏈嶅姟',
            style: FontUtils.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7f8c8d),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PresetServices.services.length,
            itemBuilder: (context, index) {
              final service = PresetServices.services[index];
              final isSelected = _isLocalMode && _subscriptionUrlController.text == service.url;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? const Color(0xFFe8f4fd) : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleServiceSelect(service),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            service.icon == 'movie' ? Icons.movie :
                            service.icon == 'movie_filter' ? Icons.movie_filter :
                            service.icon == 'live_tv' ? Icons.live_tv :
                            Icons.video_library,
                            size: 22,
                            color: isSelected ? const Color(0xFF2980b9) : const Color(0xFF95a5a6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: FontUtils.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? const Color(0xFF2c3e50) : const Color(0xFF34495e),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.description,
                                  style: FontUtils.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF95a5a6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, size: 20, color: Color(0xFF27ae60)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFd5dbdb)),
          const SizedBox(height: 8),
          Text(
            _isLocalMode ? '鎴栨墜鍔ㄨ緭鍏ヨ闃呴摼鎺? : '鎴栨墜鍔ㄨ緭鍏ユ湇鍔″櫒淇℃伅',
            style: FontUtils.poppins(
              fontSize: 12,
              color: const Color(0xFFbdc3c7),
            ),
          ),
        ],
      ),
    );
  }


  void _validateForm() {
    if (!mounted) return;

    setState(() {
      if (_isLocalMode) {
        _isFormValid = _subscriptionUrlController.text.isNotEmpty;
      } else {
        _isFormValid = _urlController.text.isNotEmpty &&
            _usernameController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty;
      }
    });
  }

  // 澶勭悊鍥炶溅閿彁浜?
  void _handleSubmit() {
    if (_isLocalMode) {
      _handleLocalModeLogin();
    } else {
      _handleLogin();
    }
  }

  Widget _buildLocalModeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 璁㈤槄閾炬帴杈撳叆妗?
        TextFormField(
          controller: _subscriptionUrlController,
          style: FontUtils.poppins(
            fontSize: 16,
            color: const Color(0xFF2c3e50),
          ),
          decoration: InputDecoration(
            labelText: '璁㈤槄閾炬帴',
            labelStyle: FontUtils.poppins(
              color: const Color(0xFF7f8c8d),
              fontSize: 14,
            ),
            hintText: '璇疯緭鍏ヨ闃呴摼鎺?,
            hintStyle: FontUtils.poppins(
              color: const Color(0xFFbdc3c7),
              fontSize: 16,
            ),
            prefixIcon: const Icon(
              Icons.link,
              color: Color(0xFF7f8c8d),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '璇疯緭鍏ヨ闃呴摼鎺?;
            }
            return null;
          },
          onChanged: (value) => _validateForm(),
          onFieldSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: 32),

        // 鐧诲綍鎸夐挳
        ElevatedButton(
          onPressed:
              (_isLoading || !_isFormValid) ? null : _handleLocalModeLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFormValid && !_isLoading
                ? const Color(0xFF2c3e50)
                : const Color(0xFFbdc3c7),
            foregroundColor: _isFormValid && !_isLoading
                ? Colors.white
                : const Color(0xFF7f8c8d),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '鐧诲綍涓?..',
                      style: FontUtils.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  '鐧诲綍',
                  style: FontUtils.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ],
    );
  }

  String _processUrl(String url) {
    // 鍘婚櫎灏鹃儴鏂滄潬
    String processedUrl = url.trim();
    if (processedUrl.endsWith('/')) {
      processedUrl = processedUrl.substring(0, processedUrl.length - 1);
    }
    return processedUrl;
  }

  String _parseCookies(http.Response response) {
    // 瑙ｆ瀽 Set-Cookie 澶撮儴
    List<String> cookies = [];

    // 鑾峰彇鎵€鏈?Set-Cookie 澶撮儴
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      // HTTP 澶撮儴閫氬父鏄?String 绫诲瀷
      final cookieParts = setCookieHeaders.split(';');
      if (cookieParts.isNotEmpty) {
        cookies.add(cookieParts[0].trim());
      }
    }

    return cookies.join('; ');
  }

  void _showToast(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: FontUtils.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 澶勭悊 URL
        String baseUrl = _processUrl(_urlController.text);
        String loginUrl = '$baseUrl/api/login';

        // 鍙戦€佺櫥褰曡姹?
        final response = await http.post(
          Uri.parse(loginUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'username': _usernameController.text,
            'password': _passwordController.text,
          }),
        );
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // 鏍规嵁鐘舵€佺爜鏄剧ず涓嶅悓鐨勬秷鎭?
        switch (response.statusCode) {
          case 200:
            // 瑙ｆ瀽骞朵繚瀛?cookies
            String cookies = _parseCookies(response);

            // 淇濆瓨鐢ㄦ埛鏁版嵁
            await UserDataService.saveUserData(
              serverUrl: baseUrl,
              username: _usernameController.text,
              password: _passwordController.text,
              cookies: cookies,
            );
            if (!mounted) return;

            // 淇濆瓨妯″紡鐘舵€佷负鏈嶅姟鍣ㄦā寮?
            await UserDataService.saveIsLocalMode(false);
            if (!mounted) return;

            // _showToast('鐧诲綍鎴愬姛锛?, const Color(0xFF27ae60));

            // 璺宠浆鍒伴椤碉紝骞舵竻闄ゆ墍鏈夎矾鐢辨爤锛堝己鍒堕攢姣佹墍鏈夋棫椤甸潰锛?
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
            break;
          case 401:
            _showToast('鐢ㄦ埛鍚嶆垨瀵嗙爜閿欒', const Color(0xFFe74c3c));
            break;
          case 500:
            _showToast('鏈嶅姟鍣ㄩ敊璇?, const Color(0xFFe74c3c));
            break;
          default:
            _showToast('缃戠粶寮傚父', const Color(0xFFe74c3c));
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showToast('缃戠粶寮傚父', const Color(0xFFe74c3c));
      }
    }
  }

  void _handleLocalModeLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newUrl = _subscriptionUrlController.text.trim();

        // 鑾峰彇骞惰В鏋愯闃呭唴瀹?
        final response = await http.get(Uri.parse(newUrl));
        if (!mounted) return;

        if (response.statusCode != 200) {
          setState(() {
            _isLoading = false;
          });
          _showToast('鑾峰彇璁㈤槄鍐呭澶辫触', const Color(0xFFe74c3c));
          return;
        }

        final content =
            await SubscriptionService.parseSubscriptionContent(response.body);
        if (!mounted) return;

        if (content == null || 
            (content.searchResources == null || content.searchResources!.isEmpty) &&
            (content.liveSources == null || content.liveSources!.isEmpty)) {
          setState(() {
            _isLoading = false;
          });
          _showToast('瑙ｆ瀽璁㈤槄鍐呭澶辫触', const Color(0xFFe74c3c));
          return;
        }

        // 妫€鏌ユ槸鍚﹀凡鏈夎闃?URL
        final existingUrl = await LocalModeStorageService.getSubscriptionUrl();
        if (!mounted) return;

        if (existingUrl != null &&
            existingUrl.isNotEmpty &&
            existingUrl != newUrl) {
          // 寮圭獥璇㈤棶鏄惁娓呯┖
          setState(() {
            _isLoading = false;
          });

          if (!mounted) return;

          final shouldClear = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                '鎻愮ず',
                style: FontUtils.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              content: Text(
                '妫€娴嬪埌宸叉湁鏈湴妯″紡鍐呭涓旇闃呴摼鎺ヤ笉涓€鑷达紝鏄惁娓呯┖鍏ㄩ儴鏈湴妯″紡瀛樺偍锛?,
                style: FontUtils.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    '鍚?,
                    style: FontUtils.poppins(
                      fontSize: 14,
                      color: const Color(0xFF7f8c8d),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    '鏄?,
                    style: FontUtils.poppins(
                      fontSize: 14,
                      color: const Color(0xFFe74c3c),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
          if (!mounted) return;

          if (shouldClear == true) {
            await LocalModeStorageService.clearAllLocalModeData();
            if (!mounted) return;
          } else if (shouldClear == null) {
            // 鐢ㄦ埛鍙栨秷浜嗗璇濇
            return;
          }

          setState(() {
            _isLoading = true;
          });
        }

        // 淇濆瓨璁㈤槄閾炬帴鍜屽唴瀹?
        await LocalModeStorageService.saveSubscriptionUrl(newUrl);
        if (!mounted) return;
        if (content.searchResources != null && content.searchResources!.isNotEmpty) {
          await LocalModeStorageService.saveSearchSources(content.searchResources!);
          if (!mounted) return;
        }
        if (content.liveSources != null && content.liveSources!.isNotEmpty) {
          await LocalModeStorageService.saveLiveSources(content.liveSources!);
          if (!mounted) return;
        }

        // 淇濆瓨妯″紡鐘舵€佷负鏈湴妯″紡
        await UserDataService.saveIsLocalMode(true);
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // _showToast('鏈湴妯″紡鐧诲綍鎴愬姛锛?, const Color(0xFF27ae60));

        // 璺宠浆鍒伴椤碉紝骞舵竻闄ゆ墍鏈夎矾鐢辨爤锛堝己鍒堕攢姣佹墍鏈夋棫椤甸潰锛?
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showToast('鐧诲綍澶辫触锛?{e.toString()}', const Color(0xFFe74c3c));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceUtils.isTablet(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFe6f3fb), // #e6f3fb 0%
              Color(0xFFeaf3f7), // #eaf3f7 18%
              Color(0xFFf7f7f3), // #f7f7f3 38%
              Color(0xFFe9ecef), // #e9ecef 60%
              Color(0xFFdbe3ea), // #dbe3ea 80%
              Color(0xFFd3dde6), // #d3dde6 100%
            ],
            stops: [0.0, 0.18, 0.38, 0.60, 0.80, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Windows 鑷畾涔夋爣棰樻爮锛堥€忔槑鑳屾櫙锛?
            if (Platform.isWindows) const WindowsTitleBar(forceBlack: true),
            // 涓昏鍐呭
            Expanded(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 0 : 32.0,
                      vertical: 24.0,
                    ),
                    child:
                        isTablet ? _buildTabletLayout() : _buildMobileLayout(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 鎵嬫満绔竷灞€锛堜繚鎸佸師鏍凤級
  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildServiceSelector(),
        // Selene 鏍囬 - 鍙偣鍑?
        GestureDetector(
          onTap: _handleLogoTap,
          child: Text(
            'Selene',
            style: FontUtils.sourceCodePro(
              fontSize: 42,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2c3e50),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // 鐧诲綍琛ㄥ崟 - 鏃犺竟妗嗚璁?
        Form(
          key: _formKey,
          child: _isLocalMode
              ? _buildLocalModeForm()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // URL 杈撳叆妗?
                    TextFormField(
                      controller: _urlController,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: const Color(0xFF2c3e50),
                      ),
                      decoration: InputDecoration(
                        labelText: '鏈嶅姟鍣ㄥ湴鍧€',
                        labelStyle: FontUtils.poppins(
                          color: const Color(0xFF7f8c8d),
                          fontSize: 14,
                        ),
                        hintText: 'https://example.com',
                        hintStyle: FontUtils.poppins(
                          color: const Color(0xFFbdc3c7),
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.link,
                          color: Color(0xFF7f8c8d),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '璇疯緭鍏ユ湇鍔″櫒鍦板潃';
                        }
                        final uri = Uri.tryParse(value);
                        if (uri == null ||
                            uri.scheme.isEmpty ||
                            uri.host.isEmpty) {
                          return '璇疯緭鍏ユ湁鏁堢殑URL鍦板潃';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 20),

                    // 鐢ㄦ埛鍚嶈緭鍏ユ
                    TextFormField(
                      controller: _usernameController,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: const Color(0xFF2c3e50),
                      ),
                      decoration: InputDecoration(
                        labelText: '鐢ㄦ埛鍚?,
                        labelStyle: FontUtils.poppins(
                          color: const Color(0xFF7f8c8d),
                          fontSize: 14,
                        ),
                        hintText: '璇疯緭鍏ョ敤鎴峰悕',
                        hintStyle: FontUtils.poppins(
                          color: const Color(0xFFbdc3c7),
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF7f8c8d),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '璇疯緭鍏ョ敤鎴峰悕';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 20),

                    // 瀵嗙爜杈撳叆妗?
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: FontUtils.poppins(
                        fontSize: 16,
                        color: const Color(0xFF2c3e50),
                      ),
                      decoration: InputDecoration(
                        labelText: '瀵嗙爜',
                        labelStyle: FontUtils.poppins(
                          color: const Color(0xFF7f8c8d),
                          fontSize: 14,
                        ),
                        hintText: '璇疯緭鍏ュ瘑鐮?,
                        hintStyle: FontUtils.poppins(
                          color: const Color(0xFFbdc3c7),
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF7f8c8d),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF7f8c8d),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '璇疯緭鍏ュ瘑鐮?;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 32),

                    // 鐧诲綍鎸夐挳
                    ElevatedButton(
                      onPressed:
                          (_isLoading || !_isFormValid) ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid && !_isLoading
                            ? const Color(0xFF2c3e50) // 涓嶴elene logo鐩稿悓鐨勯鑹?
                            : const Color(0xFFbdc3c7), // 绂佺敤鏃剁殑娴呯伆鑹?
                        foregroundColor: _isFormValid && !_isLoading
                            ? Colors.white
                            : const Color(0xFF7f8c8d), // 绂佺敤鏃剁殑鏂囧瓧棰滆壊
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '鐧诲綍涓?..',
                                  style: FontUtils.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '鐧诲綍',
                              style: FontUtils.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // 骞虫澘绔竷灞€锛堜笌鎵嬫満绔鏍间竴鑷达紝鍙槸闄愬埗瀹藉害锛?
  Widget _buildTabletLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selene 鏍囬 - 鍙偣鍑?
          GestureDetector(
            onTap: _handleLogoTap,
            child: Text(
              'Selene',
              style: FontUtils.sourceCodePro(
                fontSize: 42,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF2c3e50),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // 鐧诲綍琛ㄥ崟 - 鏃犺竟妗嗚璁?
          Form(
            key: _formKey,
            child: _isLocalMode
                ? _buildLocalModeForm()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // URL 杈撳叆妗?
                      TextFormField(
                        controller: _urlController,
                        style: FontUtils.poppins(
                          fontSize: 16,
                          color: const Color(0xFF2c3e50),
                        ),
                        decoration: InputDecoration(
                          labelText: '鏈嶅姟鍣ㄥ湴鍧€',
                          labelStyle: FontUtils.poppins(
                            color: const Color(0xFF7f8c8d),
                            fontSize: 14,
                          ),
                          hintText: 'https://example.com',
                          hintStyle: FontUtils.poppins(
                            color: const Color(0xFFbdc3c7),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.link,
                            color: Color(0xFF7f8c8d),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '璇疯緭鍏ユ湇鍔″櫒鍦板潃';
                          }
                          final uri = Uri.tryParse(value);
                          if (uri == null ||
                              uri.scheme.isEmpty ||
                              uri.host.isEmpty) {
                            return '璇疯緭鍏ユ湁鏁堢殑URL鍦板潃';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 20),

                      // 鐢ㄦ埛鍚嶈緭鍏ユ
                      TextFormField(
                        controller: _usernameController,
                        style: FontUtils.poppins(
                          fontSize: 16,
                          color: const Color(0xFF2c3e50),
                        ),
                        decoration: InputDecoration(
                          labelText: '鐢ㄦ埛鍚?,
                          labelStyle: FontUtils.poppins(
                            color: const Color(0xFF7f8c8d),
                            fontSize: 14,
                          ),
                          hintText: '璇疯緭鍏ョ敤鎴峰悕',
                          hintStyle: FontUtils.poppins(
                            color: const Color(0xFFbdc3c7),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF7f8c8d),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '璇疯緭鍏ョ敤鎴峰悕';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 20),

                      // 瀵嗙爜杈撳叆妗?
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: FontUtils.poppins(
                          fontSize: 16,
                          color: const Color(0xFF2c3e50),
                        ),
                        decoration: InputDecoration(
                          labelText: '瀵嗙爜',
                          labelStyle: FontUtils.poppins(
                            color: const Color(0xFF7f8c8d),
                            fontSize: 14,
                          ),
                          hintText: '璇疯緭鍏ュ瘑鐮?,
                          hintStyle: FontUtils.poppins(
                            color: const Color(0xFFbdc3c7),
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFF7f8c8d),
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF7f8c8d),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.6),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '璇疯緭鍏ュ瘑鐮?;
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      const SizedBox(height: 32),

                      // 鐧诲綍鎸夐挳
                      ElevatedButton(
                        onPressed:
                            (_isLoading || !_isFormValid) ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid && !_isLoading
                              ? const Color(0xFF2c3e50)
                              : const Color(0xFFbdc3c7),
                          foregroundColor: _isFormValid && !_isLoading
                              ? Colors.white
                              : const Color(0xFF7f8c8d),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '鐧诲綍涓?..',
                                    style: FontUtils.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '鐧诲綍',
                                style: FontUtils.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
