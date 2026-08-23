#ifndef RUNNER_LOCAL_STATE_FILE_H_
#define RUNNER_LOCAL_STATE_FILE_H_

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

struct LocalStatePaths {
  std::wstring root;
  std::wstring directory;
  std::wstring file;
};

enum class LocalStateReadStatus { kSuccess, kMissing, kError };

struct LocalStateReadResult {
  LocalStateReadStatus status;
  std::vector<std::uint8_t> bytes;
};

class LocalStateFile {
 public:
  explicit LocalStateFile(std::wstring application_identity,
                          std::wstring root_override = std::wstring());

  std::optional<LocalStatePaths> ResolvePaths() const;
  LocalStateReadResult Read() const;
  bool WriteAtomic(const std::vector<std::uint8_t>& bytes) const;
  bool Delete() const;

 private:
  std::wstring application_identity_;
  std::wstring root_override_;
};

#endif  // RUNNER_LOCAL_STATE_FILE_H_
