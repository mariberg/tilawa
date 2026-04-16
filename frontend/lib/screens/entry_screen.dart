// Home screen — text input, familiarity selection, recent sessions, and prepare button.
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:js' as js;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/surah.dart';
import '../services/surah_service.dart';
import '../models/recent_session.dart';
import '../services/auth_service.dart';
import '../services/level_service.dart';
import '../services/session_service.dart';
import '../utils/date_utils.dart';
import '../utils/page_utils.dart';
import '../widgets/familiarity_pills.dart';
import '../widgets/revisit_bottom_sheet.dart';
import '../main.dart' show routeObserver;

import 'dart:math' show min;

/// Normalizes an Arabic transliteration string for fuzzy comparison.
/// Strips the common article prefix (al-/an-/ar-/as-/at-/ad-/ash-/ath-/adh-),
/// removes hyphens, apostrophes, and extra whitespace, then lowercases.
String _normalize(String s) {
  var t = s.toLowerCase().trim();
  // Strip leading article prefix: "al-", "an-", "ar-", "as-", "at-", "ad-",
  // "ash-", "ath-", "adh-", with or without the hyphen/space.
  t = t.replaceFirst(RegExp(r'^(al|an|ar|as|at|ad|ash|ath|adh)[\s\-]?'), '');
  // Remove remaining hyphens, apostrophes, and collapse whitespace.
  t = t.replaceAll(RegExp(r"[\-'`]"), '').replaceAll(RegExp(r'\s+'), '');
  return t;
}

