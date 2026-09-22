#include <stdio.h>
#include <string.h>
#include "w3d_file.h"
int main(int argc,char *argv[])
{
  chunk *c = new chunk;
  FILE *f,*f2;
  char d;
  char *text;
  char oldname[W3D_NAME_LEN];
  char newname[W3D_NAME_LEN];
  char oldname2[W3D_NAME_LEN*2];
  char newname2[W3D_NAME_LEN*2];
  char temp[W3D_NAME_LEN*2];
  char *st;
  char oldname3[260];
  char newname3[260];
  char *s1,*s2;
  int i,j,s,q;
  int fsize;
  uint32 u;
  W3dMeshHeader3Struct *m = new W3dMeshHeader3Struct;
  W3dVectorStruct *v = new W3dVectorStruct;
  W3dVertInfStruct *vi = new W3dVertInfStruct;
  W3dTriStruct *t = new W3dTriStruct;
  W3dMaterialInfoStruct *mi = new W3dMaterialInfoStruct;
  W3dShaderStruct *sh = new W3dShaderStruct;
  W3dVertexMaterialStruct *vm = new W3dVertexMaterialStruct;
  W3dTextureInfoStruct *ti = new W3dTextureInfoStruct;
  W3dRGBAStruct *r = new W3dRGBAStruct;
  W3dRGBStruct *rg = new W3dRGBStruct;
  W3dTexCoordStruct *tc = new W3dTexCoordStruct;
  W3dMeshAABTreeHeader *aa = new W3dMeshAABTreeHeader;
  W3dMeshAABTreeNode *an = new W3dMeshAABTreeNode;
  W3dHierarchyStruct *h = new W3dHierarchyStruct;
  W3dPivotStruct *p = new W3dPivotStruct;
  W3dPivotFixupStruct *pf = new W3dPivotFixupStruct;
  W3dAnimHeaderStruct *ah = new W3dAnimHeaderStruct;
  W3dCompressedAnimHeaderStruct *ac = new W3dCompressedAnimHeaderStruct;
  W3dMorphAnimHeaderStruct *am = new W3dMorphAnimHeaderStruct;
  W3dHModelHeaderStruct *hm = new W3dHModelHeaderStruct;
  W3dHModelNodeStruct *hn = new W3dHModelNodeStruct;
  W3dEmitterHeaderStruct *e = new W3dEmitterHeaderStruct;
  W3dEmitterInfoStruct *ei = new W3dEmitterInfoStruct;
  W3dAggregateHeaderStruct *ag = new W3dAggregateHeaderStruct;
  W3dAggregateInfoStruct *ai = new W3dAggregateInfoStruct;
  W3dAggregateSubobjectStruct *as = new W3dAggregateSubobjectStruct;
  W3dHLodHeaderStruct *hl = new W3dHLodHeaderStruct;
  W3dHLodSubObjectStruct *hs = new W3dHLodSubObjectStruct;
  W3dBoxStruct *b = new W3dBoxStruct;
  W3dSoundRObjHeaderStruct *sr = new W3dSoundRObjHeaderStruct;
  if (argc < 5) {
    printf("usage:\nw3dtool oldfilename newfilename oldname newname");
    exit(1);
  }
  f = fopen(argv[1],"rb");
  f2 = fopen(argv[2],"wb");
  fseek(f,0,SEEK_END);
  fsize = ftell(f);
  fseek(f,0,SEEK_SET);
  s = 0;
  s1 = new char[strlen(argv[3])];
  s2 = new char[strlen(argv[4])];
  strcpy(s1,argv[3]);
  strcpy(s2,argv[4]);
  s1 = _strupr(s1);
  s2 = _strupr(s2);
  for(i=0;i<W3D_NAME_LEN;i++) {
    oldname[i] = 0;
    newname[i] = 0;
  }
  for(i=0;i<strlen(argv[3]);i++) {
    oldname[i] = s1[i];
  }
  for(i=0;i<strlen(argv[4]);i++) {
    newname[i] = s2[i];
  }
  for(i=0;i<W3D_NAME_LEN*2;i++) {
    oldname2[i] = 0;
    newname2[i] = 0;
  }
  for(i=0;i<strlen(argv[3]);i++) {
    oldname2[i] = s1[i];
  }
  for(i=0;i<strlen(argv[4]);i++) {
    newname2[i] = s2[i];
  }
  for(i=0;i<260;i++) {
    oldname3[i] = 0;
    newname3[i] = 0;
  }
  for(i=0;i<strlen(argv[3]);i++) {
    oldname3[i] = s1[i];
  }
  for(i=0;i<strlen(argv[4]);i++) {
    newname3[i] = s2[i];
  }
  while(s<fsize) {
    fread(c,8,1,f);
    if ((c->size < 1) && (c->type != W3D_CHUNK_SPHERE) && (c->type != W3D_CHUNK_RING) && (c->type != W3D_CHUNK_SOUNDROBJ_DEFINITION)) {
      s += 8;
      fwrite(c,8,1,f2);
      continue;
    }
    if ((c->type == W3D_CHUNK_SPHERE) || (c->type == W3D_CHUNK_RING) || (c->type == W3D_CHUNK_SOUNDROBJ_DEFINITION)) {
      c->size &= 0x7FFFFF;
    }
    s += c->size + 8;
    switch(c->type) {
    case W3D_CHUNK_MESH_HEADER3:
      fread(m,sizeof(W3dMeshHeader3Struct),1,f);
      if (stricmp(m->MeshName,oldname) == 0) {
        m->MeshName = newname;
      }
      if (stricmp(m->ContainerName,oldname) == 0) {
        m->ContainerName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(m,sizeof(W3dMeshHeader3Struct),1,f2);
      break;
    case W3D_CHUNK_TEXTURE_NAME:
      text=new char[c->size*2];
      fread(text,c->size,1,f);
      if (stricmp(text,argv[3]) == 0) {
        text = argv[4];
        int x=c->size;
        c->size=c->size-strlen(argv[3])+strlen(argv[4]);
        if (c->size > x) {
          printf("error, name too long");
          exit(1);
        }
      }
      fwrite(c,8,1,f2);
      fwrite(text,c->size,1,f2);
      break;
    case W3D_CHUNK_HIERARCHY_HEADER:
      fread(h,sizeof(W3dHierarchyStruct),1,f);
      if (stricmp(h->Name,oldname) == 0) {
        h->Name = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(h,sizeof(W3dHierarchyStruct),1,f2);
      break;
    case W3D_CHUNK_PIVOTS:
      fwrite(c,8,1,f2);
      for(j=0;j<c->size;j+=sizeof(W3dPivotStruct)) {
        fread(p,sizeof(W3dPivotStruct),1,f);
        if (stricmp(p->Name,oldname) == 0) {
          p->Name = newname;
        }
        fwrite(p,sizeof(W3dPivotStruct),1,f2);
      }
      break;
    case W3D_CHUNK_ANIMATION_HEADER:
      fread(ah,sizeof(W3dAnimHeaderStruct),1,f);
      if (stricmp(ah->Name,oldname) == 0) {
        ah->Name = newname;
      }
      if (stricmp(ah->HierarchyName,oldname) == 0) {
        ah->HierarchyName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(ah,sizeof(W3dAnimHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_COMPRESSED_ANIMATION_HEADER:
      fread(ac,sizeof(W3dCompressedAnimHeaderStruct),1,f);
      if (stricmp(ac->Name,oldname) == 0) {
        ac->Name = newname;
      }
      if (stricmp(ac->HierarchyName,oldname) == 0) {
        ac->HierarchyName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(ac,sizeof(W3dCompressedAnimHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_MORPHANIM_HEADER:
      fread(am,sizeof(W3dMorphAnimHeaderStruct),1,f);
      if (stricmp(am->Name,oldname) == 0) {
        am->Name = newname;
      }
      if (stricmp(am->HierarchyName,oldname) == 0) {
        am->HierarchyName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(am,sizeof(W3dMorphAnimHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_MORPHANIM_POSENAME:
      text=new char[c->size*2];
      fread(text,c->size,1,f);
      if (stricmp(text,argv[3]) == 0) {
        text = argv[4];
        int x=c->size;
        c->size=c->size-strlen(argv[3])+strlen(argv[4]);
        if (c->size > x) {
          printf("error, name too long");
          exit(1);
        }
      }
      fwrite(c,8,1,f2);
      fwrite(text,c->size,1,f2);
      break;
    case W3D_CHUNK_HMODEL_HEADER:
      fread(hm,sizeof(W3dHModelHeaderStruct),1,f);
      if (stricmp(hm->Name,oldname) == 0) {
        hm->Name = newname;
      }
      if (stricmp(hm->HierarchyName,oldname) == 0) {
        hm->HierarchyName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(hm,sizeof(W3dHModelHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_NODE:
    case W3D_CHUNK_COLLISION_NODE:
    case W3D_CHUNK_SKIN_NODE:
      fread(hn,sizeof(W3dHModelNodeStruct),1,f);
      if (stricmp(hn->RenderObjName,oldname) == 0) {
        hn->RenderObjName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(hn,sizeof(W3dHModelNodeStruct),1,f2);
      break;
    case W3D_CHUNK_EMITTER_HEADER:
      fread(e,sizeof(W3dEmitterHeaderStruct),1,f);
      if (stricmp(e->Name,oldname) == 0) {
        e->Name = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(e,sizeof(W3dEmitterHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_EMITTER_INFO:
      fread(ei,sizeof(W3dEmitterInfoStruct),1,f);
      if (stricmp(ei->TextureFilename,oldname3) == 0) {
        ei->TextureFilename = newname3;
      }
      fwrite(c,8,1,f2);
      fwrite(ei,sizeof(W3dEmitterInfoStruct),1,f2);
      break;
    case W3D_CHUNK_AGGREGATE_HEADER:
      fread(ag,sizeof(W3dAggregateHeaderStruct),1,f);
      if (stricmp(ag->Name,oldname) == 0) {
        ag->Name = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(ag,sizeof(W3dAggregateHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_AGGREGATE_INFO:
      fwrite(c,8,1,f2);
      fread(ai,sizeof(W3dAggregateInfoStruct),1,f);
      if (strncmp(ai->BaseModelName,oldname2,strlen(argv[3])) == 0) {
        i = 0;
        if (strchr(ai->BaseModelName,'.') != 0) {
          i = strlen(strstr(ai->BaseModelName,"."));
          strncpy(ai->BaseModelName+strlen(argv[3]),ai->BaseModelName+strlen(argv[4]),i);
        }
        strncpy(ai->BaseModelName,newname2,strlen(argv[4]));
        _strnset(ai->BaseModelName+strlen(argv[4])+i,0,strlen(argv[4])+i);
      } else {
        if (strchr(ai->BaseModelName,'.') != 0) {          
          st = strstr(ai->BaseModelName,oldname2);
          if (st != 0) {
            i = ai->BaseModelName - st;
            strncpy(ai->BaseModelName+i,newname2,strlen(argv[4]));
            _strnset(ai->BaseModelName+i+strlen(argv[4]),0,strlen(argv[4])+i);
          }
        }
      }
      fwrite(ai,sizeof(W3dAggregateInfoStruct),1,f2);
      for(j=0;j<(c->size-sizeof(W3dAggregateInfoStruct));j+=sizeof(W3dAggregateSubobjectStruct)) {
        fread(as,sizeof(W3dAggregateSubobjectStruct),1,f);
        if (strncmp(as->SubobjectName,oldname2,strlen(argv[3])) == 0) {
          i = 0;
          if (strchr(as->SubobjectName,'.') != 0) {
            i = strlen(strstr(as->SubobjectName,"."));
            strncpy(as->SubobjectName+strlen(argv[3]),as->SubobjectName+strlen(argv[4]),i);
          }
          strncpy(as->SubobjectName,newname2,strlen(argv[4]));
          _strnset(as->SubobjectName+strlen(argv[4])+i,0,strlen(argv[4])+i);
        } else {
          if (strchr(as->SubobjectName,'.') != 0) {          
            st = strstr(as->SubobjectName,oldname2);
            if (st != 0) {
              i = as->SubobjectName - st;
              strncpy(as->SubobjectName+i,newname2,strlen(argv[4]));
              _strnset(as->SubobjectName+i+strlen(argv[4]),0,strlen(argv[4])+i);
            }
          }
        }
        if (strncmp(as->BoneName,oldname2,strlen(argv[3])) == 0) {
          i = 0;
          if (strchr(as->BoneName,'.') != 0) {
            i = strlen(strstr(as->BoneName,"."));
            strncpy(as->BoneName+strlen(argv[3]),as->BoneName+strlen(argv[4]),i);
          }
          strncpy(as->BoneName,newname2,strlen(argv[4]));
          _strnset(as->BoneName+strlen(argv[4])+i,0,strlen(argv[4])+i);
        } else {
          if (strchr(as->BoneName,'.') != 0) {          
            st = strstr(as->BoneName,oldname2);
            if (st != 0) {
              i = as->BoneName - st;
              strncpy(as->BoneName+i,newname2,strlen(argv[4]));
              _strnset(as->BoneName+i+strlen(argv[4]),0,strlen(argv[4])+i);
            }
          }
        }
        fwrite(as,sizeof(W3dAggregateSubobjectStruct),1,f2);
      }
      break;
    case W3D_CHUNK_HLOD_HEADER:
      fread(hl,sizeof(W3dHLodHeaderStruct),1,f);
      if (stricmp(hl->Name,oldname) == 0) {
        hl->Name = newname;
      }
      if (stricmp(hl->HierarchyName,oldname) == 0) {
        hl->HierarchyName = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(hl,sizeof(W3dHLodHeaderStruct),1,f2);
      break;
    case W3D_CHUNK_HLOD_SUB_OBJECT:
      fread(hs,sizeof(W3dHLodSubObjectStruct),1,f);
      if (strncmp(hs->Name,oldname2,strlen(argv[3])) == 0) {
        i = 0;
        if (strchr(hs->Name,'.') != 0) {
          i = strlen(strstr(hs->Name,"."));
          strncpy(hs->Name+strlen(argv[3]),hs->Name+strlen(argv[4]),i);
        }
        strncpy(hs->Name,newname2,strlen(argv[4]));
        _strnset(hs->Name+strlen(argv[4])+i,0,strlen(argv[4])+i);
      } else {
        if (strchr(hs->Name,'.') != 0) {          
          st = strstr(hs->Name,oldname2);
          if (st != 0) {
            i = hs->Name - st;
            strncpy(hs->Name+i,newname2,strlen(argv[4]));
            _strnset(hs->Name+i+strlen(argv[4]),0,strlen(argv[4])+i);
          }
        }
      }
      fwrite(c,8,1,f2);
      fwrite(hs,sizeof(W3dHLodSubObjectStruct),1,f2);
      break;
    case W3D_CHUNK_BOX:
      fread(b,sizeof(W3dBoxStruct),1,f);
      if (strncmp(b->Name,oldname2,strlen(argv[3])) == 0) {
        i = 0;
        if (strchr(b->Name,'.') != 0) {
          i = strlen(strstr(b->Name,"."));
          strncpy(b->Name+strlen(argv[3]),b->Name+strlen(argv[4]),i);
        }
        strncpy(b->Name,newname2,strlen(argv[4]));
        _strnset(b->Name+strlen(argv[4])+i,0,strlen(argv[4])+i);
      } else {
        if (strchr(b->Name,'.') != 0) {          
          st = strstr(b->Name,oldname2);
          if (st != 0) {
            i = b->Name - st;
            strncpy(b->Name+i,newname2,strlen(argv[4]));
            _strnset(b->Name+i+strlen(argv[4]),0,strlen(argv[4])+i);
          }
        }
      }
      fwrite(c,8,1,f2);
      fwrite(b,sizeof(W3dBoxStruct),1,f2);
      break;
    case W3D_CHUNK_DAZZLE_NAME:
      text=new char[c->size*2];
      fread(text,c->size,1,f);
      if (strncmp(text,oldname2,strlen(argv[3])) == 0) {
        i = 0;
        if (strchr(text,'.') != 0) {
          i = strlen(strstr(text,"."));
          strncpy(text+strlen(argv[3]),text+strlen(argv[4]),i);
        }
        strncpy(text,newname2,strlen(argv[4]));
        int x=c->size;
        c->size=c->size-strlen(argv[3])+strlen(argv[4]);
        if (c->size > x) {
          printf("error, name too long");
          exit(1);
        }
      } else {
        if (strchr(text,'.') != 0) {          
          st = strstr(text,oldname2);
          if (st != 0) {
            i = text - st;
            strncpy(text+i,newname2,strlen(argv[4]));
            int x=c->size;
            c->size=c->size-strlen(argv[3])+strlen(argv[4]);
            if (c->size > x) {
              printf("error, name too long");
              exit(1);
            }
          }
        }
      }
      fwrite(c,8,1,f2);
      fwrite(text,c->size,1,f2);
      break;
    case W3D_CHUNK_DAZZLE_TYPENAME:
      text=new char[c->size*2];
      fread(text,c->size,1,f);
      if (stricmp(text,argv[3]) == 0) {
        text = argv[4];
        int x=c->size;
        c->size=c->size-strlen(argv[3])+strlen(argv[4]);
        if (c->size > x) {
          printf("error, name too long");
          exit(1);
        }
      }
      fwrite(c,8,1,f2);
      fwrite(text,c->size,1,f2);
      break;
    case W3D_CHUNK_SOUNDROBJ_HEADER:
      fread(sr,sizeof(W3dSoundRObjHeaderStruct),1,f);
      if (stricmp(sr->Name,oldname) == 0) {
        sr->Name = newname;
      }
      fwrite(c,8,1,f2);
      fwrite(sr,sizeof(W3dSoundRObjHeaderStruct),1,f2);
      break;
    default:
      fwrite(c,8,1,f2);
      for(j=0;j<c->size;j++) {
         d = fgetc(f);
         fputc(d,f2);
      }
      break;
    }
  }
}

