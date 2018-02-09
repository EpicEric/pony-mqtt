#include <stdbool.h>
#include <stdint.h>
#include <sys/statvfs.h>

const uint32_t MB = (1024 * 1024);

bool pony_disk_space(uint32_t *total_space, uint32_t *used_space,
  uint32_t *free_space)
{
  struct statvfs st;
  if (statvfs("/", &st) != 0)
    return false;
  *total_space = (st.f_blocks * st.f_frsize) / MB;
  *free_space = (st.f_bfree * st.f_frsize) / MB;
  *used_space = *total_space - *free_space;
  return true;
}
