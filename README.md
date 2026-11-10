# Task Manager

A Flutter application for authenticated Task management, Tag categorization and
hierarchical Nomenclatures. Administrators can create, edit and delete records;
other authenticated users have read-only access.

Tasks include status, priority, an optional due date (`YYYY-MM-DD`), assignee,
multiple tags and an optional nomenclature. Nomenclature selectors show ancestry
paths; the parent editor excludes the current node and its descendants. Backend
validation errors, including referenced-category deletion failures, remain visible.

The reusable `domain_template_client` package retains its existing package identity
and lives in the sibling repository `../template-flutter-api-client`. Import
`package:domain_template_client/task_client.dart`, `tag_client.dart` or
`nomenclature_client.dart` for the corresponding authenticated REST clients.
Task seed/import/export endpoints remain available on `TaskClient`.
JSON seed/import requests retain all task fields. Missing task extras default to
`TODO`, `NORMAL`, empty tags and null optional values. Due dates remain date-only;
assignees are free text, not user foreign keys. Referenced tags/nomenclatures must
already exist in the same backend database before importing tasks. CSV is passed
through unchanged; the appended columns are `status,priority,dueDate,assignedTo,tagIds,nomenclatureId`,
with semicolon-separated numeric tag IDs.

## Getting Started

With the Flutter SDK installed, run:

```sh
flutter pub get
flutter test
flutter analyze
dart format lib test
```

Run `dart pub get`, `dart test` and `dart analyze` in `../template-flutter-api-client` for the
standalone client package.

## Release packages

The `Flutter releases` workflow packages Android and Linux on Ubuntu and Windows on
a Windows runner, checking out `tiogars/template-flutter-api-client` next to this
repository. Set the `API_BASE_URL` Actions variable to the public HTTPS API URL
compiled into the applications. Pushing a `v*` tag publishes a GitHub Release with
the packages and `build-info-<platform>.json` files; the next
`template-react-backend` image build embeds them in its download page.

## Run and debug on Windows

Install Visual Studio or Visual Studio Build Tools with the **Desktop development
with C++** workload, a Windows SDK, and **C++ ATL for latest build tools (x86 &
x64)** matching the installed MSVC toolset. The Windows secure-storage plugin
requires ATL. If compilation reports that `atlstr.h` is missing, open Visual
Studio Installer, modify the Build Tools installation, and add ATL under
**Individual components**. This dependency can be missing even when
`flutter doctor -v` reports a healthy Windows toolchain.

Check the toolchain with `flutter doctor -v` and confirm that `flutter devices`
lists `Windows (desktop)`.

From this application's directory, run:

```powershell
flutter run -d windows --debug
```

In the running terminal, press `r` for hot reload, `R` for hot restart, or `q`
to quit. In VS Code with the Flutter extension, open this directory, select
**Windows (desktop)**, and press **F5** to debug with breakpoints.

The login screen can open without a running API. Authenticated operations require
the Spring Boot API and its database. The default API URL is
`http://localhost:8989` (the local Docker stack); use **API settings** on the login
screen to select another server, such as `http://localhost:8080` for a locally
started API. Saving a different API URL signs out the current session.
Use an account from that server; the local Docker development defaults are
`admin` / `admin` unless overridden.

For a first manual desktop check:

1. Open **API settings**, verify the URL, and return to **Tasks** to sign in.
2. Sign in and open a task from the table.
3. With an administrator account, create a task, edit it, then delete it with
   confirmation.
4. Open **Tags** and **Nomenclatures**, then resize the window to check both
   table and compact navigation layouts.
5. Sign out and verify that protected pages return to the login screen.

Widget tests use in-memory repositories; they do not verify real API connectivity,
database persistence, or native Windows plugin behavior.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
