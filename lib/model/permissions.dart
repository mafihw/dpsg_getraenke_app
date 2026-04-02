import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dpsg_app/connection/backend.dart';
import 'package:dpsg_app/connection/storage_interface.dart';
import 'package:get_it/get_it.dart';

enum Permission {
  canGetAllUsers,
  canPurchaseForOthers,
  canRegisterUsers,
  canEditOtherUsers,
  canEditDrinks,
  canEditPurchases,
  canSeeAllPurchases,
  canPayForOthers,
  canEditRoles,
  canEditPermissions,
}

class PermissionSystem {
  List<Permission> permissions = [];
  bool isInitialized = false;

  Future<void> init() async {
    await fetchPermissions();
    isInitialized = true;
  }

  Future<List<Permission>> fetchPermissions() async {
    List<Permission> fetchedPermissions = [];
    var backend = GetIt.instance<Backend>();
    if (backend.isOnlineMode) {
      //try to fetch data from server
      try {
        final response = await backend.get('/permissions');
        if (response != null) {
          fetchedPermissions = permissionsFromJson(response);
          await _storePermissionsJson(response);
        }
      } catch (e) {
        developer.log(e.toString());
      }
    }
    //load permissions from local storage
    if (fetchedPermissions.isEmpty) {
      fetchedPermissions = await _getLocalPermissions();
    }

    permissions = fetchedPermissions;

    return fetchedPermissions;
  }

  Future<void> _storePermissionsJson(dynamic permissions) async {
    await GetIt.I<StorageInterface>().setSettingByKey(
      'permissions',
      jsonEncode(permissions),
    );
  }

  Future<List<Permission>> _getLocalPermissions() async {
    dynamic permissionsJson = await GetIt.I<StorageInterface>().getSettingByKey(
      'permissions',
    );
    if (permissionsJson != null) {
      return permissionsFromJson(jsonDecode(permissionsJson));
    } else {
      return [];
    }
  }

  List<Permission> permissionsFromJson(dynamic json) {
    List<Permission> result = [];
    if (json != null && json != '[]') {
      for (var entry in json.toList()) {
        switch (entry) {
          case 'canGetAllUsers':
            result.add(Permission.canGetAllUsers);
            break;
          case 'canPurchaseForOthers':
            result.add(Permission.canPurchaseForOthers);
            break;
          case 'canRegisterUsers':
            result.add(Permission.canRegisterUsers);
            break;
          case 'canEditOtherUsers':
            result.add(Permission.canEditOtherUsers);
            break;
          case 'canEditDrinks':
            result.add(Permission.canEditDrinks);
            break;
          case 'canEditPurchases':
            result.add(Permission.canEditPurchases);
            break;
          case 'canSeeAllPurchases':
            result.add(Permission.canSeeAllPurchases);
            break;
          case 'canPayForOthers':
            result.add(Permission.canPayForOthers);
            break;
          case 'canEditRoles':
            result.add(Permission.canEditRoles);
            break;
          case 'canEditPermissions':
            result.add(Permission.canEditPermissions);
            break;
        }
      }
    }
    return result;
  }

  bool userHasPermission(Permission permissionToCheck) {
    return permissions.contains(permissionToCheck);
  }
}
