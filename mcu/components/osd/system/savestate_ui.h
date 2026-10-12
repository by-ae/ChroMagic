#pragma once

#include "osd_shared.h"

#include <stdbool.h>
#include <stdint.h>

enum {
    kSavestateOp_Save = 1,
    kSavestateOp_Load = 2,
};

typedef bool (*SavestateActionFn)(uint8_t Op);

void SavestateUI_RegisterAction(SavestateActionFn Action);

OSD_Result_t SavestateSave_Draw(void *arg);
OSD_Result_t SavestateSave_OnButton(const Button_t Button, const ButtonState_t State, void *arg);
OSD_Result_t SavestateSave_OnTransition(void *arg);

OSD_Result_t SavestateLoad_Draw(void *arg);
OSD_Result_t SavestateLoad_OnButton(const Button_t Button, const ButtonState_t State, void *arg);
OSD_Result_t SavestateLoad_OnTransition(void *arg);
