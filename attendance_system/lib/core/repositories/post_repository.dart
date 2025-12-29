import '../models/post_model.dart';
import '../models/user_model.dart';

abstract class PostRepository {
  Future<List<Post>> getAllPosts();
  Future<List<Post>> getPostsByRole(UserRole role);
  Future<Post?> getPostById(String id);
  Future<Post> createPost(Post post);
  Future<Post> updatePost(Post post);
  Future<void> deletePost(String id);
}

class InMemoryPostRepository implements PostRepository {
  final Map<String, Post> _posts = {};

  @override
  Future<List<Post>> getAllPosts() async {
    return _posts.values.toList()..sort((a, b) => 
      b.createdAt.compareTo(a.createdAt)
    );
  }

  @override
  Future<List<Post>> getPostsByRole(UserRole role) async {
    final allPosts = await getAllPosts();
    return allPosts.where((p) => 
      p.targetRoles.isEmpty || 
      p.targetRoles.contains(role.toString().split('.').last)
    ).toList();
  }

  @override
  Future<Post?> getPostById(String id) async {
    return _posts[id];
  }

  @override
  Future<Post> createPost(Post post) async {
    _posts[post.id] = post;
    return post;
  }

  @override
  Future<Post> updatePost(Post post) async {
    _posts[post.id] = post;
    return post;
  }

  @override
  Future<void> deletePost(String id) async {
    _posts.remove(id);
  }
}

