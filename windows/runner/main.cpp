#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

// Registers the opennotes:// scheme for the current user, so that the browser
// can hand the Google sign-in back to this app when port 3000 is busy.
static void RegisterOpenNotesScheme() {
  wchar_t exe_path[MAX_PATH];
  if (::GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) {
    return;
  }
  const std::wstring description = L"URL:OpenNotes";
  const std::wstring command = std::wstring(L"\"") + exe_path + L"\" \"%1\"";
  ::RegSetKeyValueW(HKEY_CURRENT_USER, L"Software\\Classes\\opennotes", nullptr,
                    REG_SZ, description.c_str(),
                    (description.size() + 1) * sizeof(wchar_t));
  ::RegSetKeyValueW(HKEY_CURRENT_USER, L"Software\\Classes\\opennotes",
                    L"URL Protocol", REG_SZ, L"", sizeof(wchar_t));
  ::RegSetKeyValueW(HKEY_CURRENT_USER,
                    L"Software\\Classes\\opennotes\\shell\\open\\command",
                    nullptr, REG_SZ, command.c_str(),
                    (command.size() + 1) * sizeof(wchar_t));
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  RegisterOpenNotesScheme();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 760);
  if (!window.Create(L"open_notes", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
