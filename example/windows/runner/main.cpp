#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr unsigned int kInitialWidth = 420;
constexpr unsigned int kInitialHeight = 840;

// Compose Desktop's WindowPosition.Aligned(Center) centers the original 420 x
// 840dp window in the primary work area. Win32 receives logical dimensions in
// this runner and scales them inside Win32Window::Create, so convert the work
// area back to logical pixels before calculating the matching origin.
Win32Window::Point CenteredPrimaryOrigin() {
  RECT work_area{};
  if (!::SystemParametersInfoW(SPI_GETWORKAREA, 0, &work_area, 0)) {
    work_area = {0, 0, ::GetSystemMetrics(SM_CXSCREEN),
                 ::GetSystemMetrics(SM_CYSCREEN)};
  }
  const UINT dpi = ::GetDpiForSystem();
  const double scale = dpi > 0 ? static_cast<double>(dpi) / 96.0 : 1.0;
  const int logical_width = static_cast<int>(
      (work_area.right - work_area.left) / scale);
  const int logical_height = static_cast<int>(
      (work_area.bottom - work_area.top) / scale);
  const int logical_left = static_cast<int>(work_area.left / scale);
  const int logical_top = static_cast<int>(work_area.top / scale);
  const int x =
      logical_left + (logical_width - static_cast<int>(kInitialWidth)) / 2;
  const int y =
      logical_top + (logical_height - static_cast<int>(kInitialHeight)) / 2;
  return Win32Window::Point(static_cast<unsigned int>(x > 0 ? x : 0),
                           static_cast<unsigned int>(y > 0 ? y : 0));
}

}  // namespace

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

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  const Win32Window::Point origin = CenteredPrimaryOrigin();
  const Win32Window::Size size(kInitialWidth, kInitialHeight);
  if (!window.Create(L"Miuix", origin, size)) {
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
