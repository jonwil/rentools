/*	
	Maxscript Extentions for 3DS Max W3D Export Plugin
	Copyright 2010 Jonathan Wilson

	This file is part of the Maxscript Extentions for 3DS Max W3D Export Plugin
	The Maxscript Extentions for 3DS Max W3D Export Plugin is free software; you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3, or (at your option) any later
	version. See the file COPYING for more details.
*/
#pragma warning (disable: 4800 4100 4238 4512 4245 4239 4201)
#include "max.h"
#include "maxscrpt.h"
#include "numbers.h"
#include "maxmats.h"
#include "colorval.h"
#include "strings.h"
#include "modstack.h"
CoreExport void *	(__cdecl *MAX_malloc)(size_t);
#define malloc(size)	(*MAX_malloc)(size)
CoreExport void *__cdecl MAX_new_array(size_t size);
CoreExport void __cdecl MAX_delete_array(void* mem);

Class_ID GameMtlID = Class_ID(0x29397211,0x28C016C2);
class GameMtlDlg;
class GameMtl : public Mtl {
public:
	int SurfaceType;
	int SortLevel;
	Interval Time;
	GameMtlDlg *MtlDlg;
	int RollupFlags;
	int RollupScrollPos;
	int f64[4];
	ReferenceTarget *ReferenceUnk;
	IParamBlock *General;
	IParamBlock *Materials[4];
	Texmap *Texmaps[4][2];
	char *MapperArgs[4][2];
	int MapperArgLengths[4][2];
	int MapperTypes[4][2];
	Texmap *StdTexmap;
	int f110;
	int IsPS2;
	int f118;
	virtual BaseInterface* GetInterface(Interface_ID id);
	virtual void GetClassName(TSTR& s);
	virtual Class_ID ClassID();
	virtual ~GameMtl();
	virtual void DeleteThis();
	virtual void* GetInterface(ULONG id);
	virtual	int NumSubs();
	virtual	Animatable* SubAnim(int i);
	virtual TSTR SubAnimName(int i);
	virtual IOResult Save(ISave *isave);
	virtual IOResult Load(ILoad *iload);
	virtual	int NumRefs();
	virtual RefTargetHandle GetReference(int i);
	virtual void SetReference(int i, RefTargetHandle rtarg);
	virtual RefResult NotifyRefChanged(Interval changeInt, RefTargetHandle hTarget, PartID& partID,  RefMessage message);
	virtual RefTargetHandle Clone(RemapDir &remap = NoRemap());
	virtual ULONG Requirements(int subMtlNum);
	virtual	void Update(TimeValue t, Interval& valid);
	virtual void Reset();
	virtual Interval Validity(TimeValue t);
	virtual ParamDlg* CreateParamDlg(HWND hwMtlEdit, IMtlParams *imp);
	virtual Color GetAmbient(int mtlNum=0, BOOL backFace=FALSE);
	virtual Color GetDiffuse(int mtlNum=0, BOOL backFace=FALSE);	    
	virtual Color GetSpecular(int mtlNum=0, BOOL backFace=FALSE);
	virtual float GetShininess(int mtlNum=0, BOOL backFace=FALSE);
	virtual	float GetShinStr(int mtlNum=0, BOOL backFace=FALSE);		
	virtual float GetXParency(int mtlNum=0, BOOL backFace=FALSE);
	virtual void SetAmbient(Color c, TimeValue t);
	virtual void SetDiffuse(Color c, TimeValue t);
	virtual void SetSpecular(Color c, TimeValue t);
	virtual void SetShininess(float v, TimeValue t);
	virtual void Shade(ShadeContext& sc);
	virtual float EvalDisplacement(ShadeContext& sc);
	virtual int NumSubTexmaps();
	virtual Texmap* GetSubTexmap(int i);
	virtual void SetSubTexmap(int i, Texmap *m);
	void MaterialChanged()
	{
		Interval i(0x80000000,0x7FFFFFFF);
		NotifyDependents(i,0x800037FF,80,-16,true);
	}
	void SetPassCount(int pass)
	{
		General->SetValue(0,0,pass);
	}
	int PassCount()
	{
		int pass;
		Interval i(0x80000000,0x7FFFFFFF);
		General->GetValue(0,0,pass,i);
		return pass;
	}
	void DoSetAmbient(int pass,int time,Color newval)
	{
		Materials[pass]->SetValue(0,time,newval);
	}
	Color DoGetAmbient(int pass,int time)
	{
		Color c;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(0,time,c,i);
		return c;
	}
	void DoSetDiffuse(int pass,int time,Color newval)
	{
		Materials[pass]->SetValue(1,time,newval);
	}
	Color DoGetDiffuse(int pass,int time)
	{
		Color c;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(1,time,c,i);
		return c;
	}
	void DoSetSpecular(int pass,int time,Color newval)
	{
		Materials[pass]->SetValue(2,time,newval);
	}
	Color DoGetSpecular(int pass,int time)
	{
		Color c;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(2,time,c,i);
		return c;
	}
	void DoSetEmissive(int pass,int time,Color newval)
	{
		Materials[pass]->SetValue(3,time,newval);
	}
	Color DoGetEmissive(int pass,int time)
	{
		Color c;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(3,time,c,i);
		return c;
	}
	void DoSetShininess(int pass,float newval)
	{
		Materials[pass]->SetValue(4,0,newval);
	}
	float DoGetShininess(int pass)
	{
		float f;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(4,0,f,i);
		return f;
	}
	void DoSetOpacity(int pass,float newval)
	{
		Materials[pass]->SetValue(5,0,newval);
	}
	float DoGetOpacity(int pass)
	{
		float f;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(5,0,f,i);
		return f;
	}
	void DoSetTranslucency(int pass,float newval)
	{
		Materials[pass]->SetValue(6,0,newval);
	}
	float DoGetTranslucency(int pass)
	{
		float f;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(6,0,f,i);
		return f;
	}
	void DoSetSpecularToDiffuse(int pass,bool newval)
	{
		Materials[pass]->SetValue(7,0,newval);
	}
	bool GetSpecularToDiffuse(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(7,0,value,i);
		return value;
	}
	void DoSetMapType(int pass,int stage,int newval)
	{
		if (stage)
		{
			if (stage == 1)
			{
				Materials[pass]->SetValue(53,0,newval);
			}
		}
		else
		{
			Materials[pass]->SetValue(8,0,newval);
		}
	}
	int DoGetMapType(int pass,int stage)
	{
		int value = -1;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			if (stage == 1)
			{
				Materials[pass]->GetValue(53,0,value,i);
			}
		}
		else
		{
			Materials[pass]->GetValue(8,0,value,i);
		}
		return value;
	}
	void SetDepthCmp(int pass,int newval)
	{
		Materials[pass]->SetValue(11,0,newval);
	}
	int GetDepthCmp(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(11,0,value,i);
		return value;
	}
	void SetWriteZBuffer(int pass,bool newval)
	{
		Materials[pass]->SetValue(12,0,newval);
	}
	bool GetWriteZBuffer(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(12,0,value,i);
		return value;
	}
	void SetDestBlend(int pass,int newval)
	{
		Materials[pass]->SetValue(14,0,newval);
	}
	int GetDestBlend(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(14,0,value,i);
		return value;
	}
	void SetPriGradient(int pass,int newval)
	{
		Materials[pass]->SetValue(16,0,newval);
	}
	int GetPriGradient(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(16,0,value,i);
		return value;
	}
	void SetSecGradient(int pass,int newval)
	{
		Materials[pass]->SetValue(17,0,newval);
	}
	int GetSecGradient(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(17,0,value,i);
		return value;
	}
	void SetSrcBlend(int pass,int newval)
	{
		Materials[pass]->SetValue(18,0,newval);
	}
	int GetSrcBlend(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(18,0,value,i);
		return value;
	}
	void SetDetailColor(int pass,int newval)
	{
		Materials[pass]->SetValue(19,0,newval);
	}
	int GetDetailColor(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(19,0,value,i);
		return value;
	}
	void SetDetailAlpha(int pass,int newval)
	{
		Materials[pass]->SetValue(20,0,newval);
	}
	int GetDetailAlpha(int pass)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		Materials[pass]->GetValue(20,0,value,i);
		return value;
	}
	void SetTextureStageEnabled(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(32,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(21,0,newval);
		}
	}
	bool GetTextureStageEnabled(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(32,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(21,0,value,i);
		}
		return value;
	}
	void SetPublish(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(33,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(22,0,newval);
		}
	}
	bool GetPublish(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(33,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(22,0,value,i);
		}
		return value;
	}
	void SetClampU(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(36,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(25,0,newval);
		}
	}
	bool GetClampU(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(36,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(25,0,value,i);
		}
		return value;
	}
	void SetClampV(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(37,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(26,0,newval);
		}
	}
	bool GetClampV(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(37,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(26,0,value,i);
		}
		return value;
	}
	void SetPassHint(int pass,int stage,int newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(38,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(27,0,newval);
		}
	}
	int GetPassHint(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(38,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(27,0,value,i);
		}
		return value;
	}
	void SetFrameRate(int pass,int stage,float newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(40,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(29,0,newval);
		}
	}
	float GetFrameRate(int pass,int stage)
	{
		float value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(40,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(29,0,value,i);
		}
		return value;
	}
	void SetFrames(int pass,int stage,int newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(41,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(30,0,newval);
		}
	}
	float GetFrames(int pass,int stage)
	{
		float value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(41,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(30,0,value,i);
		}
		return value;
	}
	void SetAnimType(int pass,int stage,int newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(42,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(31,0,newval);
		}
	}
	int GetAnimType(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(42,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(31,0,value,i);
		}
		return value;
	}
	void SetAlphaBitmap(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(44,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(43,0,newval);
		}
	}
	bool GetAlphaBitmap(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(44,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(43,0,value,i);
		}
		return value;
	}
	void DoSetUV(int pass,int stage,int newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(52,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(51,0,newval);
		}
		Texmap *tex = Texmaps[pass][stage];
		if (tex)
		{
			UVGen *gen = tex->GetTheUVGen();
			if (gen)
			{
				gen->SetMapChannel(newval);
			}
			Interval i(0x80000000,0x7FFFFFFF);
			NotifyDependents(i,0x800037FF,80,-16,true);
		}
	}
	int GetUV(int pass,int stage)
	{
		int val;
		if (stage)
		{
			Interval i(0x80000000,0x7FFFFFFF);
			Materials[pass]->GetValue(52,0,val,i);
		}
		else
		{
			Interval i(0x80000000,0x7FFFFFFF);
			Materials[pass]->GetValue(51,0,val,i);
		}
		return val;
	}
	void SetNoLOD(int pass,int stage,bool newval)
	{
		if (stage)
		{
			Materials[pass]->SetValue(55,0,newval);
		}
		else
		{
			Materials[pass]->SetValue(54,0,newval);
		}
	}
	bool GetNoLOD(int pass,int stage)
	{
		int value;
		Interval i(0x80000000,0x7FFFFFFF);
		if (stage)
		{
			Materials[pass]->GetValue(55,0,value,i);
		}
		else
		{
			Materials[pass]->GetValue(54,0,value,i);
		}
		return value;
	}
	void Display(int pass,int stage,bool display)
	{
		int val = 0;
		for (IParamBlock **i = Materials;;i++)
		{
			Interval in(0x80000000,0x7FFFFFFF);
			int v;
			General->GetValue(0,0,v,in);
			if (val >= v)
			{
				break;
			}
			(*i)->SetValue(28,0,0);
			(*i)->SetValue(39,0,0);
			val++;
		}
		Texmap *tex = Texmaps[pass][stage];
		if (display == 1)
		{
			if (stage)
			{
				Materials[pass]->SetValue(39,0,1);
			}
			else
			{
				Materials[pass]->SetValue(28,0,1);
			}
			if (tex)
			{
				SetMtlFlag(0x100000,true);
				SetActiveTexmap(tex);
				tex->ActivateTexDisplay(true);
				GetCOREInterface()->ActivateTexture(tex,this,-1);
			}
		}
		else
		{
			if (tex)
			{
				tex->ActivateTexDisplay(false);
				GetCOREInterface()->DeActivateTexture(tex,this,-1);
				SetMtlFlag(0x100000,false);
				SetActiveTexmap(0);
			}
		}
		Interval in(0x80000000,0x7FFFFFFF);
		NotifyDependents(in,0x800037FF,80,-16,1);
		if (IsMultiMtl())
		{
			MaxMsgBox(0,"Unsupported feature","error",MB_OK);
		}
	}
};

