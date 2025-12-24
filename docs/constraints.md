# Constraints

GPU usage depends on the app
- PRIME offload affects OpenGL and Vulkan rendering only.
- Languages like Python, JavaScript, or Go do not use the GPU unless the app uses GPU APIs.
- CPU-only or software-rendered apps will not benefit from PRIME offload.
- CUDA is separate from PRIME offload and is out of scope for this tool.

Per-process, not full desktop
- PRIME offload affects only the process launched with `nvidia-run`.
- The rest of the desktop remains on the integrated GPU.

Nouveau vs proprietary
- Nouveau provides limited features and may not support full PRIME offload.
- Proprietary NVIDIA drivers generally offer better compatibility and performance.
