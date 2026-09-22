#include <windows.h>
#include <assert.h>
#define NONAMELESSUNION
#define byte BYTE
#include "ddraw.h"
byte* Decompress(DDSURFACEDESC2& ddsd, byte* s);