#define EXPORT_BONE 1
#define EXPORT_GEOMETRY 2

#define MESH_HIDE 1
#define MESH_2SIDE 2
#define MESH_SHADOW 4
#define MESH_VALPHA 8
#define MESH_ZNORMAL 0x10
#define MESH_SHATTER 0x20
#define MESH_NPATCH 0x40
#define MESH_KEEPNORMAL 0x80

#define COLLIDE_PHYSICAL 1
#define COLLIDE_PROJECTILE 2
#define COLLIDE_VIS 4
#define COLLIDE_CAMERA 8
#define COLLIDE_VEHICLE 0x10

#define TYPE_CAMPAR 1
#define TYPE_NORMAL 2
#define TYPE_OBBOX 3
#define TYPE_AABOX 4
#define TYPE_CAMORI 5
#define TYPE_NULL 6
#define TYPE_DAZZLE 7
#define TYPE_AGGREGATE 8

struct W3DAppData1Struct {
	int exportflags;
	int type;
	int meshflags;
	int collideflags;
	int sorting;
	int unk14;
	int unk18;
	int unk1C;
};

bool IsTriObj(INode *node)
{
	Object *obj = node->EvalWorldState(0,true).obj;
	Class_ID cid(TRIOBJ_CLASS_ID,0);
	return obj && obj->CanConvertToType(cid);
}

struct DazzleAppData {
	int f0;
	int f1;
	int f2;
	int f3;
	char name[128];
	DazzleAppData()
	{
		f0 = 0;
		f1 = 0;
		f2 = 0;
		f3 = 0;
		memset(name,0,sizeof(name));
		strcpy(name,"DEFAULT");
	}
};

DazzleAppData *GetDazzleAppData(INode *node)
{
	Class_ID cid(0x3C362C97,0x5FC73AB0);
	AppDataChunk *ad = node->GetAppDataChunk(cid,4128,3);
	if (ad)
	{
		return (DazzleAppData *)ad->data;
	}
	else
	{
		DazzleAppData *d = new DazzleAppData();
		node->AddAppDataChunk(cid,4128,3,144,d);
		return d;
	}
}

void W3DAppData1StructInit(W3DAppData1Struct *str)
{
	str->exportflags = 0;
	str->type = 0;
	str->meshflags = 0;
	str->collideflags = 0;
	str->sorting = 0;
	str->unk14 = 0;
	str->unk18 = 0;
	str->unk1C = 0;
	str->exportflags |= 0x10000;
}

