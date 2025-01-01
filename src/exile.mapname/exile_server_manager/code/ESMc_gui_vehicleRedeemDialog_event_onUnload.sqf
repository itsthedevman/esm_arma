disableSerialization;

// Remove Background blur
//ExileClientPostProcessingBackgroundBlur ppEffectEnable false;
//ExileClientPostProcessingBackgroundBlur ppEffectCommit 1;

// Moon Light adjustment
ExileClientMoonLight setLightBrightness 0.75;

// Destroy model box
call ExileClient_gui_modelBox_destroy;

// Show our hud
true call ExileClient_gui_hud_toggle;

