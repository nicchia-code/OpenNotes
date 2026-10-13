#include <gio/gdesktopappinfo.h>
#include <gio/gio.h>

#include "my_application.h"

// Registers the opennotes:// scheme for the current user, so that the browser
// can hand the Google sign-in back to this app when port 3000 is busy. Writes
// a desktop entry pointing at this executable and makes it the default handler.
// ponytail: the executable path is not escaped; paths with quotes or $ break Exec.
static void register_opennotes_scheme() {
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  if (exe_path == nullptr) {
    return;
  }
  g_autofree gchar* dir =
      g_build_filename(g_get_user_data_dir(), "applications", nullptr);
  g_mkdir_with_parents(dir, 0755);
  g_autofree gchar* file_name = g_strdup_printf("%s.desktop", APPLICATION_ID);
  g_autofree gchar* desktop_file = g_build_filename(dir, file_name, nullptr);
  g_autofree gchar* contents = g_strdup_printf(
      "[Desktop Entry]\n"
      "Type=Application\n"
      "Name=OpenNotes\n"
      "Exec=\"%s\" %%u\n"
      "Terminal=false\n"
      "MimeType=x-scheme-handler/opennotes;\n",
      exe_path);
  if (!g_file_set_contents(desktop_file, contents, -1, nullptr)) {
    return;
  }
  GDesktopAppInfo* app_info =
      g_desktop_app_info_new_from_filename(desktop_file);
  if (app_info != nullptr) {
    g_app_info_set_as_default_for_type(G_APP_INFO(app_info),
                                       "x-scheme-handler/opennotes", nullptr);
    g_object_unref(app_info);
  }
}

int main(int argc, char** argv) {
  register_opennotes_scheme();
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