W3DAppData1Struct *GetW3DAppData1Struct(INode *node)
{
	Class_ID cid(0x3C362C97,0x5FC73AB0);
	AppDataChunk *data = node->GetAppDataChunk(cid,UTILITY_CLASS_ID,2);
	if (data)
	{
		W3DAppData1Struct *str = (W3DAppData1Struct *)data->data;
		if (!(str->exportflags & 0xFFFF0000))
		{
			int cf = str->collideflags;
			if (cf & COLLIDE_PHYSICAL)
			{
				str->collideflags = cf | COLLIDE_CAMERA;
			}
			else
			{
				str->collideflags = cf & ~COLLIDE_CAMERA;
			}
			str->exportflags &= 0x0000FFFF;
			str->exportflags |= 0x10000;
		}
		return str;
	}
	else
	{
		W3DAppData1Struct *str = (W3DAppData1Struct *)MAX_malloc(sizeof(W3DAppData1Struct));
		W3DAppData1StructInit(str);
		if (IsTriObj(node))
		{
			str->exportflags |= 3;
		}
		node->AddAppDataChunk(cid,UTILITY_CLASS_ID,2,sizeof(W3DAppData1Struct),str);
		return str;
	}
}
#include "definsfn.h"
def_visible_primitive(wwSetType,"wwSetType");
Value *wwSetType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetType,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Type",arg_list[1],class_tag(Integer));
	}
	INode *node = arg_list[0]->to_node();
	int type = arg_list[1]->to_int();
	GetW3DAppData1Struct(node)->type = type;
	return &ok;
}

def_visible_primitive(wwSetDazzle,"wwSetDazzle");
Value *wwSetDazzle_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDazzle,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_string(arg_list[1]))
	{
		throw TypeError("Type",arg_list[1],class_tag(String));
	}
	INode *node = arg_list[0]->to_node();
	char *type = arg_list[1]->to_string();
	strncpy(GetDazzleAppData(node)->name,type,127);
	return &ok;
}
#define W3D_BOX_ATTRIBUTE_ORIENTED							0x00000001
#define W3D_BOX_ATTRIBUTE_ALIGNED							0x00000002
#define W3D_BOX_ATTRIBUTE_COLLISION_TYPE_MASK			0x00000FF0
#define W3D_BOX_ATTRIBUTE_COLLISION_TYPE_SHIFT						4
#define W3D_BOX_ATTRIBTUE_COLLISION_TYPE_PHYSICAL		0x00000010
#define W3D_BOX_ATTRIBTUE_COLLISION_TYPE_PROJECTILE	0x00000020
#define W3D_BOX_ATTRIBTUE_COLLISION_TYPE_VIS				0x00000040
#define W3D_BOX_ATTRIBTUE_COLLISION_TYPE_CAMERA			0x00000080
#define W3D_BOX_ATTRIBTUE_COLLISION_TYPE_VEHICLE		0x00000100
#define W3D_MESH_FLAG_NONE										0x00000000
#define W3D_MESH_FLAG_COLLISION_TYPE_MASK					0x00000FF0
#define W3D_MESH_FLAG_COLLISION_TYPE_SHIFT							4
#define W3D_MESH_FLAG_COLLISION_TYPE_PHYSICAL			0x00000010
#define W3D_MESH_FLAG_COLLISION_TYPE_PROJECTILE			0x00000020
#define W3D_MESH_FLAG_COLLISION_TYPE_VIS					0x00000040
#define W3D_MESH_FLAG_COLLISION_TYPE_CAMERA				0x00000080
#define W3D_MESH_FLAG_COLLISION_TYPE_VEHICLE				0x00000100
#define W3D_MESH_FLAG_COLLISION_TYPE_USER1				0x00000200
#define W3D_MESH_FLAG_COLLISION_TYPE_USER2				0x00000400
#define W3D_MESH_FLAG_HIDDEN									0x00001000
#define W3D_MESH_FLAG_TWO_SIDED								0x00002000
#define OBSOLETE_W3D_MESH_FLAG_LIGHTMAPPED				0x00004000
#define W3D_MESH_FLAG_CAST_SHADOW							0x00008000
#define W3D_MESH_FLAG_GEOMETRY_TYPE_MASK					0x00FF0000
#define W3D_MESH_FLAG_GEOMETRY_TYPE_NORMAL				0x00000000
#define W3D_MESH_FLAG_GEOMETRY_TYPE_CAMERA_ALIGNED		0x00010000
#define W3D_MESH_FLAG_GEOMETRY_TYPE_SKIN					0x00020000
#define W3D_MESH_FLAG_GEOMETRY_TYPE_CAMERA_ORIENTED	0x00060000
#define W3D_MESH_FLAG_PRELIT_MASK							0x0F000000
#define W3D_MESH_FLAG_PRELIT_UNLIT							0x01000000
#define W3D_MESH_FLAG_PRELIT_VERTEX							0x02000000
#define W3D_MESH_FLAG_PRELIT_LIGHTMAP_MULTI_PASS		0x04000000
#define W3D_MESH_FLAG_PRELIT_LIGHTMAP_MULTI_TEXTURE	0x08000000
#define W3D_MESH_FLAG_SHATTERABLE							0x10000000
#define W3D_MESH_FLAG_NPATCHABLE								0x20000000
def_visible_primitive(wwSetFlags,"wwSetFlags");
Value *wwSetFlags_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetFlags,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Flags",arg_list[1],class_tag(Integer));
	}
	INode *node = arg_list[0]->to_node();
	int flags = arg_list[1]->to_int();
	W3DAppData1Struct *str = GetW3DAppData1Struct(node);
	if (flags & W3D_MESH_FLAG_HIDDEN)
	{
		str->meshflags |= MESH_HIDE;
	}
	else
	{
		str->meshflags &= ~MESH_HIDE;
	}
	if (flags & W3D_MESH_FLAG_TWO_SIDED)
	{
		str->meshflags |= MESH_2SIDE;
	}
	else
	{
		str->meshflags &= ~MESH_2SIDE;
	}

	if (flags & W3D_MESH_FLAG_CAST_SHADOW)
	{
		str->meshflags |= MESH_SHADOW;
	}
	else
	{
		str->meshflags &= ~MESH_SHADOW;
	}

	if (flags & W3D_MESH_FLAG_SHATTERABLE)
	{
		str->meshflags |= MESH_SHATTER;
	}
	else
	{
		str->meshflags &= ~MESH_SHATTER;
	}

	if (flags & W3D_MESH_FLAG_NPATCHABLE)
	{
		str->meshflags |= MESH_NPATCH;
	}
	else
	{
		str->meshflags &= ~MESH_NPATCH;
	}

	int gt = flags & W3D_MESH_FLAG_GEOMETRY_TYPE_MASK;
	switch (gt)
	{
	case W3D_MESH_FLAG_GEOMETRY_TYPE_NORMAL:
		str->type = TYPE_NORMAL;
		break;
	case W3D_MESH_FLAG_GEOMETRY_TYPE_CAMERA_ALIGNED:
		str->type = TYPE_CAMPAR;
		break;
	case W3D_MESH_FLAG_GEOMETRY_TYPE_CAMERA_ORIENTED:
		str->type = TYPE_CAMORI;
		break;
	}

	if (flags & W3D_BOX_ATTRIBUTE_ORIENTED)
	{
		str->type = TYPE_OBBOX;
		str->meshflags |= MESH_HIDE;
	}
	if (flags & W3D_BOX_ATTRIBUTE_ALIGNED)
	{
		str->type = TYPE_AABOX;
	}
	int ct = flags & W3D_MESH_FLAG_COLLISION_TYPE_MASK;
	if (ct & W3D_MESH_FLAG_COLLISION_TYPE_PHYSICAL)
	{
		str->collideflags |= COLLIDE_PHYSICAL;
	}
	else
	{
		str->collideflags &= ~COLLIDE_PHYSICAL;
	}

	if (ct & W3D_MESH_FLAG_COLLISION_TYPE_PROJECTILE)
	{
		str->collideflags |= COLLIDE_PROJECTILE;
	}
	else
	{
		str->collideflags &= ~COLLIDE_PROJECTILE;
	}

	if (ct & W3D_MESH_FLAG_COLLISION_TYPE_VIS)
	{
		str->collideflags |= COLLIDE_VIS;
	}
	else
	{
		str->collideflags &= ~COLLIDE_VIS;
	}

	if (ct & W3D_MESH_FLAG_COLLISION_TYPE_CAMERA)
	{
		str->collideflags |= COLLIDE_CAMERA;
	}
	else
	{
		str->collideflags &= ~COLLIDE_CAMERA;
	}

	if (ct & W3D_MESH_FLAG_COLLISION_TYPE_VEHICLE)
	{
		str->collideflags |= COLLIDE_VEHICLE;
	}
	else
	{
		str->collideflags &= ~COLLIDE_VEHICLE;
	}
	return &ok;
}

