#pragma once

#include <stdint.h>

struct font {
  const char *const name;
  uint32_t size;
  uint32_t color;
};

struct config {
  struct {
    uint32_t use_duration;
    uint32_t break_duration;
  } functionality;
  struct {
    uint32_t background;
    struct font message_font;
    const char *const message;
    struct font timer_font;
    const char *const icon_path;
    struct {
      struct {
        float fade_in;
        float fade_out;
      } window;
      struct {
        float fade_in;
      } message;
      struct {
        float fade_in;
        float fade_in_delay;
      } timer;
    } animations;
  } appearance;
};
