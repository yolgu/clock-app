#include "local_state_file.h"

#include <windows.h>
#include <shlobj.h>

#include <algorithm>
#include <filesystem>
#include <limits>
#include <system_error>
#include <utility>

namespace {

constexpr std::uint64_t kMaximumStateBytes = 64 * 1024;

bool IsValidIdentity(const std::wstring& identity) {
  if (identity.empty() || identity.size() > 128) {
    return false;
  }
  return std::all_of(identity.begin(), identity.end(), [](wchar_t value) {
    return (value >= L'a' && value <= L'z') ||
           (value >= L'A' && value <= L'Z') ||
           (value >= L'0' && value <= L'9') || value == L'.' ||
           value == L'_' || value == L'-';
  });
}

std::optional<std::wstring> ResolveLocalAppDataRoot() {
  PWSTR resolved = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_DEFAULT,
                                    nullptr, &resolved))) {
    return std::nullopt;
  }
  const std::wstring value(resolved);
  ::CoTaskMemFree(resolved);
  return value.empty() ? std::nullopt
                       : std::optional<std::wstring>(value);
}

bool WriteAll(HANDLE file, const std::vector<std::uint8_t>& bytes) {
  std::size_t written_total = 0;
  while (written_total < bytes.size()) {
    const std::size_t remaining = bytes.size() - written_total;
    const DWORD chunk_size = static_cast<DWORD>(std::min<std::size_t>(
        remaining, std::numeric_limits<DWORD>::max()));
    DWORD written = 0;
    if (!::WriteFile(file, bytes.data() + written_total, chunk_size, &written,
                     nullptr) ||
        written == 0) {
      return false;
    }
    written_total += written;
  }
  return true;
}

}  // namespace

LocalStateFile::LocalStateFile(std::wstring application_identity,
                               std::wstring root_override)
    : application_identity_(std::move(application_identity)),
      root_override_(std::move(root_override)) {}

std::optional<LocalStatePaths> LocalStateFile::ResolvePaths() const {
  if (!IsValidIdentity(application_identity_)) {
    return std::nullopt;
  }
  const std::optional<std::wstring> resolved_root = root_override_.empty()
                                                       ? ResolveLocalAppDataRoot()
                                                       : root_override_;
  if (!resolved_root.has_value() || resolved_root->empty()) {
    return std::nullopt;
  }
  const std::filesystem::path root(resolved_root.value());
  const std::filesystem::path directory =
      root / L"Clock Rhythm" / application_identity_;
  const std::filesystem::path file = directory / L"window-state.json";
  return LocalStatePaths{root.wstring(), directory.wstring(), file.wstring()};
}

LocalStateReadResult LocalStateFile::Read() const {
  const std::optional<LocalStatePaths> paths = ResolvePaths();
  if (!paths.has_value()) {
    return LocalStateReadResult{LocalStateReadStatus::kError, {}};
  }
  HANDLE file = ::CreateFileW(paths->file.c_str(), GENERIC_READ, FILE_SHARE_READ,
                              nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                              nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return LocalStateReadResult{
        ::GetLastError() == ERROR_FILE_NOT_FOUND
            ? LocalStateReadStatus::kMissing
            : LocalStateReadStatus::kError,
        {}};
  }
  LARGE_INTEGER size{};
  if (!::GetFileSizeEx(file, &size) || size.QuadPart < 0 ||
      static_cast<std::uint64_t>(size.QuadPart) > kMaximumStateBytes) {
    ::CloseHandle(file);
    return LocalStateReadResult{LocalStateReadStatus::kError, {}};
  }
  std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size.QuadPart));
  DWORD read = 0;
  const bool read_ok = bytes.empty() ||
                       (::ReadFile(file, bytes.data(),
                                   static_cast<DWORD>(bytes.size()), &read,
                                   nullptr) != FALSE &&
                        read == bytes.size());
  ::CloseHandle(file);
  return read_ok
             ? LocalStateReadResult{LocalStateReadStatus::kSuccess,
                                    std::move(bytes)}
             : LocalStateReadResult{LocalStateReadStatus::kError, {}};
}

bool LocalStateFile::WriteAtomic(
    const std::vector<std::uint8_t>& bytes) const {
  if (bytes.size() > kMaximumStateBytes) {
    return false;
  }
  const std::optional<LocalStatePaths> paths = ResolvePaths();
  if (!paths.has_value()) {
    return false;
  }
  std::error_code directory_error;
  std::filesystem::create_directories(paths->directory, directory_error);
  if (directory_error) {
    return false;
  }

  const std::wstring temporary_file = paths->file + L".tmp";
  HANDLE file = ::CreateFileW(temporary_file.c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }
  const bool write_ok = WriteAll(file, bytes) && ::FlushFileBuffers(file);
  ::CloseHandle(file);
  if (!write_ok) {
    ::DeleteFileW(temporary_file.c_str());
    return false;
  }
  if (!::MoveFileExW(temporary_file.c_str(), paths->file.c_str(),
                     MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
    ::DeleteFileW(temporary_file.c_str());
    return false;
  }
  return true;
}

bool LocalStateFile::Delete() const {
  const std::optional<LocalStatePaths> paths = ResolvePaths();
  if (!paths.has_value()) {
    return false;
  }
  const bool file_deleted =
      ::DeleteFileW(paths->file.c_str()) != FALSE ||
      ::GetLastError() == ERROR_FILE_NOT_FOUND;
  const std::wstring temporary_file = paths->file + L".tmp";
  const bool temporary_deleted =
      ::DeleteFileW(temporary_file.c_str()) != FALSE ||
      ::GetLastError() == ERROR_FILE_NOT_FOUND;
  return file_deleted && temporary_deleted;
}