def_visible_primitive(wwSetSorting,"wwSetSorting");
Value *wwSetSorting_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSorting,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Sorting",arg_list[1],class_tag(Integer));
	}
	INode *node = arg_list[0]->to_node();
	int type = arg_list[1]->to_int();
	GetW3DAppData1Struct(node)->sorting = type;
	return &ok;
}

def_visible_primitive(wwSetHide,"wwSetHide");
Value *wwSetHide_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetHide,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_HIDE;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_HIDE;
	}
	return &ok;
}

def_visible_primitive(wwSet2Side,"wwSet2Side");
Value *wwSet2Side_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSet2Side,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_2SIDE;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_2SIDE;
	}
	return &ok;
}

def_visible_primitive(wwSetShadow,"wwSetShadow");
Value *wwSetShadow_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetShadow,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_SHADOW;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_SHADOW;
	}
	return &ok;
}

def_visible_primitive(wwSetVAlpha,"wwSetVAlpha");
Value *wwSetVAlpha_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetVAlpha,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_VALPHA;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_VALPHA;
	}
	return &ok;
}

def_visible_primitive(wwSetZNormal,"wwSetZNormal");
Value *wwSetZNormal_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetZNormal,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_ZNORMAL;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_ZNORMAL;
	}
	return &ok;
}

def_visible_primitive(wwSetShatter,"wwSetShatter");
Value *wwSetShatter_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetShatter,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_SHATTER;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_SHATTER;
	}
	return &ok;
}

def_visible_primitive(wwSetNPatch,"wwSetNPatch");
Value *wwSetNPatch_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetNPatch,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_NPATCH;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_NPATCH;
	}
	return &ok;
}

def_visible_primitive(wwSetKeepNormal,"wwSetKeepNormal");
Value *wwSetKeepNormal_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetKeepNormal,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->meshflags |= MESH_KEEPNORMAL;
	}
	else
	{
		GetW3DAppData1Struct(node)->meshflags &= ~MESH_KEEPNORMAL;
	}
	return &ok;
}

def_visible_primitive(wwSetCollidePhysical,"wwSetCollidePhysical");
Value *wwSetCollidePhysical_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetCollidePhysical,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->collideflags |= COLLIDE_PHYSICAL;
	}
	else
	{
		GetW3DAppData1Struct(node)->collideflags &= ~COLLIDE_PHYSICAL;
	}
	return &ok;
}

def_visible_primitive(wwSetCollideProjectile,"wwSetCollideProjectile");
Value *wwSetCollideProjectile_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetCollideProjectile,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->collideflags |= COLLIDE_PROJECTILE;
	}
	else
	{
		GetW3DAppData1Struct(node)->collideflags &= ~COLLIDE_PROJECTILE;
	}
	return &ok;
}

def_visible_primitive(wwSetCollideVis,"wwSetCollideVis");
Value *wwSetCollideVis_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetCollideVis,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->collideflags |= COLLIDE_VIS;
	}
	else
	{
		GetW3DAppData1Struct(node)->collideflags &= ~COLLIDE_VIS;
	}
	return &ok;
}

def_visible_primitive(wwSetCollideCamera,"wwSetCollideCamera");
Value *wwSetCollideCamera_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetCollideCamera,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->collideflags |= COLLIDE_CAMERA;
	}
	else
	{
		GetW3DAppData1Struct(node)->collideflags &= ~COLLIDE_CAMERA;
	}
	return &ok;
}

def_visible_primitive(wwSetCollideVehicle,"wwSetCollideVehicle");
Value *wwSetCollideVehicle_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetCollideVehicle,2,count);
	if (!is_node(arg_list[0]))
	{
		throw TypeError("Max INode",arg_list[0],class_tag(MAXNode));
	}
	if (!is_bool(arg_list[1]))
	{
		throw TypeError("Boolean",arg_list[1],class_tag(Boolean));
	}
	INode *node = arg_list[0]->to_node();
	BOOL hide = arg_list[1]->to_bool();
	if (hide)
	{
		GetW3DAppData1Struct(node)->collideflags |= COLLIDE_VEHICLE;
	}
	else
	{
		GetW3DAppData1Struct(node)->collideflags &= ~COLLIDE_VEHICLE;
	}
	return &ok;
}

#define is_material(mat) mat->is_kind_of(class_tag(MAXMaterial))
def_visible_primitive(wwSetSortLevel,"wwSetSortLevel");
Value *wwSetSortLevel_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSortLevel,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Value",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int value = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SortLevel = value;
	}
	return &ok;
}

def_visible_primitive(wwGetSortLevel,"wwGetSortLevel");
Value *wwGetSortLevel_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetSortLevel,1,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->SortLevel);
	}
	return &undefined;
}

def_visible_primitive(wwSetSurfaceType,"wwSetSurfaceType");
Value *wwSetSurfaceType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSurfaceType,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Value",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int value = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SurfaceType = value;
	}
	return &ok;
}

def_visible_primitive(wwGetSurfaceType,"wwGetSurfaceType");
Value *wwGetSurfaceType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetSurfaceType,1,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->SurfaceType);
	}
	return &undefined;
}

def_visible_primitive(wwSetPassCount,"wwSetPassCount");
Value *wwSetPassCount_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetPassCount,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Value",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int value = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetPassCount(value);
	}
	return &ok;
}

def_visible_primitive(wwGetPassCount,"wwGetPassCount");
Value *wwGetPassCount_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetPassCount,1,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->PassCount());
	}
	return &undefined;
}

def_visible_primitive(wwSetWriteZBuffer,"wwSetWriteZBuffer");
Value *wwSetWriteZBuffer_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetWriteZBuffer,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_bool(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	BOOL value = arg_list[2]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetWriteZBuffer(pass,value);
	}
	return &ok;
}

