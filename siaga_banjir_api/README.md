# Siaga Banjir API

Backend foundation for the academic Siaga Banjir Padang simulation. This is not an official BPBD or emergency service. No domain tables, feature controllers, external integrations, or production claims are included yet.

## Runtime

- Laravel Framework 13.38.0
- PHP CLI 8.3.33 from `E:\laragon\bin\php\php-8.3.33-Win32-vs16-x64`
- Composer 2.10.2 PHAR from `E:\laragon\bin\composer\composer.phar`
- Laravel Sanctum 4.3.3 for token-authenticated mobile API requests
- MySQL database name: `siaga_banjir` (created and started by the project owner)

The Composer wrapper in Laragon expects `php` on `PATH`. To use PHP/Composer in a PowerShell session without changing global Windows or Laragon settings:

```powershell
$phpDir = 'E:\laragon\bin\php\php-8.3.33-Win32-vs16-x64'
$env:PATH = "$phpDir;$env:PATH"
php -v
```

For Composer commands when PHP's ZIP extension is not enabled in `php.ini`, enable the already installed DLL for this command only:

```powershell
& "$phpDir\php.exe" -d 'extension=E:/laragon/bin/php/php-8.3.33-Win32-vs16-x64/ext/php_zip.dll' `
  'E:\laragon\bin\composer\composer.phar' install --no-interaction
```

No global PATH, PHP, or Laragon configuration was changed.

## Local environment

1. Copy `.env.example` to `.env` only if `.env` does not already exist.
2. In `.env`, replace each `__SET_FROM_LARAGON__` value using the active Laragon MySQL connection details. Keep `DB_DATABASE=siaga_banjir`; enter the actual host, port, and username. Set `DB_PASSWORD` locally. Do not commit `.env` or share its password.
3. Set `APP_URL` to the local address you actually use. For a physical Android device, use a reachable laptop address or USB port forwarding; `localhost` on the phone is not the laptop.
4. Start Apache/Nginx and MySQL from Laragon manually. This project does not change Windows services or Laragon settings.

The `.env.example` contains placeholders, not assumed connection values. The generated local `.env` is also left with placeholders until the owner fills in Laragon's actual values. MySQL connectivity has not been tested.

## Current API foundation

- `routes/api.php` contains the starter protected `GET /api/user` route using `auth:sanctum`.
- The `User` model has Sanctum's `HasApiTokens` trait.
- Laravel Blade routes retain Laravel's normal `web` session middleware.
- Sanctum's `personal_access_tokens` migration template is present. It has **not** been run against MySQL.
- There is not yet a login/token issuance endpoint, role schema, staff authorization middleware, or domain API. Do not expose staff endpoints until role-based server-side authorization is implemented.

## Migration status and safety

The Laravel 13 skeleton's `post-create-project-cmd` automatically created `database/database.sqlite` and ran its three default framework migrations. `php artisan migrate:status` confirmed those three migrations as `Ran` against the scaffold's default SQLite connection. The MySQL database `siaga_banjir` was not contacted. The Sanctum token migration was published afterward and remains pending.

Do not run `php artisan migrate` until the schema has been reviewed and `.env` has been filled and checked. `php artisan migrate:status` is read-only, but once `.env` points to MySQL it will need valid connection details.

## Run the local web server

After installing dependencies and filling `.env` with the verified local database settings:

```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Binding to all interfaces is only for local device testing; use a narrowly scoped firewall rule if required and remove it after testing. Production requires HTTPS and a proper web-server configuration.

## Not implemented yet

Citizen authentication flows, staff account provisioning, role middleware, domain migrations/models/controllers, SOS/report/family workflows, Blade pages, map provider, push notification, and BMKG integration are not part of this foundation. Review `../flutter_firstapp/docs/requirements_analysis.md` and `../flutter_firstapp/docs/implementation_plan.md` before adding them.
