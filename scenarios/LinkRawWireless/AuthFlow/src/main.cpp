#include <cstring>
#include <stdio.h>
#include <tonc.h>

#include "interrupt.h"
#include "C_LinkRawWireless.h"

// Required by C_LinkRawWireless.h
C_LinkRawWirelessHandle cLinkRawWireless = NULL;

namespace {
bool didStart = false;
bool adapterReady = false;

bool startPressed = false;
bool aPressed = false;
bool bPressed = false;

inline bool didPress(u16 key, bool& pressed) {
  u16 keys = ~REG_KEYS & KEY_ANY;
  if ((keys & key) && !pressed) {
    pressed = true;
    return true;
  }
  if (pressed && !(keys & key))
    pressed = false;
  return false;
}

inline void printLine(int line, const char* text) {
  tte_erase_rect(0, line * 8, 240, line * 8 + 8);
  char cursor[32];
  snprintf(cursor, sizeof(cursor), "#{P:0,%d}", line * 8);
  tte_write(cursor);
  tte_write(text);
}

void onVBlank() {}

void onSerial() {
  if (cLinkRawWireless != NULL)
    C_LinkRawWireless_onSerial(cLinkRawWireless);
}

void initAdapter() {
  if (cLinkRawWireless == NULL)
    cLinkRawWireless = C_LinkRawWireless_create();

  bool ok = C_LinkRawWireless_activate(cLinkRawWireless);
  if (ok)
    ok = C_LinkRawWireless_setup(cLinkRawWireless, 5, 4, 32, 0x003C0000);

  adapterReady = ok;
  printLine(8, ok ? "Adapter init: OK" : "Adapter init: FAIL");
}

void sendHello() {
  if (!adapterReady) {
    printLine(9, "A hello: FAIL (not ready)");
    return;
  }

  u32 payload[2] = {0, 0};
  const char* hello = "hello";
  std::memcpy(payload, hello, 5);

  bool ok = C_LinkRawWireless_sendData(cLinkRawWireless, payload, 2, 8);
  printLine(9, ok ? "A hello: OK" : "A hello: FAIL");
}

void sendBye() {
  if (!adapterReady) {
    printLine(10, "B bye: FAIL (not ready)");
    return;
  }

  bool ok = C_LinkRawWireless_bye(cLinkRawWireless);
  printLine(10, ok ? "B bye: OK" : "B bye: FAIL");
}
}  // namespace

int main() {
  interrupt_init();
  interrupt_add(INTR_VBLANK, onVBlank);
  interrupt_add(INTR_SERIAL, onSerial);

  REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;
  tte_init_se_default(0, BG_CBB(0) | BG_SBB(31));

  printLine(0, "AuthFlow - LinkRawWireless");
  printLine(2, "START: init adapter");
  printLine(3, "A: send HELLO");
  printLine(4, "B: send BYE");
  printLine(6, "Waiting for START...");

  while (true) {
    VBlankIntrWait();

    if (!didStart && didPress(KEY_START, startPressed)) {
      didStart = true;
      printLine(6, "Initializing...");
      initAdapter();
    }

    if (didStart && didPress(KEY_A, aPressed))
      sendHello();
    if (didStart && didPress(KEY_B, bPressed))
      sendBye();
  }

  return 0;
}