def_visible_primitive(wwGetWriteZBuffer,"wwGetWriteZBuffer");
Value *wwGetWriteZBuffer_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetWriteZBuffer,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		bool b = gm->GetWriteZBuffer(pass);
		if (b)
		{
			return &true_value;
		}
		else
		{
			return &false_value;
		}
	}
	return &undefined;
}

def_visible_primitive(wwSetDestBlend,"wwSetDestBlend");
Value *wwSetDestBlend_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDestBlend,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetDestBlend(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetSrcBlend,"wwSetSrcBlend");
Value *wwSetSrcBlend_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSrcBlend,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetSrcBlend(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetPriGradient,"wwSetPriGradient");
Value *wwSetPriGradient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetPriGradient,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetPriGradient(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetDepthCompare,"wwSetDepthCompare");
Value *wwSetDepthCompare_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDepthCompare,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetDepthCmp(pass,value);
	}
	return &ok;
}

def_visible_primitive(wwSetDetailColor,"wwSetDetailColor");
Value *wwSetDetailColor_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDetailColor,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetDetailColor(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetDetailAlpha,"wwSetDetailAlpha");
Value *wwSetDetailAlpha_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDetailAlpha,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetDetailAlpha(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetSecGradient,"wwSetSecGradient");
Value *wwSetSecGradient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSecGradient,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetSecGradient(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetOpacity,"wwSetOpacity");
Value *wwSetOpacity_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetOpacity,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Float));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	float value = arg_list[2]->to_float();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetOpacity(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetShininess,"wwSetShininess");
Value *wwSetShininess_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetShininess,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Float));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	float value = arg_list[2]->to_float();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetShininess(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetTranslucency,"wwSetTranslucency");
Value *wwSetTranslucency_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetTranslucency,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Float));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	float value = arg_list[2]->to_float();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetTranslucency(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetUV,"wwSetUV");
Value *wwSetUV_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetUV,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetUV(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwGetUV,"wwGetUV");
Value *wwGetUV_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetUV,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int uv = gm->GetUV(pass,stage);
		return Integer::intern(uv);
	}
	return &undefined;
}

def_visible_primitive(wwSetAmbient,"wwSetAmbient");
Value *wwSetAmbient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetAmbient,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_color(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	COLORREF value = arg_list[2]->to_colorref();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetAmbient(pass,0,Color(value));
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetDiffuse,"wwSetDiffuse");
Value *wwSetDiffuse_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetDiffuse,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_color(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	COLORREF value = arg_list[2]->to_colorref();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetDiffuse(pass,0,Color(value));
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetSpecular,"wwSetSpecular");
Value *wwSetSpecular_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSpecular,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_color(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	COLORREF value = arg_list[2]->to_colorref();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetSpecular(pass,0,Color(value));
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetEmissive,"wwSetEmissive");
Value *wwSetEmissive_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetEmissive,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_color(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	COLORREF value = arg_list[2]->to_colorref();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetEmissive(pass,0,Color(value));
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetSpecularToDiffuse,"wwSetSpecularToDiffuse");
Value *wwSetSpecularToDiffuse_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetSpecularToDiffuse,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_bool(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	BOOL value = arg_list[2]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetSpecularToDiffuse(pass,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetMapType,"wwSetMapType");
Value *wwSetMapType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetMapType,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->DoSetMapType(pass,stage,value);
		gm->MapperTypes[stage][pass] = value;
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetFrames,"wwSetFrames");
Value *wwSetFrames_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetFrames,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetFrames(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetFrameRate,"wwSetFrameRate");
Value *wwSetFrameRate_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetFrameRate,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Float));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	float value = arg_list[3]->to_float();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetFrameRate(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetPublish,"wwSetPublish");
Value *wwSetPublish_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetPublish,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_bool(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	BOOL value = arg_list[3]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetPublish(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetClampU,"wwSetClampU");
Value *wwSetClampU_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetClampU,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_bool(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	BOOL value = arg_list[3]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetClampU(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetClampV,"wwSetClampV");
Value *wwSetClampV_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetClampV,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_bool(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	BOOL value = arg_list[3]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetClampV(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetNoLod,"wwSetNoLod");
Value *wwSetNoLod_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetNoLod,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_bool(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	BOOL value = arg_list[3]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetNoLOD(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetAlphaBitmap,"wwSetAlphaBitmap");
Value *wwSetAlphaBitmap_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetAlphaBitmap,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_bool(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Boolean));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	BOOL value = arg_list[3]->to_bool();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetAlphaBitmap(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetAnimType,"wwSetAnimType");
Value *wwSetAnimType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetAnimType,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetAnimType(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwSetPassHint,"wwSetPassHint");
Value *wwSetPassHint_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetPassHint,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		gm->SetPassHint(pass,stage,value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwGetStageFlag,"wwGetStageFlag");
Value *wwGetStageFlag_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetStageFlag,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		bool b = gm->GetTextureStageEnabled(pass,stage);
		if (b)
		{
			return &true_value;
		}
		else
		{
			return &false_value;
		}
	}
	return &undefined;
}

def_visible_primitive(wwSetMapperArgs,"wwSetMapperArgs");
Value *wwSetMapperArgs_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetMapperArgs,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_string(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(String));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	char *value = arg_list[3]->to_string();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int len = strlen(value);
		len += 10;
		gm->MapperArgLengths[pass][stage] = len;
		char *c = (char *)MAX_new_array(len + 1);
		if (gm->MapperArgs[pass][stage])
		{
			MAX_delete_array(gm->MapperArgs[pass][stage]);
			gm->MapperArgs[pass][stage] = 0;
		}
		gm->MapperArgs[pass][stage] = c;
		strcpy(gm->MapperArgs[pass][stage],value);
		gm->MaterialChanged();
	}
	return &ok;
}

def_visible_primitive(wwGetMapperArgs,"wwGetMapperArgs");
Value *wwGetMapperArgs_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetMapperArgs,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		if (gm->MapperArgs[pass][stage] && gm->MapperArgs[pass][stage][0])
		{
			return new String(gm->MapperArgs[pass][stage]);
		}
	}
	return &undefined;
}

def_visible_primitive(wwGetAmbient,"wwGetAmbient");
Value *wwGetAmbient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetAmbient,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return new ColorValue(gm->DoGetAmbient(pass,0));
	}
	return &undefined;
}

def_visible_primitive(wwGetDiffuse,"wwGetDiffuse");
Value *wwGetDiffuse_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetDiffuse,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return new ColorValue(gm->DoGetDiffuse(pass,0));
	}
	return &undefined;
}

def_visible_primitive(wwGetSpecular,"wwGetSpecular");
Value *wwGetSpecular_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetSpecular,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return new ColorValue(gm->DoGetSpecular(pass,0));
	}
	return &undefined;
}

def_visible_primitive(wwGetEmissive,"wwGetEmissive");
Value *wwGetEmissive_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetEmissive,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return new ColorValue(gm->DoGetEmissive(pass,0));
	}
	return &undefined;
}

