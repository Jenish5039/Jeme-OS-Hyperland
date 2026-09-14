-- Hybrid GPU Mode: Intel iGPU primary for desktop/compositor, NVIDIA dGPU secondary
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")
