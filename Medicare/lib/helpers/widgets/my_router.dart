import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare/helpers/widgets/my_middleware.dart';
import 'package:medicare/helpers/widgets/my_route.dart';
import 'package:medicare/helpers/widgets/my_route_exception.dart';
import 'package:medicare/helpers/widgets/my_routes.dart';

/// Middleware that redirects unauthenticated users to /auth/login.
/// Register it on any [MyRoute] that requires authentication.
class AuthGuard extends MyMiddleware {
  @override
  String handle(String routeName) {
    if (FirebaseAuth.instance.currentUser != null) return routeName;
    final next = Uri.encodeComponent(routeName);
    return '/auth/login?next=$next';
  }
}

class MyRouter {
  static T? getArgs<T>(BuildContext context) {
    try {
      Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args is T) return args;
      return null;
    } catch (e) {
      throw RouteException(
          "Use getArgs in onReady state. Don't use in constructor or initState");
    }
  }

  static MyRoute? _getRouteFromRouteName(String routeName) {
    for (MyRoute route in MyRoutes.routes) {
      if (route.name.compareTo(routeName) == 0) return route;
    }
    return null;
  }

  static MyRoute? getSecuredRouteFromRouteName(String routeName) {
    Uri uri = Uri.parse(routeName);
    var route0 = uri.path;
    MyRoute? route = _getRouteFromRouteName(route0);
    if (route == null) return null;

    if (route.middlewares != null && route.middlewares!.isNotEmpty) {
      for (MyMiddleware middleware in route.middlewares!) {
        String redirectedRouteName = middleware.handle(route0);
        if (redirectedRouteName.compareTo(route0) != 0) {
          return getSecuredRouteFromRouteName(redirectedRouteName);
        }
      }
    }
    return route;
  }

  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      final next = Uri.encodeComponent(routeName);
      return Navigator.of(context)
          .pushReplacementNamed('/auth/login?next=$next') as Future<T?>;
    }
    MyRoute? route = getSecuredRouteFromRouteName(routeName);
    if (route == null) {
      throw RouteException("'$routeName' Route is not implemented");
    }
    return Navigator.of(context).pushNamed<T>(route.name, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      final next = Uri.encodeComponent(routeName);
      return Navigator.of(context)
          .pushReplacementNamed('/auth/login?next=$next') as Future<T?>;
    }
    MyRoute? route = getSecuredRouteFromRouteName(routeName);
    if (route == null) {
      throw RouteException("'$routeName' Route is not implemented");
    }
    return Navigator.of(context)
        .pushReplacementNamed<T, TO>(route.name, arguments: arguments);
  }
}