def_visible_primitive(wwGetShininess,"wwGetShininess");
Value *wwGetShininess_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetShininess,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Float::intern(gm->DoGetShininess(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetOpacity,"wwGetOpacity");
Value *wwGetOpacity_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetOpacity,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Float::intern(gm->DoGetOpacity(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetTranslucency,"wwGetTranslucency");
Value *wwGetTranslucency_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetOpacity,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Float::intern(gm->DoGetTranslucency(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetDepthCompare,"wwGetDepthCompare");
Value *wwGetDepthCompare_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetDepthCompare,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetDepthCmp(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetDestBlend,"wwGetDestBlend");
Value *wwGetDestBlend_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetDestBlend,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetDestBlend(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetPriGradient,"wwGetPriGradient");
Value *wwGetPriGradient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetPriGradient,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetPriGradient(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetSecGradient,"wwGetSecGradient");
Value *wwGetSecGradient_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetSecGradient,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetSecGradient(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetSrcBlend,"wwGetSrcBlend");
Value *wwGetSrcBlend_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetSrcBlend,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetSrcBlend(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetDetailColor,"wwGetDetailColor");
Value *wwGetDetailColor_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetDetailColor,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetDetailColor(pass));
	}
	return &undefined;
}

def_visible_primitive(wwGetDetailAlpha,"wwGetDetailAlpha");
Value *wwGetDetailAlpha_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetDetailAlpha,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetDetailAlpha(pass));
	}
	return &undefined;
}
#define		W3DVERTMAT_USE_DEPTH_CUE								0x00000001
#define		W3DVERTMAT_ARGB_EMISSIVE_ONLY							0x00000002
#define		W3DVERTMAT_COPY_SPECULAR_TO_DIFFUSE					0x00000004
#define		W3DVERTMAT_DEPTH_CUE_TO_ALPHA							0x00000008

#define		W3DVERTMAT_STAGE0_MAPPING_MASK						0x00FF0000
#define		W3DVERTMAT_STAGE0_MAPPING_UV							0x00000000
#define		W3DVERTMAT_STAGE0_MAPPING_ENVIRONMENT				0x00010000
#define		W3DVERTMAT_STAGE0_MAPPING_CHEAP_ENVIRONMENT		0x00020000
#define		W3DVERTMAT_STAGE0_MAPPING_SCREEN						0x00030000
#define		W3DVERTMAT_STAGE0_MAPPING_LINEAR_OFFSET			0x00040000
#define		W3DVERTMAT_STAGE0_MAPPING_SILHOUETTE				0x00050000
#define		W3DVERTMAT_STAGE0_MAPPING_SCALE						0x00060000
#define		W3DVERTMAT_STAGE0_MAPPING_GRID						0x00070000
#define		W3DVERTMAT_STAGE0_MAPPING_ROTATE						0x00080000
#define		W3DVERTMAT_STAGE0_MAPPING_SINE_LINEAR_OFFSET		0x00090000
#define		W3DVERTMAT_STAGE0_MAPPING_STEP_LINEAR_OFFSET		0x000A0000
#define		W3DVERTMAT_STAGE0_MAPPING_ZIGZAG_LINEAR_OFFSET	0x000B0000
#define		W3DVERTMAT_STAGE0_MAPPING_WS_CLASSIC_ENV			0x000C0000
#define		W3DVERTMAT_STAGE0_MAPPING_WS_ENVIRONMENT			0x000D0000
#define		W3DVERTMAT_STAGE0_MAPPING_GRID_CLASSIC_ENV		0x000E0000
#define		W3DVERTMAT_STAGE0_MAPPING_GRID_ENVIRONMENT		0x000F0000
#define		W3DVERTMAT_STAGE0_MAPPING_RANDOM						0x00100000
#define		W3DVERTMAT_STAGE0_MAPPING_EDGE						0x00110000
#define		W3DVERTMAT_STAGE0_MAPPING_BUMPENV					0x00120000

#define		W3DVERTMAT_STAGE1_MAPPING_MASK						0x0000FF00
#define		W3DVERTMAT_STAGE1_MAPPING_UV							0x00000000
#define		W3DVERTMAT_STAGE1_MAPPING_ENVIRONMENT				0x00000100
#define		W3DVERTMAT_STAGE1_MAPPING_CHEAP_ENVIRONMENT		0x00000200
#define		W3DVERTMAT_STAGE1_MAPPING_SCREEN						0x00000300
#define		W3DVERTMAT_STAGE1_MAPPING_LINEAR_OFFSET			0x00000400
#define		W3DVERTMAT_STAGE1_MAPPING_SILHOUETTE				0x00000500
#define		W3DVERTMAT_STAGE1_MAPPING_SCALE						0x00000600
#define		W3DVERTMAT_STAGE1_MAPPING_GRID						0x00000700
#define		W3DVERTMAT_STAGE1_MAPPING_ROTATE						0x00000800
#define		W3DVERTMAT_STAGE1_MAPPING_SINE_LINEAR_OFFSET		0x00000900
#define		W3DVERTMAT_STAGE1_MAPPING_STEP_LINEAR_OFFSET		0x00000A00
#define		W3DVERTMAT_STAGE1_MAPPING_ZIGZAG_LINEAR_OFFSET	0x00000B00
#define		W3DVERTMAT_STAGE1_MAPPING_WS_CLASSIC_ENV			0x00000C00
#define		W3DVERTMAT_STAGE1_MAPPING_WS_ENVIRONMENT			0x00000D00
#define		W3DVERTMAT_STAGE1_MAPPING_GRID_CLASSIC_ENV		0x00000E00
#define		W3DVERTMAT_STAGE1_MAPPING_GRID_ENVIRONMENT		0x00000F00
#define		W3DVERTMAT_STAGE1_MAPPING_RANDOM						0x00001000
#define		W3DVERTMAT_STAGE1_MAPPING_EDGE						0x00001100
#define		W3DVERTMAT_STAGE1_MAPPING_BUMPENV					0x00001200
def_visible_primitive(wwSetMatFlags,"wwSetMatFlags");
Value *wwSetMatFlags_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetMatFlags,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Value",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int value = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int m1 = (value & W3DVERTMAT_STAGE0_MAPPING_MASK) >> 0x10;
		gm->DoSetMapType(pass,0,m1);
		gm->MapperTypes[pass][0] = m1;
		int m2 = (value & W3DVERTMAT_STAGE1_MAPPING_MASK) >> 8;
		gm->DoSetMapType(pass,1,m2);
		gm->MapperTypes[pass][1] = m2;
		int f = value & W3DVERTMAT_COPY_SPECULAR_TO_DIFFUSE;
		gm->DoSetSpecularToDiffuse(pass,f == 1);
	}
	return &ok;
}

