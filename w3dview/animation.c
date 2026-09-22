/*	Functions for handling W3D file animation data
	Copyright 2004 Jonathan Wilson

	This file is part of W3DView
	W3DView is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2, or (at your option) any later
	version. See the file COPYING for more details.
*/
#include "w3d.h"
/*
Function for updating the Hierarchy data to the next frame of animation
inputs: currently playing animation
outputs: none
*/
void UpdateAnimationFrame(int AnimationNumber)
{
	uint32 Count;
	W3dAnimChannelDefStruct CurrentChannel;
	W3dQuaternionStruct Temp;
	W3dHierarchyDefStruct CurAnimationHierarchy;
	W3dHierarchyDefStruct CurHierarchy;
	uint32 Offset;
	float32 Trans[16] = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
	if (stricmp(Animation[AnimationNumber].Header.HierarchyName,Hierarchy[0].Header.Name) == 0)
	{
		CurAnimationHierarchy = AnimationHierarchy[0];
		CurHierarchy = Hierarchy[0];
	}
	else
	{
		CurAnimationHierarchy = AnimationHierarchy[1];
		CurHierarchy = Hierarchy[1];
	}
	for (Count = 0;Count < Animation[AnimationNumber].W3dAnimChannelCount;Count++)
	{
		CurrentChannel = Animation[AnimationNumber].AnimationChannels[Count];
		if ((Frame >= CurrentChannel.Header.FirstFrame) && (Frame <= CurrentChannel.Header.LastFrame))
		{
			Offset = (Frame - CurrentChannel.Header.FirstFrame) * CurrentChannel.Header.VectorLen;
			switch(CurrentChannel.Header.Flags)
			{
			case ANIM_CHANNEL_X:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.X = (CurrentChannel.Data[Offset]);
				break;
			case ANIM_CHANNEL_Y:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.Y = (CurrentChannel.Data[Offset]);
				break;
			case ANIM_CHANNEL_Z:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.Z = (CurrentChannel.Data[Offset]);
				break;
			case ANIM_CHANNEL_Q:
				Temp.Q[0] = CurrentChannel.Data[Offset];
				Temp.Q[1] = CurrentChannel.Data[Offset+1];
				Temp.Q[2] = CurrentChannel.Data[Offset+2];
				Temp.Q[3] = CurrentChannel.Data[Offset+3];
				QuatToMatrix(Temp,&CurAnimationHierarchy.RotateMatrix[CurrentChannel.Header.Pivot*16]);
				break;
			}
		}
		else
		{
			switch(CurrentChannel.Header.Flags)
			{
			case ANIM_CHANNEL_X:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.X = 0;
				break;
			case ANIM_CHANNEL_Y:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.Y = 0;
				break;
			case ANIM_CHANNEL_Z:
				CurAnimationHierarchy.Pivots[CurrentChannel.Header.Pivot].Translation.Z = 0;
				break;
			case ANIM_CHANNEL_Q:
				memcpy(&CurAnimationHierarchy.RotateMatrix[CurrentChannel.Header.Pivot*16],&Trans,sizeof(float32)*16);
				break;
			}
		}
	}
	glutPostRedisplay();
	Frame++;
	if (Frame >= Animation[AnimationNumber].Header.NumFrames)
	{
		Frame = 0;
	}
	glutTimerFunc(1000/Animation[AnimationNumber].Header.FrameRate,UpdateAnimationFrame,AnimationNumber);
}
/* Function for handling Visibility Animation
Currently only handles frame 0 which is sufficiant for most models.
inputs: currently playing animation
outputs: none 
*/
void UpdateBitFrame(int AnimationNumber)
{
	uint32 Count;
	uint32 Visible;
	W3dHierarchyDefStruct CurHierarchy;
	W3dBitChannelDefStruct CurrentChannel;
	if (stricmp(Animation[AnimationNumber].Header.HierarchyName,Hierarchy[0].Header.Name) == 0)
	{
		CurHierarchy = AnimationHierarchy[0];
	}
	else
	{
		CurHierarchy = AnimationHierarchy[1];
	}
	for (Count = 0;Count < Animation[AnimationNumber].W3dBitChannelCount;Count++)
	{
		CurrentChannel = Animation[AnimationNumber].BitChannels[Count];
		if ((BitFrame >= CurrentChannel.Header.FirstFrame) && (BitFrame <= CurrentChannel.Header.LastFrame))
		{
			Visible = CurrentChannel.Data[0] & 0x01;
		}
		else
		{
			Visible = CurrentChannel.Header.DefaultVal;
		}
		CurHierarchy.Visible[CurrentChannel.Header.Pivot] = Visible;
	}
}
