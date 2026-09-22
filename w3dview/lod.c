/*	Functions for handling W3D file LOD data
	Copyright 2004 Jonathan Wilson

	This file is part of W3DView
	W3DView is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2, or (at your option) any later
	version. See the file COPYING for more details.
*/
#include "w3d.h"
/*
Function to turn a string of the form hierarchyname.meshname into a string of the form meshname
inputs: string
outputs: converted string
*/
void StripHierarchyName(char *Name)
{
	uint32 Count = 0;
	uint32 Position = 0;
	for (Count = 0;Count < strlen(Name);Count++)
	{
		if (Name[Count] == '.')
		{
			break;
		}
	}
	Position = Count+1;
	for (Count = Position;Count < strlen(Name);Count++)
	{
		Name[Count-Position] = Name[Count];
	}
	Name[Count-Position] = '\0';
}
/*
Function to display a W3D LOD Array
inputs: LOD to display
outputs: none
*/
void DisplayLOD(W3dLODArrayStruct LOD,uint32 HierarchyNo)
{
	float32 Transform[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	uint32 Count;
	uint32 Visible;
	uint32 Bone;
	char Name[W3D_NAME_LEN*2];
	for (Count=0;Count<LOD.Header.ModelCount;Count++)
	{
		Bone = LOD.SubObjects[Count].BoneIndex;
		Visible = CalculateBoneTransform(Bone,Transform,HierarchyNo);
		if (Visible == 1)
		{
			strcpy(Name,LOD.SubObjects[Count].Name);
			StripHierarchyName(Name);
			DisplayMesh(Name,Transform,HierarchyNo);
		}
	}
}
