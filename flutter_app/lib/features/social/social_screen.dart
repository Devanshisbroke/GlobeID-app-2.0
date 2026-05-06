import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';

/// Social v3 — flagship social feed.
///
/// Stories rail (with active ring + view-state), suggested travellers
/// list with toggleable Follow chips, post feed with engagement
/// buttons, and a `+` FAB that opens a Create Post bottom sheet.
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final Set<String> _following = <String>{};
  final Set<int> _liked = <int>{};
  final Set<int> _bookmarked = <int>{};

  // ── Stories ─────────────────────────────────────────────────────
  final _stories = <_Story>[
    const _Story('Aria', '🇬🇧', true, true),
    const _Story('Kenji', '🇯🇵', true, false),
    const _Story('Marcus', '🇺🇸', true, false),
    const _Story('Lina', '🇩🇪', false, false),
    const _Story('Sofia', '🇪🇸', true, true),
    const _Story('Hiro', '🇯🇵', true, false),
    const _Story('Olu', '🇳🇬', false, false),
  ];

  // ── Suggestions ─────────────────────────────────────────────────
  final _suggestions = const [
    _SocialUser('Aria', '12 trips · GBP', '🇬🇧'),
    _SocialUser('Kenji', '8 trips · JPY', '🇯🇵'),
    _SocialUser('Marcus', '21 trips · USD', '🇺🇸'),
    _SocialUser('Lina', '6 trips · EUR', '🇩🇪'),
    _SocialUser('Sofia', '14 trips · EUR', '🇪🇸'),
  ];

  // ── Posts ───────────────────────────────────────────────────────
  final _posts = <_Post>[
    const _Post(
      author: 'Aria',
      avatar: '🇬🇧',
      timestamp: '2h',
      caption: 'Just landed at NRT for cherry blossom season ✈️ '
          'The 12-hour flight from LHR was buttery on the new 787-9.',
      tags: ['#tokyo', '#nrt', '#cherryblossom'],
      likes: 132,
      comments: 14,
      hero: '🌸',
      heroBg: Color(0xFFFFC0CB),
    ),
    _Post(
      author: 'Kenji',
      avatar: '🇯🇵',
      timestamp: '6h',
      caption:
          'Top tip: book Premium Lounge at NRT T1 with AmEx Platinum, the '
          'sushi counter is unreal.',
      tags: const ['#nrt', '#lounge', '#tip'],
      likes: 84,
      comments: 9,
      hero: '🍣',
      heroBg: const Color(0xFFFFB347),
    ),
    const _Post(
      author: 'Marcus',
      avatar: '🇺🇸',
      timestamp: '1d',
      caption: 'JFK → LHR was 6h35m thanks to the polar jet stream. '
          'Got a wallet alert that my GBP balance refilled automatically.',
      tags: ['#jfk', '#lhr', '#wallet'],
      likes: 213,
      comments: 31,
      hero: '🛩️',
      heroBg: Color(0xFF6FB7FF),
    ),
    const _Post(
      author: 'Sofia',
      avatar: '🇪🇸',
      timestamp: '2d',
      caption: 'Barcelona dinner spot of the week: Disfrutar. '
          'Identity tier upgraded after 14 stamps this year.',
      tags: ['#bcn', '#dinner', '#identity'],
      likes: 178,
      comments: 22,
      hero: '🥘',
      heroBg: Color(0xFFFFD580),
    ),
  ];

  void _toggleFollow(String name) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_following.contains(name)) {
        _following.remove(name);
      } else {
        _following.add(name);
      }
    });
    AppToast.show(
      context,
      title: _following.contains(name) ? 'Following $name' : 'Unfollowed $name',
      tone: AppToastTone.info,
    );
  }

  void _toggleLike(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_liked.contains(i)) {
        _liked.remove(i);
      } else {
        _liked.add(i);
      }
    });
  }

  void _toggleBookmark(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_bookmarked.contains(i)) {
        _bookmarked.remove(i);
      } else {
        _bookmarked.add(i);
      }
    });
  }

  Future<void> _openCreatePost() async {
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<_NewPostDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreatePostSheet(),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _posts.insert(
        0,
        _Post(
          author: 'You',
          avatar: '🌍',
          timestamp: 'now',
          caption: result.caption,
          tags: result.tags,
          likes: 0,
          comments: 0,
          hero: result.hero,
          heroBg: const Color(0xFFB0E0E6),
        ),
      );
    });
    AppToast.show(
      context,
      title: 'Posted',
      message: 'Visible to your circle',
      tone: AppToastTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Social',
      subtitle: 'Follow, post, and react across your circle',
      actions: [
        IconButton(
          tooltip: 'New post',
          icon: const Icon(Icons.edit_rounded),
          onPressed: _openCreatePost,
        ),
      ],
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Stories rail
          AnimatedAppearance(
            child: SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: _stories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  if (i == 0) return _AddStoryTile(onTap: _openCreatePost);
                  return _StoryTile(story: _stories[i - 1]);
                },
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTokens.space4,
                0,
                AppTokens.space2,
              ),
              child: Text(
                'SUGGESTED TRAVELLERS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          for (var i = 0; i < _suggestions.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 120 + 50 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: _SuggestionRow(
                  user: _suggestions[i],
                  following: _following.contains(_suggestions[i].name),
                  onToggle: () => _toggleFollow(_suggestions[i].name),
                ),
              ),
            ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTokens.space5,
                0,
                AppTokens.space2,
              ),
              child: Row(
                children: [
                  Text(
                    'CIRCLE FEED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: _openCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                        gradient: LinearGradient(colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ]),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < _posts.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 420 + 60 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space3),
                child: _PostCard(
                  post: _posts[i],
                  liked: _liked.contains(i),
                  bookmarked: _bookmarked.contains(i),
                  onLike: () => _toggleLike(i),
                  onBookmark: () => _toggleBookmark(i),
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ─── Story tile ────────────────────────────────────────────────────

class _Story {
  const _Story(this.name, this.avatar, this.hasUnseen, this.live);
  final String name;
  final String avatar;
  final bool hasUnseen;
  final bool live;
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story});
  final _Story story;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.hasUnseen
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFEC4899),
                        const Color(0xFFF59E0B),
                        theme.colorScheme.primary,
                      ],
                    )
                  : null,
              color: story.hasUnseen
                  ? null
                  : theme.colorScheme.onSurface.withValues(alpha: 0.16),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.4),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Center(
                      child: Text(
                        story.avatar,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    if (story.live)
                      Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusFull,
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 7,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoryTile extends StatelessWidget {
  const _AddStoryTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Pressable(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ]),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your story',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion row ───────────────────────────────────────────────

class _SocialUser {
  const _SocialUser(this.name, this.subtitle, this.flag);
  final String name;
  final String subtitle;
  final String flag;
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.user,
    required this.following,
    required this.onToggle,
  });
  final _SocialUser user;
  final bool following;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary.withValues(alpha: 0.55),
                theme.colorScheme.primary.withValues(alpha: 0.18),
              ]),
            ),
            child: Text(user.flag, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppTokens.durationSm,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                gradient: following
                    ? null
                    : LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]),
                color: following
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                    : null,
                border: Border.all(
                  color: following
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    following
                        ? Icons.check_rounded
                        : Icons.add_rounded,
                    size: 14,
                    color: following
                        ? theme.colorScheme.onSurface
                        : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    following ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: following
                          ? theme.colorScheme.onSurface
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post card ─────────────────────────────────────────────────────

class _Post {
  const _Post({
    required this.author,
    required this.avatar,
    required this.timestamp,
    required this.caption,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.hero,
    required this.heroBg,
  });
  final String author;
  final String avatar;
  final String timestamp;
  final String caption;
  final List<String> tags;
  final int likes;
  final int comments;
  final String hero;
  final Color heroBg;
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.liked,
    required this.bookmarked,
    required this.onLike,
    required this.onBookmark,
  });
  final _Post post;
  final bool liked;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.4),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Text(post.avatar,
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      post.timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Container(
            height: 156,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  post.heroBg,
                  post.heroBg.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Text(
              post.hero,
              style: const TextStyle(fontSize: 80),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            post.caption,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space2),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in post.tags)
                  Text(
                    t,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space3),
          Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          const SizedBox(height: AppTokens.space2),
          Row(
            children: [
              _PostAction(
                icon:
                    liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                label: '${post.likes + (liked ? 1 : 0)}',
                tone: const Color(0xFFEC4899),
                active: liked,
                onTap: onLike,
              ),
              const SizedBox(width: 12),
              _PostAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments}',
                tone: theme.colorScheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              const SizedBox(width: 12),
              _PostAction(
                icon: Icons.share_rounded,
                label: '',
                tone: theme.colorScheme.secondary,
                onTap: () {
                  HapticFeedback.lightImpact();
                },
              ),
              const Spacer(),
              _PostAction(
                icon: bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: '',
                tone: const Color(0xFFF59E0B),
                active: bookmarked,
                onTap: onBookmark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    required this.tone,
    this.active = false,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color tone;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: AppTokens.durationSm,
            child: Icon(
              icon,
              key: ValueKey(active),
              size: 20,
              color: active
                  ? tone
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: active
                    ? tone
                    : theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Create post sheet ─────────────────────────────────────────────

class _NewPostDraft {
  const _NewPostDraft({
    required this.caption,
    required this.tags,
    required this.hero,
  });
  final String caption;
  final List<String> tags;
  final String hero;
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _ctrl = TextEditingController();
  String _hero = '🌍';
  final Set<String> _tags = {};
  static const _availableTags = [
    '#trip',
    '#flight',
    '#wallet',
    '#identity',
    '#food',
    '#stay',
    '#tip',
    '#milestone',
  ];
  static const _heroes = ['🌍', '✈️', '🌸', '🍣', '🥘', '🛩️', '🌅', '🌃'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _post() {
    final caption = _ctrl.text.trim();
    if (caption.isEmpty) {
      HapticFeedback.lightImpact();
      return;
    }
    Navigator.of(context).pop(
      _NewPostDraft(
        caption: caption,
        tags: _tags.toList(),
        hero: _hero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTokens.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
              ),
            ),
            Text(
              'Share something',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 280,
              decoration: InputDecoration(
                hintText: 'What\'s up at your next stop?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'HERO',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in _heroes)
                  Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _hero = h);
                    },
                    child: AnimatedContainer(
                      duration: AppTokens.durationSm,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hero == h
                            ? theme.colorScheme.primary.withValues(alpha: 0.20)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.04),
                        border: Border.all(
                          color: _hero == h
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(h, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              'TAGS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in _availableTags)
                  Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_tags.contains(t)) {
                          _tags.remove(t);
                        } else {
                          _tags.add(t);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: AppTokens.durationSm,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        color: _tags.contains(t)
                            ? theme.colorScheme.primary.withValues(alpha: 0.20)
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.04),
                        border: Border.all(
                          color: _tags.contains(t)
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.40)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        t,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _tags.contains(t)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _post,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Post'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
