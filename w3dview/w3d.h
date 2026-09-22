/*	Main include file for W3D Viewer
	Copyright 2004 Jonathan Wilson

	This file is part of W3DView
	W3DView is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2, or (at your option) any later
	version. See the file COPYING for more details.
*/
#ifdef _MSC_VER
#pragma warning (disable: 4100)
#endif
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <float.h>
#include <math.h>
#include <gl\glut.h>
#include <il\ilut.h>
#include "bittype.h"
#include "w3d_file.h"
#include "w3dstruct.h"
#include "animation.h"
#include "bone.h"
#include "defs.h"
#include "loader.h"
#include "lod.h"
#include "matrix.h"
#include "mesh.h"
