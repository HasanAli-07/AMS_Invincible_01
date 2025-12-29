import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models/post_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/app_provider.dart';
import '../../design_system/tokens/radius_tokens.dart';

enum PostVisibility { global, departmental }

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final List<String> _pinnedIds = [];
  bool _isLoading = false;
  List<Post> _posts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    final appState = AppProvider.of(context);
    final user = appState.currentUser;
    if (user == null) {
      setState(() {
        _posts = [];
        _isLoading = false;
      });
      return;
    }
    final repo = appState.postRepo;
    final data = user.role == UserRole.admin
        ? await repo.getAllPosts()
        : await repo.getPostsByRole(user.role);
    setState(() {
      _posts = data;
      _isLoading = false;
    });
  }

  void _togglePin(String id) {
    setState(() {
      if (_pinnedIds.contains(id)) {
        _pinnedIds.remove(id);
      } else {
        _pinnedIds.add(id);
      }
    });
  }

  bool get _canCreate {
    final user = AppProvider.of(context).currentUser;
    if (user == null) return false;
    return user.role != UserRole.student;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = AppProvider.of(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        title: const Text(
          'Posts & Announcements',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _openComposer,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final isPinned = _pinnedIds.contains(post.id);
                  final canPin = user?.role == UserRole.student;
                  return _PostCard(
                    post: post,
                    isPinned: isPinned,
                    canPin: canPin,
                    onPinToggle: () => _togglePin(post.id),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openComposer() async {
    final result = await showModalBottomSheet<Post?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _PostComposerSheet(),
    );
    if (result != null) {
      final appState = AppProvider.of(context);
      await appState.postRepo.createPost(result);
      await _loadPosts();
    }
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool isPinned;
  final bool canPin;
  final VoidCallback onPinToggle;

  const _PostCard({
    required this.post,
    required this.isPinned,
    required this.canPin,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (canPin)
                IconButton(
                  onPressed: onPinToggle,
                  icon: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? colors.primary : colors.onSurfaceVariant,
                  ),
                  tooltip: isPinned ? 'Unpin' : 'Pin for reminder',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            post.content,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (post.attachments.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.attachments
                  .map((a) => Chip(
                        label: Text(
                          a.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                        avatar: const Icon(Icons.attachment, size: 16),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.public,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                post.targetRoles.isEmpty
                    ? 'All roles'
                    : post.targetRoles.join(', '),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatDate(post.createdAt),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _PostComposerSheet extends StatefulWidget {
  const _PostComposerSheet();

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PostVisibility _visibility = PostVisibility.global;
  final List<String> _attachments = [];
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final f in result.files) {
        if (f.path != null) {
          _attachments.add(f.path!);
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Post',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Content required' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Post type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                  color: colors.surfaceVariant.withOpacity(0.4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Global',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: _visibility == PostVisibility.global,
                        onSelected: (_) =>
                            setState(() => _visibility = PostVisibility.global),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Departmental',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: _visibility == PostVisibility.departmental,
                        onSelected: (_) => setState(
                          () => _visibility = PostVisibility.departmental,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._attachments.map(
                    (a) => Chip(
                      label: Text(
                        a.split(Platform.pathSeparator).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: const Icon(Icons.attachment, size: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickAttachments,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add attachments'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Publish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final appState = AppProvider.of(context);
    final user = appState.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    final now = DateTime.now();
    final targets = _visibility == PostVisibility.global
        ? ['admin', 'principal', 'teacher', 'student']
        : ['teacher'];

    final post = Post(
      id: 'post-${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      authorId: user.id,
      authorRole: user.role,
      createdAt: now,
      attachments: List<String>.from(_attachments),
      targetRoles: targets,
    );

    Navigator.of(context).pop(post);
  }
}

