/*	Main program code for W3DView
	Copyright 2004 Jonathan Wilson

	This file is part of W3DView
	W3DView is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2, or (at your option) any later
	version. See the file COPYING for more details.
*/
#include "w3d.h"
/*
Reshape Callback: Resizes the viewport when the window is resized
Inputs: new width, new height
Outputs: none
*/
void W3DViewReshape(int width, int height)
{
	glViewport(0, 0, width, height);
}
/*
Display Callback: Displays the model on the screen
Inputs: none
Outputs: none
*/
void W3DViewDisplay(void)
{
	GLfloat SceneLightAmbiant[] = {0.5,0.5,0.5,1.0};
	GLfloat LightDiffuse[] = {1.0,1.0,1.0,1.0};
	GLfloat LightSpecular[] = {1.0,1.0,1.0,1.0};
	GLfloat LightAmbiant[] = {1.0,1.0,1.0,1.0};
	GLfloat LightPosition[] = {-0.810051,1.766175,-0.524711,1.0};
	float32 Transform[16] = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
	float32 Project[16] = {2.615055,0,0,0,0,2.414213,0,0,0,0,-1,-1,0,0,-1,0};
	uint32 HierarchyNo;
	RotateMat[Rotate][14] = -Zoom;
	RotateMat[Rotate][13] = -Tilt;
	RotateMat[Rotate][12] = -Pan;
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glLoadMatrixf(Project);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glLoadMatrixf(RotateMat[Rotate]);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT,SceneLightAmbiant);
	glLightfv(GL_LIGHT0,GL_AMBIENT,LightAmbiant);
	glLightfv(GL_LIGHT0,GL_DIFFUSE,LightDiffuse);
	glLightfv(GL_LIGHT0,GL_SPECULAR,LightSpecular);
	glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, 1.0);
	glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, 0.0);
	glLightfv(GL_LIGHT0,GL_POSITION,LightPosition);
	glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 180.0);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	if (ChunkCount == 1)
	{
		DisplayMesh(Mesh[0].Header.MeshName,Transform,0);
	}
	else
	{
		if (stricmp(HLOD[0].Header.HierarchyName,AnimationHierarchy[0].Header.Name) == 0)
		{
			HierarchyNo = 0;
		}
		else
		{
			HierarchyNo = 1;
		}
		DisplayLOD(HLOD[0].LODs[HLOD[0].Header.LodCount-1],HierarchyNo);
	}
	glFlush();
	glutSwapBuffers();
}
/*
Special Keys Callback
Inputs: Key, X, Y
Outputs: None
*/
void W3DViewSpecial(int key,int x, int y)
{
	switch (key) 
	{
	case GLUT_KEY_LEFT:
		Pan += 1.0;
		break;
	case GLUT_KEY_RIGHT: 
		Pan -= 1.0;
		break;
	case GLUT_KEY_UP:
		Tilt -= 1.0;
		break;
	case GLUT_KEY_DOWN:
		Tilt += 1.0;
		break;
	}
	glutPostRedisplay();
}
/*
Function to handle rotation for a wheel
Inputs: Hierarchy Number to use, Wheel Perimiter Bone Number, Wheel Center Bone Number
Outputs: None
*/
void DoWheel(int HierarchyNo,uint32 PBone,uint32 CBone)
{
	float32 Rotate[16] = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
	float32 Temp[16] = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};
	float32 Radius = 0;
	float32 AnglePerMeter = 0;
	float32 Angle = 0;
	AnimationHierarchy[HierarchyNo].Pivots[PBone].Translation.Z = -Suspension;
	Radius = fabs(Hierarchy[HierarchyNo].Pivots[CBone].Translation.Z);
	AnglePerMeter = 360*(1/(6.28*Radius));
	Angle = AnglePerMeter * Speed/1000;
	Rotate[0] = cos(Angle);
	Rotate[1] = -sin(Angle);
	Rotate[4] = sin(Angle);
	Rotate[5] = cos(Angle);
	MatrixMultiply(&AnimationHierarchy[HierarchyNo].RotateMatrix[CBone*16],Rotate,Temp);
	memcpy(&AnimationHierarchy[HierarchyNo].RotateMatrix[CBone*16],&Temp,(sizeof(float32)*16));
}
/*
Function to move a vechicle
Inputs: Hierarchy Number to use
Outputs: none
*/
void MoveVehicle(int HierarchyNo)
{
	uint32 Count,Count2;
	char *TempBoneName = NULL;
	AnimationHierarchy[HierarchyNo].Pivots[0].Translation.X += Speed/100;
	glutTimerFunc(10,MoveVehicle,HierarchyNo);
	for (Count = 0;Count < AnimationHierarchy[HierarchyNo].Header.NumPivots;Count++)
	{
			if ((strnicmp(AnimationHierarchy[HierarchyNo].Pivots[Count].Name,"WHEELP",6) == 0))
			{
				TempBoneName = malloc(strlen(AnimationHierarchy[HierarchyNo].Pivots[Count].Name)+1);
				strcpy(TempBoneName,AnimationHierarchy[HierarchyNo].Pivots[Count].Name);
				TempBoneName[5] = 'C';
				for (Count2 = 0;Count2 < AnimationHierarchy[HierarchyNo].Header.NumPivots;Count2++)
				{
					if ((stricmp(AnimationHierarchy[HierarchyNo].Pivots[Count2].Name,TempBoneName) == 0))
					{
						DoWheel(HierarchyNo,Count,Count2);
					}
				}
				free(TempBoneName);
			}
	}
	glutPostRedisplay();
}
/*
Keyboard Callback
Inputs: Key, X, Y
Outputs: None
*/
void W3DViewKeyboard(unsigned char key,int x, int y)
{
	uint32 HierarchyNo = 0;
	switch(key)
	{
	case 'z':
		Zoom -= 1.0;
		if (Zoom < 1) Zoom = 1;
		break;
	case 'Z':
		Zoom += 1.0;
		break;
	case '1':
		Rotate = 0;
		break;
	case '2':
		Rotate = 1;
		break;
	case '3':
		Rotate = 2;
		break;
	case '4':
		Rotate = 3;
		break;
	case '5':
		Rotate = 4;
		break;
	case '6':
		Rotate = 5;
		break;
	case 'v':
		if (IsVehicle == 1)
		{
			IsVehicle = 0;
			if (stricmp(HLOD[0].Header.HierarchyName,AnimationHierarchy[0].Header.Name) == 0)
			{
				HierarchyNo = 0;
			}
			else
			{
				HierarchyNo = 1;
			}
			MoveVehicle(HierarchyNo);
		}
	case 'S':
		Speed += 1;
		break;
	case 's':
		Speed -= 1;
		if (Speed < 1) Speed = 1;
		break;
	}
	glutPostRedisplay();
}
/*
Return the U value for the given Mapper Arguments string
Inputs: Mapper Arguments string
Outputs: U value
*/
float32 GetU(char *Arguments)
{
	float32 Value;
	char *Temp2;
	char *Temp;
	Temp2 = malloc(strlen(Arguments)+1);
	strcpy(Temp2,Arguments);
	Temp = strstr(Temp2,"UPerSec=");
	if (Temp == NULL)
	{
		free(Temp2);
		return 0;
	}
	Temp = strtok(Temp2,"\r");
	Temp += 8;
	Value = atof(Temp);
	free(Temp2);
	return Value;
}
/*
Return the V value for the given Mapper Arguments string
Inputs: Mapper Arguments string
Outputs: V value
*/
float32 GetV(char *Arguments)
{
	float32 Value;
	char *Temp2;
	char *Temp;
	Temp2 = malloc(strlen(Arguments)+1);
	strcpy(Temp2,Arguments);
	Temp = strstr(Temp2,"VPerSec=");
	if (Temp == NULL)
	{
		free(Temp2);
		return 0;
	}
	Temp = strtok(Temp2,"\r");
	Temp += 8;
	Value = atof(Temp);
	free(Temp2);
	return Value;
}
/*
Timer for U Per Second handling
Inputs: Value to identify the material to update
Outputs: None
*/
void UFunc(int UValue)
{
	uint32 Count = UValue / 0x1000;
	uint32 Count2 = UValue & 0xFFF;
	Mesh[Count].Materials[Count2].CurrentU += -((float)(Mesh[Count].Materials[Count2].UPerSec / 100));
	if (Mesh[Count].Materials[Count2].CurrentU > 1)
	{
		Mesh[Count].Materials[Count2].CurrentU = 0;
	} 
	else if (Mesh[Count].Materials[Count2].CurrentU < -1)
	{
		Mesh[Count].Materials[Count2].CurrentU = 0;
	}
	glutTimerFunc(10,UFunc,Count*0x1000+Count2);
	glutPostRedisplay();
}
/*
Timer for V Per Second handling
Inputs: Value to identify the material to update
Outputs: None
*/
void VFunc(int VValue)
{
	uint32 Count = VValue / 0x1000;
	uint32 Count2 = VValue & 0xFFF;
	Mesh[Count].Materials[Count2].CurrentV += ((float)(Mesh[Count].Materials[Count2].VPerSec / 100));
	if (Mesh[Count].Materials[Count2].CurrentV > 1)
	{
		Mesh[Count].Materials[Count2].CurrentV = 0;
	} 
	else if (Mesh[Count].Materials[Count2].CurrentV < -1)
	{
		Mesh[Count].Materials[Count2].CurrentV = 0;
	}
	glutTimerFunc(10,VFunc,Count*0x1000+Count2);
	glutPostRedisplay();
}
/*
main program
inputs: command line arguments
outputs: exit code
*/
int main(int argc, char* argv[])
{
	uint32 Count,Count2;
	uint32 Loaded = 0;
	uint32 HierarchyNo = 0;
	char FileName[MAX_PATH];
	Initdefs();
	printf("Enter W3D Filenames To Load, NULL to end\n");
	while (stricmp(FileName,"NULL") != 0)
	{
		scanf("%s",FileName);
		if (stricmp(FileName,"NULL") != 0)
		{
			Loaded = 1;
			LoadW3dFromDisk(FileName);
		}
	}
	if (Loaded == 0)
	{
		printf("Nothing To Display\n");
		exit(0);
	}
	printf("Enter Initial Zoom Value\n");
	scanf("%f",&Zoom);
	if (ChunkCount != 1)
	{
		if (stricmp(HLOD[0].Header.HierarchyName,AnimationHierarchy[0].Header.Name) == 0)
		{
			HierarchyNo = 0;
		}
		else
		{
			HierarchyNo = 1;
		}
		for (Count = 0;Count < AnimationHierarchy[HierarchyNo].Header.NumPivots;Count++)
		{
			if ((strnicmp(AnimationHierarchy[HierarchyNo].Pivots[Count].Name,"WHEELP",6) == 0) && (IsVehicle == 0))
			{
				IsVehicle = 1;
				printf("Enter Speed Value in Scale Meters per second\n");
				scanf("%f",&Speed);
				printf("Enter Suspension Travel Value in Scale Meters\n");
				scanf("%f",&Suspension);
			}
		}
	}
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_ALPHA);
	glutInitWindowSize(500, 500);
	glutCreateWindow("W3D Viewer");
	glutReshapeFunc(W3DViewReshape);
	glutDisplayFunc(W3DViewDisplay);
	glutIdleFunc(NULL);
	glutKeyboardFunc(W3DViewKeyboard);
	glutSpecialFunc(W3DViewSpecial);
	glShadeModel(GL_SMOOTH);
	glClearColor(0.5,0.5,0.5,1.0);
	glViewport(0, 0, 500, 500);
	for (Count = 0;Count < MeshCount;Count++)
	{
		for (Count2 = 0;Count2 < Mesh[Count].MaterialInfo.VertexMaterialCount;Count2++)
		{
			if ((Mesh[Count].Materials[Count2].MapperArgs0 != NULL) && ((Mesh[Count].Materials[Count2].VertexMaterialInfo.Attributes & W3DVERTMAT_STAGE0_MAPPING_LINEAR_OFFSET) != 0))
			{
				Mesh[Count].Materials[Count2].CurrentU = 0;
				Mesh[Count].Materials[Count2].CurrentV = 0;
				Mesh[Count].Materials[Count2].UPerSec = GetU(Mesh[Count].Materials[Count2].MapperArgs0);
				Mesh[Count].Materials[Count2].VPerSec = GetV(Mesh[Count].Materials[Count2].MapperArgs0);
				if (Mesh[Count].Materials[Count2].UPerSec != 0)
				{
					UFunc(Count*0x1000+Count2);
				}
				if (Mesh[Count].Materials[Count2].VPerSec != 0)
				{
					VFunc(Count*0x1000+Count2);
				}
			}
		}
	}
	if (AnimationCount != 0)
	{
		UpdateAnimationFrame(0);
	}
	if (AnimationCount != 0)
	{
		UpdateBitFrame(0);
	}
	ilInit();
	ilutRenderer(ILUT_OPENGL);
	ilutEnable(ILUT_OPENGL_CONV);
	glEnable(GL_BLEND);
	glutMainLoop();
	return 0;
}