/// Computes the Levenshtein edit distance between two strings.
int _editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final m = a.length, n = b.length;
  var prev = List<int>.generate(n + 1, (j) => j);
  var curr = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = min(min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

/// Filters [surahs] by case-insensitive substring match on [nameSimple],
/// falling back to fuzzy matching (normalized prefix stripping + edit distance)
/// when no exact substring matches are found.
/// Returns an empty list when [query] is empty or starts with a digit
/// (indicating a page-range input like "50–54").
List<Surah> filterSurahs(List<Surah> surahs, String query) {
  final trimmed = query.trimLeft();
  if (trimmed.isEmpty || RegExp(r'^\d').hasMatch(trimmed)) return [];
  final lowerQuery = trimmed.toLowerCase();

  // 1. Try exact substring match first (existing behavior).
  final exact = surahs
      .where((s) => s.nameSimple.toLowerCase().contains(lowerQuery))
      .toList();
  if (exact.isNotEmpty) return exact;

  // 2. Fuzzy fallback: normalize both sides and rank by edit distance.
  final normQuery = _normalize(trimmed);
  if (normQuery.isEmpty) return [];

  final scored = <(Surah, int)>[];
  for (final s in surahs) {
    final normName = _normalize(s.nameSimple);
    // Check normalized substring first.
    if (normName.contains(normQuery) || normQuery.contains(normName)) {
      scored.add((s, 0));
      continue;
    }
    final dist = _editDistance(normQuery, normName);
    // Allow up to ~40% of the longer string's length as tolerance.
    final maxLen = normQuery.length > normName.length
        ? normQuery.length
        : normName.length;
    if (dist <= (maxLen * 0.4).ceil()) {
      scored.add((s, dist));
    }
  }

  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return scored.map((e) => e.$1).toList();
}

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> with RouteAware {
  AuthService? _authService;
  LevelService? _levelService;
  SessionService? _sessionService;
  bool _didExtractArgs = false;

  final SurahService _surahService = SurahService();
  final TextEditingController _textController = TextEditingController();

  List<Surah>? _surahs;
  Surah? _selectedSurah;
  String? _error;
  bool _isLoading = true;
  bool _isPreparing = false;
  String _familiarity = 'New';

  List<RecentSession>? _recentSessions;
  bool _isLoadingRecent = true;
  String? _recentError;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer so we know when this screen becomes visible.
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) {
      routeObserver.subscribe(this, route);
    }
    if (!_didExtractArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null ||
          args is! Map<String, dynamic> ||
          args['authService'] is! AuthService) {
        // After a full refresh, arguments are lost — redirect to login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
        return;
      }
      _authService = args['authService'] as AuthService;
      _levelService = args['levelService'] as LevelService?;
      _sessionService = SessionService(authService: _authService!);
      _loadRecentSessions();
      _didExtractArgs = true;
    }
  }

  Future<void> _loadRecentSessions() async {
    try {
      final sessions = await _sessionService!.fetchRecentSessions();
      if (!mounted) return;
      setState(() {
        _recentSessions = sessions;
        _isLoadingRecent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentError = 'Could not load recent sessions.';
        _isLoadingRecent = false;
      });
    }
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await _surahService.fetchSurahs();
      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load surah data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _textController.dispose();
    super.dispose();
  }

  /// Called when this route becomes the top route again (e.g. after popUntil).
  @override
  void didPopNext() {
    // Re-fetch recent sessions and clear the form.
    setState(() {
      _isLoadingRecent = true;
      _recentError = null;
      _textController.clear();
      _selectedSurah = null;
      _error = null;
    });
    _loadRecentSessions();
  }

  /// Returns the [nameSimple] of the surah with the given [id],
  /// or null if [_surahs] is not loaded or the id is not found.
  String? _surahName(int id) {
    final idx = _surahs?.indexWhere((s) => s.id == id) ?? -1;
    return idx >= 0 ? _surahs![idx].nameSimple : null;
  }

  /// Returns the [nameSimple] of the next surah after [currentId],
  /// wrapping from 114 back to 1. Returns null if not found.
  String? _nextSurahName(int currentId) {
    final nextId = currentId >= 114 ? 1 : currentId + 1;
    return _surahName(nextId);
  }

  /// Computes the display title for a recent session row.
  /// Page sessions show the pages string; surah sessions show the
  /// looked-up nameSimple or a fallback "Surah {id}".
  String _sessionTitle(RecentSession session) {
    if (session.pages != null) return session.pages!;
    if (session.surah != null) {
      return _surahName(session.surah!) ?? 'Surah ${session.surah}';
    }
    return 'Unknown session';
  }

  Future<void> _onRecentSessionTap(RecentSession session) async {
    if (session.pages != null) {
      _handlePageSessionTap(session);
    } else if (session.surah != null) {
      _handleSurahSessionTap(session);
    }
  }

  void _handlePageSessionTap(RecentSession session) async {
    final parsed = parsePageRange(session.pages!);
    if (parsed == null) return;

    if (session.feeling == 'revisit') {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => const RevisitBottomSheet(
          revisitLabel: 'Revisit same pages',
          moveOnLabel: 'Move on',
        ),
      );
      if (choice == 'revisit') {
        _textController.text = formatPageRange(parsed.start, parsed.end);
      } else if (choice == 'moveOn') {
        _textController.text =
            nextPageRange(parsed.start, parsed.end, parsed.span);
      }
    } else {
      _textController.text =
          nextPageRange(parsed.start, parsed.end, parsed.span);
    }
  }

  void _handleSurahSessionTap(RecentSession session) async {
    if (session.feeling == 'revisit') {
      final currentName = _surahName(session.surah!);
      if (currentName == null) return;
      final nextName = _nextSurahName(session.surah!);

      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => const RevisitBottomSheet(
          revisitLabel: 'Revisit same surah',
          moveOnLabel: 'Move on',
        ),
      );
      if (choice == 'revisit') {
        _textController.text = currentName;
      } else if (choice == 'moveOn' && nextName != null) {
        _textController.text = nextName;
      }
    } else {
      final nextName = _nextSurahName(session.surah!);
      if (nextName == null) return;
      _textController.text = nextName;
    }
  }

  /// Validates page input. Only accepts a single number (e.g. "50")
  /// or a range with a dash (e.g. "50-54" or "50–54"). Returns the
  /// normalized pages string (using "-") or null if input is not pages.
  /// Throws if the format starts with a digit but is invalid.
  String? _parsePages(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    // Not a page input if it doesn't start with a digit
    if (!RegExp(r'^\d').hasMatch(trimmed)) return null;
    // Single page number
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
    // Range like "50-54" or "50–54" (with optional spaces around dash)
    final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      return '${rangeMatch.group(1)}-${rangeMatch.group(2)}';
    }
    // Anything else starting with a digit is invalid (commas, spaces, etc.)
    throw FormatException(
      'Invalid page format. Use a single page (e.g. 50) or a range (e.g. 50-54).',
    );
  }

  Future<void> _prepare() async {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Please enter pages or a surah name.');
      return;
    }

    setState(() {
      _error = null;
      _isPreparing = true;
    });

    try {
      final pages = _parsePages(input);
      // For surah input, send the chapter number (1-114) not the name.
      String? surahNumber;
      if (pages == null) {
        final match = _selectedSurah ??
            _surahs?.cast<Surah?>().firstWhere(
                  (s) => s!.nameSimple.toLowerCase() == input.toLowerCase(),
                  orElse: () => null,
                );
        if (match == null) {
          setState(() => _error = 'Surah not found. Please select from the list.');
          return;
        }
        _selectedSurah ??= match;
        surahNumber = match.id.toString();
      }

      final response = await _sessionService!.prepare(
        pages: pages,
        surah: surahNumber,
        familiarity: _familiarity,
      );

      if (!mounted) return;
      await Navigator.pushNamed(context, '/prep', arguments: {
        'sessionId': response.sessionId,
        'overview': response.overview,
        'keywords': response.keywords.map((k) => k.toJson()).toList(),
        'pages': pages,
        'surah': _selectedSurah?.id,
        'surahName': _selectedSurah?.nameSimple,
        'authService': _authService!,
      });
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.textSecondary),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings', arguments: {
                        'authService': _authService!,
                        'levelService': _levelService!,
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                    tooltip: 'Logout',
                    onPressed: () {
                      final logoutUrl = _authService!.logout('http://localhost:5000');
                      // Redirect the current window to the OAuth2 logout URL.
                      // The provider will end the session and redirect back to the app.
                      js.context.callMethod('eval', ['window.location.replace("$logoutUrl")']);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'What are you about to recite?',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Typeahead surah search
              TypeAheadField<Surah>(
                controller: _textController,
                suggestionsCallback: (search) {
                  if (_isLoading) return <Surah>[];
                  return filterSurahs(_surahs ?? [], search);
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.primary,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 50–54 or Surah Al-Baqarah',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.textHint,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      filled: false,
                    ),
                  );
                },
                itemBuilder: (context, surah) {
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          surah.nameSimple,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          surah.nameArabic,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onSelected: (surah) {
                  _selectedSurah = surah;
                  _textController.text = surah.nameSimple;
                },
                emptyBuilder: (context) {
                  // Hide the dropdown when input looks like a page number
                  final text = _textController.text.trimLeft();
                  if (text.isEmpty || RegExp(r'^\d').hasMatch(text)) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'No surahs found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context) {
                  return Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                decorationBuilder: (context, child) {
                  return Material(
                    type: MaterialType.card,
                    elevation: 4,
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: child,
                  );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Familiarity
              Text('FAMILIARITY', style: AppTextStyles.label),
              const SizedBox(height: 10),
              FamiliarityPills(
                onChanged: (value) => _familiarity = value,
              ),
              const SizedBox(height: 28),
              // Recent sessions
              Text('CONTINUE WHERE YOU LEFT OFF', style: AppTextStyles.label),
              const SizedBox(height: 12),
              if (_isLoadingRecent)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_recentError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _recentError!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else if (_recentSessions == null || _recentSessions!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No recent sessions',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                ..._recentSessions!.take(5).toList().asMap().entries.expand((entry) {
                  final session = entry.value;
                  final isLast = entry.key == _recentSessions!.length - 1;
                  return [
                    _recentRow(session),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.borderLight,
                      ),
                  ];
                }),
              const Spacer(),
              // Prepare button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPreparing ? null : _prepare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Prepare'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
          if (_isPreparing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recentRow(RecentSession session) {
    return InkWell(
      onTap: () => _onRecentSessionTap(session),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sessionTitle(session),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
                if (session.feeling == 'revisit') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Revisit',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              formatRelativeDate(session.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