def_visible_primitive(wwGetMatFlags,"wwGetMatFlags");
Value *wwGetMatFlags_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetMatFlags,2,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int m1 = gm->DoGetMapType(pass,0) << 0x10;
		int m2 = gm->DoGetMapType(pass,1) << 0x10;
		int f = gm->GetSpecularToDiffuse(pass) == 1 ? W3DVERTMAT_COPY_SPECULAR_TO_DIFFUSE : 0;
		int flags = m1 | m2 | f;
		return Integer::intern(flags);
	}
	return &undefined;
}
#define W3DTEXTURE_PUBLISH					0x0001
#define W3DTEXTURE_RESIZE_OBSOLETE		0x0002
#define W3DTEXTURE_NO_LOD					0x0004
#define W3DTEXTURE_CLAMP_U					0x0008
#define W3DTEXTURE_CLAMP_V					0x0010
#define W3DTEXTURE_ALPHA_BITMAP			0x0020
#define W3DTEXTURE_MIP_LEVELS_MASK		0x00c0
#define W3DTEXTURE_MIP_LEVELS_ALL		0x0000
#define W3DTEXTURE_MIP_LEVELS_2			0x0040
#define W3DTEXTURE_MIP_LEVELS_3			0x0080
#define W3DTEXTURE_MIP_LEVELS_4			0x00c0
#define W3DTEXTURE_HINT_SHIFT				8
#define W3DTEXTURE_HINT_MASK				0x0000ff00
#define W3DTEXTURE_HINT_BASE				0x0000
#define W3DTEXTURE_HINT_EMISSIVE			0x0100
#define W3DTEXTURE_HINT_ENVIRONMENT		0x0200
#define W3DTEXTURE_HINT_SHINY_MASK		0x0300
#define W3DTEXTURE_TYPE_MASK				0x1000	
#define W3DTEXTURE_TYPE_COLORMAP			0x0000
#define W3DTEXTURE_TYPE_BUMPMAP			0x1000
def_visible_primitive(wwSetTexFlags,"wwSetTexFlags");
Value *wwSetTexFlags_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetTexFlags,4,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Value",arg_list[3],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	int value = arg_list[3]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int p = (value & W3DTEXTURE_PUBLISH);
		gm->SetPublish(pass,stage,p == 1);
		int n = (value & W3DTEXTURE_NO_LOD);
		gm->SetNoLOD(pass,stage,n == 1);
		int u = (value & W3DTEXTURE_CLAMP_U);
		gm->SetClampU(pass,stage,u == 1);
		int v = (value & W3DTEXTURE_CLAMP_V);
		gm->SetClampV(pass,stage,v == 1);
		int a = (value & W3DTEXTURE_ALPHA_BITMAP);
		gm->SetAlphaBitmap(pass,stage,a == 1);
		int h = (value & W3DTEXTURE_HINT_MASK & ~W3DTEXTURE_TYPE_MASK) >> W3DTEXTURE_HINT_SHIFT;
		gm->SetPassHint(pass,stage,h);
	}
	return &ok;
}

def_visible_primitive(wwGetTexFlags,"wwGetTexFlags");
Value *wwGetTexFlags_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetTexFlags,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		int p = gm->GetPublish(pass,stage) == 1 ? W3DTEXTURE_PUBLISH : 0;
		int n = gm->GetNoLOD(pass,stage) == 1 ? W3DTEXTURE_NO_LOD : 0;
		int u = gm->GetClampU(pass,stage) == 1 ? W3DTEXTURE_CLAMP_U : 0;
		int v = gm->GetClampV(pass,stage) == 1 ? W3DTEXTURE_CLAMP_V : 0;
		int a = gm->GetAlphaBitmap(pass,stage) == 1 ? W3DTEXTURE_ALPHA_BITMAP : 0;
		int h = gm->GetPassHint(pass,stage) << W3DTEXTURE_HINT_SHIFT;
		int flags = p | n | u | v | a | h;
		return Integer::intern(flags);
	}
	return &undefined;
}

def_visible_primitive(wwGetAnimType,"wwGetAnimType");
Value *wwGetAnimType_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetAnimType,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Integer::intern(gm->GetAnimType(pass,stage));
	}
	return &undefined;
}

def_visible_primitive(wwGetFrames,"wwGetFrames");
Value *wwGetFrames_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetFrames,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Float::intern(gm->GetFrames(pass,stage));
	}
	return &undefined;
}

def_visible_primitive(wwGetFrameRate,"wwGetFrameRate");
Value *wwGetFrameRate_cf(Value ** arg_list, int count)
{
	check_arg_count(wwGetFrameRate,3,count);
	if (!is_material(arg_list[0]))
	{
		throw TypeError("Max Mat",arg_list[0],class_tag(MAXMaterial));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Pass",arg_list[1],class_tag(Integer));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Stage",arg_list[2],class_tag(Integer));
	}
	Mtl *mtl = arg_list[0]->to_mtl();
	int pass = arg_list[1]->to_int();
	int stage = arg_list[2]->to_int();
	if (mtl->ClassID() == GameMtlID)
	{
		GameMtl *gm = (GameMtl *)mtl;
		return Float::intern(gm->GetFrameRate(pass,stage));
	}
	return &undefined;
}

def_visible_primitive(wwLogString,"wwLogString");
Value *wwLogString_cf(Value ** arg_list, int count)
{
	check_arg_count(wwLogString,1,count);
	if (!is_string(arg_list[0]))
	{
		throw TypeError("Type",arg_list[0],class_tag(String));
	}
	char *log = arg_list[0]->to_string();
	FILE *f = fopen("log.txt","at");
	fprintf(f,"%s\n",log);
	fclose(f);
	return &ok;
}

def_visible_primitive(wwLogInt,"wwLogInt");
Value *wwLogInt_cf(Value ** arg_list, int count)
{
	check_arg_count(wwLogInt,1,count);
	if (!is_number(arg_list[0]))
	{
		throw TypeError("Type",arg_list[0],class_tag(Integer));
	}
	int log = arg_list[0]->to_int();
	FILE *f = fopen("log.txt","at");
	fprintf(f,"%d\n",log);
	fclose(f);
	return &ok;
}

def_visible_primitive(wwLogFloat,"wwLogFloat");
Value *wwLogFloat_cf(Value ** arg_list, int count)
{
	check_arg_count(wwLogFloat,1,count);
	if (!is_number(arg_list[0]))
	{
		throw TypeError("Type",arg_list[0],class_tag(Float));
	}
	float log = arg_list[0]->to_float();
	FILE *f = fopen("log.txt","at");
	fprintf(f,"%.8f\n",log);
	fclose(f);
	return &ok;
}

Matrix3 *BoneTransforms = 0;

def_visible_primitive(wwSetBoneCount,"wwSetBoneCount");
Value *wwSetBoneCount_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetBoneCount,1,count);
	if (!is_number(arg_list[0]))
	{
		throw TypeError("Count",arg_list[0],class_tag(Integer));
	}
	int Count = arg_list[0]->to_int();
	if (BoneTransforms)
	{
		delete[] BoneTransforms;
	}
	BoneTransforms = new Matrix3[Count];
	return &ok;
}

