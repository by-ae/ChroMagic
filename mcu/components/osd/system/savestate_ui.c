#include "savestate_ui.h"

#include "osd_shared.h"

#include <stddef.h>

typedef struct SavestatePage {
    lv_obj_t *pStatus;
    uint8_t Op;
    const char *IdleText;
    const char *DoneText;
    bool Done;
} SavestatePage_t;

static SavestateActionFn Action;

static SavestatePage_t SavePage = {
    .Op = kSavestateOp_Save,
    .IdleText = "A: SAVE\nTIL POWER OFF",
    .DoneText = "SAVED\nTIL POWER OFF",
};

static SavestatePage_t LoadPage = {
    .Op = kSavestateOp_Load,
    .IdleText = "A: LOAD\nTIL POWER OFF",
    .DoneText = "LOADED\nTIL POWER OFF",
};

void SavestateUI_RegisterAction(SavestateActionFn NewAction)
{
    Action = NewAction;
}

static OSD_Result_t DrawPage(SavestatePage_t *pPage, void *arg)
{
    if ((pPage == NULL) || (arg == NULL))
    {
        return kOSD_Result_Err_NullDataPtr;
    }

    lv_obj_t *const pScreen = (lv_obj_t *const)arg;
    if (pPage->pStatus == NULL)
    {
        pPage->pStatus = lv_label_create(pScreen);
        lv_obj_add_style(pPage->pStatus, OSD_GetStyleTextWhite(), 0);
        lv_obj_align(pPage->pStatus, LV_ALIGN_TOP_LEFT, 77, 60);
    }

    lv_label_set_text_static(pPage->pStatus, pPage->Done ? pPage->DoneText : pPage->IdleText);
    lv_obj_move_foreground(pPage->pStatus);
    return kOSD_Result_Ok;
}

static OSD_Result_t OnButton(SavestatePage_t *pPage, const Button_t Button, const ButtonState_t State)
{
    if (pPage == NULL)
    {
        return kOSD_Result_Err_NullDataPtr;
    }

    if ((Button == kButton_A) && (State == kButtonState_Pressed) && (Action != NULL))
    {
        pPage->Done = Action(pPage->Op);
    }
    return kOSD_Result_Ok;
}

static OSD_Result_t OnTransition(SavestatePage_t *pPage)
{
    if (pPage == NULL)
    {
        return kOSD_Result_Err_NullDataPtr;
    }

    if (pPage->pStatus != NULL)
    {
        lv_obj_del(pPage->pStatus);
        pPage->pStatus = NULL;
    }
    pPage->Done = false;
    return kOSD_Result_Ok;
}

OSD_Result_t SavestateSave_Draw(void *arg)
{
    return DrawPage(&SavePage, arg);
}

OSD_Result_t SavestateSave_OnButton(const Button_t Button, const ButtonState_t State, void *arg)
{
    (void)arg;
    return OnButton(&SavePage, Button, State);
}

OSD_Result_t SavestateSave_OnTransition(void *arg)
{
    (void)arg;
    return OnTransition(&SavePage);
}

OSD_Result_t SavestateLoad_Draw(void *arg)
{
    return DrawPage(&LoadPage, arg);
}

OSD_Result_t SavestateLoad_OnButton(const Button_t Button, const ButtonState_t State, void *arg)
{
    (void)arg;
    return OnButton(&LoadPage, Button, State);
}

OSD_Result_t SavestateLoad_OnTransition(void *arg)
{
    (void)arg;
    return OnTransition(&LoadPage);
}
