#include <tonc.h>

int main(void) {
  REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;
  tte_init_se_default(0, BG_CBB(0) | BG_SBB(31));

  tte_write("Hello, world!\n");
  tte_write("Scaffold project is running.\n");
  tte_write("Press reset in emulator to restart.\n");

  while (1) {
    vid_vsync();
  }

  return 0;
}