def_visible_primitive(wwSetBone,"wwSetBone");
Value *wwSetBone_cf(Value ** arg_list, int count)
{
	check_arg_count(wwSetBone,4,count);
	if (!is_point3(arg_list[0]))
	{
		throw TypeError("Translation",arg_list[0],class_tag(Point3Value));
	}
	if (!is_quat(arg_list[1]))
	{
		throw TypeError("Rotation",arg_list[1],class_tag(QuatValue));
	}
	if (!is_number(arg_list[2]))
	{
		throw TypeError("Bone",arg_list[2],class_tag(Integer));
	}
	if (!is_number(arg_list[3]))
	{
		throw TypeError("Parent",arg_list[3],class_tag(Integer));
	}
	Point3 Translation = arg_list[0]->to_point3();
	Quat Rotation = arg_list[1]->to_quat();
	int Bone = arg_list[2]->to_int();
	int Parent = arg_list[3]->to_int();
	Point3 U((float)(1.0 - 2.0 * (Rotation[1] * Rotation[1] + Rotation[2] * Rotation[2])),(float)(2.0 * (Rotation[0] * Rotation[1] - Rotation[2] * Rotation[3])),(float)(2.0 * (Rotation[2] * Rotation[0] + Rotation[1] * Rotation[3])));
	Point3 V((float)(2.0 * (Rotation[0] * Rotation[1] + Rotation[2] * Rotation[3])),(float)(1.0 - 2.0f * (Rotation[2] * Rotation[2] + Rotation[0] * Rotation[0])),(float)(2.0 * (Rotation[1] * Rotation[2] - Rotation[0] * Rotation[3])));
	Point3 N((float)(2.0 * (Rotation[2] * Rotation[0] - Rotation[1] * Rotation[3])),(float)(2.0 * (Rotation[1] * Rotation[2] + Rotation[0] * Rotation[3])),(float)(1.0 - 2.0 * (Rotation[1] * Rotation[1] + Rotation[0] * Rotation[0])));
	Matrix3 tm(U,V,N,Translation);
	if (Parent)
	{
		const Matrix3 ptm = BoneTransforms[Parent];
		const Matrix3 btm = tm;
		float mat[3][4];
		float pmat[3][4];
		float omat[3][4];
		mat[0][0] = btm[0][0];
		mat[0][1] = btm[0][1];
		mat[0][2] = btm[0][2];
		mat[1][0] = btm[1][0];
		mat[1][1] = btm[1][1];
		mat[1][2] = btm[1][2];
		mat[2][0] = btm[2][0];
		mat[2][1] = btm[2][1];
		mat[2][2] = btm[2][2];
		mat[0][3] = btm[3][0];
		mat[1][3] = btm[3][1];
		mat[2][3] = btm[3][2];
		pmat[0][0] = ptm[0][0];
		pmat[0][1] = ptm[0][1];
		pmat[0][2] = ptm[0][2];
		pmat[1][0] = ptm[1][0];
		pmat[1][1] = ptm[1][1];
		pmat[1][2] = ptm[1][2];
		pmat[2][0] = ptm[2][0];
		pmat[2][1] = ptm[2][1];
		pmat[2][2] = ptm[2][2];
		pmat[0][3] = ptm[3][0];
		pmat[1][3] = ptm[3][1];
		pmat[2][3] = ptm[3][2];
		float tmp1,tmp2,tmp3;
		tmp1 = mat[0][0];
		tmp2 = mat[1][0];
		tmp3 = mat[2][0];
		omat[0][0] = pmat[0][0]*tmp1 + pmat[0][1]*tmp2 + pmat[0][2]*tmp3;
		omat[1][0] = pmat[1][0]*tmp1 + pmat[1][1]*tmp2 + pmat[1][2]*tmp3;
		omat[2][0] = pmat[2][0]*tmp1 + pmat[2][1]*tmp2 + pmat[2][2]*tmp3;
		tmp1 = mat[0][1];
		tmp2 = mat[1][1];
		tmp3 = mat[2][1];
		omat[0][1] = pmat[0][0]*tmp1 + pmat[0][1]*tmp2 + pmat[0][2]*tmp3;
		omat[1][1] = pmat[1][0]*tmp1 + pmat[1][1]*tmp2 + pmat[1][2]*tmp3;
		omat[2][1] = pmat[2][0]*tmp1 + pmat[2][1]*tmp2 + pmat[2][2]*tmp3;
		tmp1 = mat[0][2];
		tmp2 = mat[1][2];
		tmp3 = mat[2][2];
		omat[0][2] = pmat[0][0]*tmp1 + pmat[0][1]*tmp2 + pmat[0][2]*tmp3;
		omat[1][2] = pmat[1][0]*tmp1 + pmat[1][1]*tmp2 + pmat[1][2]*tmp3;
		omat[2][2] = pmat[2][0]*tmp1 + pmat[2][1]*tmp2 + pmat[2][2]*tmp3;
		tmp1 = mat[0][3];
		tmp2 = mat[1][3];
		tmp3 = mat[2][3];
		omat[0][3] = pmat[0][0]*tmp1 + pmat[0][1]*tmp2 + pmat[0][2]*tmp3 + pmat[0][3];
		omat[1][3] = pmat[1][0]*tmp1 + pmat[1][1]*tmp2 + pmat[1][2]*tmp3 + pmat[1][3];
		omat[2][3] = pmat[2][0]*tmp1 + pmat[2][1]*tmp2 + pmat[2][2]*tmp3 + pmat[2][3];
		Point3 U(omat[0][0],omat[0][1],omat[0][2]);
		Point3 V(omat[1][0],omat[1][1],omat[1][2]);
		Point3 N(omat[2][0],omat[2][1],omat[2][2]);
		Point3 T(omat[0][3],omat[1][3],omat[2][3]);
		tm.Set(U,V,N,T);
	}
	BoneTransforms[Bone] = tm;
	return &ok;
}

def_visible_primitive(wwTransformVertex,"wwTransformVertex");
Value *wwTransformVertex_cf(Value ** arg_list, int count)
{
	check_arg_count(wwTransformVertex,2,count);
	if (!is_point3(arg_list[0]))
	{
		throw TypeError("Vertex",arg_list[0],class_tag(Point3Value));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Bone",arg_list[1],class_tag(Integer));
	}
	Point3 Vertex = arg_list[0]->to_point3();
	int Bone = arg_list[1]->to_int();
	Point3 Out;
	if (Bone)
	{
		const Matrix3 tm = BoneTransforms[Bone];
		Out.x = (tm[0][0] * Vertex.x + tm[0][1] * Vertex.y + tm[0][2] * Vertex.z + tm[3][0]);
		Out.y = (tm[1][0] * Vertex.x + tm[1][1] * Vertex.y + tm[1][2] * Vertex.z + tm[3][1]);
		Out.z = (tm[2][0] * Vertex.x + tm[2][1] * Vertex.y + tm[2][2] * Vertex.z + tm[3][2]);
	}
	else
	{
		Out = Vertex;
	}
	return new Point3Value(Out);
}

def_visible_primitive(wwTransformNormal,"wwTransformNormal");
Value *wwTransformNormal_cf(Value ** arg_list, int count)
{
	check_arg_count(wwTransformNormal,2,count);
	if (!is_point3(arg_list[0]))
	{
		throw TypeError("Normal",arg_list[0],class_tag(Point3Value));
	}
	if (!is_number(arg_list[1]))
	{
		throw TypeError("Bone",arg_list[1],class_tag(Integer));
	}
	Point3 Normal = arg_list[0]->to_point3();
	int Bone = arg_list[1]->to_int();
	Point3 Out;
	if (Bone)
	{
		const Matrix3 tm = BoneTransforms[Bone];
		Out.x = (tm[0][0] * Normal.x + tm[0][1] * Normal.y + tm[0][2] * Normal.z);
		Out.y = (tm[1][0] * Normal.x + tm[1][1] * Normal.y + tm[1][2] * Normal.z);
		Out.z = (tm[2][0] * Normal.x + tm[2][1] * Normal.y + tm[2][2] * Normal.z);
	}
	else
	{
		Out = Normal;
	}
	return new Point3Value(Out);
}

extern "C" {
__declspec( dllexport ) ClassDesc*
LibClassDesc(int i)
{
	return 0;
}

__declspec( dllexport ) int LibNumberClasses()
{
	return 0;
}

__declspec( dllexport ) const TCHAR *
LibDescription() {
	return "Maxscript Extentions for W3D Export Plugin";
}

__declspec( dllexport ) ULONG LibVersion() { return VERSION_3DSMAX; }

HINSTANCE hInstance;
int controlsInit = FALSE;
BOOL WINAPI
DllMain(HINSTANCE hinstDLL,ULONG fdwReason,LPVOID lpvReserved)
{
	hInstance = hinstDLL;
	if ( !controlsInit )
	{
		controlsInit = TRUE;
		InitCustomControls(hInstance);
		INITCOMMONCONTROLSEX ex;
		ex.dwSize = 8;
		ex.dwICC = 1791;
		InitCommonControlsEx(&ex);
	}
	return(TRUE);
}
}
