# Seeders

This directory contains database seeders that populate the Isar database with initial data, similar to Laravel's seeding system.

## UserSeeder

The `UserSeeder` class populates the User collection with default users following a firstOrCreate pattern to prevent duplicates.

### Usage

The seeder can be run in two ways:

#### 1. Automatic seeding in debug mode

Add this flag when running your app to automatically seed data in debug mode:

```bash
flutter run --debug --dart-define=DEBUG_MODE=true
```

#### 2. Manual seeding

You can manually run the seeder from anywhere in your code:

```dart
import 'package:caisse_1/seeders/database_seeder.dart';
import 'package:caisse_1/services/database_service.dart';

// Run all seeders
await DatabaseSeeder.seed(DatabaseService.db);
```

### Seeded Data

The UserSeeder creates the following default users:

- **Super Admin**: `superadmin@example.com` (no restaurant, no pin code)
- **Admin**: `admin@example.com` (assigned to restaurant ID 1, no pin code) 
- **Staff**: `staff@example.com` (assigned to restaurant ID 1, with pin code '1234')
- **Client**: `client@example.com` (no restaurant, no pin code)

All users have the password `password123` (hashed with SHA256).

### Architecture

- `database_seeder.dart`: Main seeder that orchestrates all other seeders
- `user_seeder.dart`: Seeds the User collection with default users
- Follows Laravel-like firstOrCreate pattern to prevent duplicate entries
- Uses Isar transactions for data integrity