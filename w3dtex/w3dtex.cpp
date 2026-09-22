#include "dds.h"
#include "w3d_file.h"
#include <stdio.h>
#include <string.h>
#include "mix_rg.h"

#ifdef _MSC_VER
#paragma push(pack)
#endif
typedef struct _TGAHeader TGAHeader, *PTGAHeader;
struct _TGAHeader {
        byte   id_len;         /* image id length */
        byte   map_t;          /* color map type */
        byte   img_t;          /* image type */
        short  map_first;      /* index of first map entry */
        short  map_len;        /* number of entries in color map */
        byte   map_entry;      /* bit-depth of a cmap entry */
        short  x;              /* x-coordinate */
        short  y;              /* y-coordinate */
        short  width;          /* width of image */
        short  height;         /* height of image */
        byte   depth;          /* pixel-depth of image */
        byte   alpha;          /* alpha bits */
}
#ifdef __MINGW32__
__attribute__((packed))
#endif
;

int main(int argc,char *argv[])
{
   t_mix_rg_header mixhead;
   t_mix_rg_index_entry *indexhead;
   char **filenames;
   char **texturenames;
   int texturecount;
   int tc;
   int found;
   char c;
   chunk *cc = new chunk;
   int i,j;
   int filecount;
   byte stlen;
   if (argc < 2)
   {
      printf("w3dtex usage:\n");
      printf("w3dtex filename.mix filename.w3d\n");
      printf("w3dtex takes the name of a renegade mix file (*.mix, *.dat or *.pkg) and the\nname of a w3d file and extracts all textures referenced by that w3d file");
      exit(1);
   }
   FILE *mix = fopen(argv[1],"rb");
   fread(&mixhead,sizeof(t_mix_rg_header),1,mix);
   fseek(mix,mixhead.index_offset,SEEK_SET);
   fread(&filecount,4,1,mix);
   indexhead = new t_mix_rg_index_entry[filecount];
   fread(indexhead,sizeof(t_mix_rg_index_entry),filecount,mix);
   fseek(mix,mixhead.tailer_offset,SEEK_SET);
   fread(&filecount,4,1,mix);
   filenames = new char *[filecount];
   for (i=0;i<filecount;i++) {
      fread(&stlen,1,1,mix);
      filenames[i] = new char[stlen];
      fread(filenames[i],stlen,1,mix);
   }
   FILE *w3d = fopen(argv[2],"rb");
   texturecount = 0;
   while(!feof(w3d)) {
      fread(cc,8,1,w3d);
      if (cc->size < 1) {
          continue;
      }
      if (cc->type == W3D_CHUNK_TEXTURE_NAME) {
          texturecount++;
      }
      for(j=0;j<cc->size;j++) {
          c = fgetc(w3d);
      }
   }
   texturenames = new char*[texturecount];
   fclose(w3d);
   tc = 0;
   w3d = fopen(argv[2],"rb");
   while(!feof(w3d)) {
      fread(cc,8,1,w3d);
      if (cc->size < 1) {
          continue;
      }
      if (cc->type == W3D_CHUNK_TEXTURE_NAME) {
         texturenames[tc]=new char[cc->size];
         fread(texturenames[tc],cc->size,1,w3d);
         tc++;
      }
      else {
         for(j=0;j<cc->size;j++) {
             c = fgetc(w3d);
         }
      }
   }
   for (i=0;i<filecount;i++) {
      if (strstr(_strlwr(filenames[i]),".tga") != NULL) {
         found = 0;
         for(tc=0;tc<texturecount;tc++) {
             if(_stricmp(texturenames[tc],filenames[i]) == 0) {
                 found = 1;
             }
         }
         if(found == 1) {
             fseek(mix,indexhead[i].offset,SEEK_SET);
             FILE *tga = fopen(filenames[i],"wb");
             if (tga != NULL) {
                printf("now writing %s\n",filenames[i]);
                for(j=0;j<indexhead[i].size;j++) {
                   c = fgetc(mix);
                   fputc(c,tga);
                }
                fclose(tga);
             }
         }
      }
      if (strstr(_strlwr(filenames[i]),".dds") != NULL) {
         stlen = strlen(filenames[i]);
         filenames[i][stlen-3] = 't';
         filenames[i][stlen-2] = 'g';
         filenames[i][stlen-1] = 'a';
         found = 0;
         for(tc=0;tc<texturecount;tc++) {
             if(_stricmp(texturenames[tc],filenames[i]) == 0) {
                 found = 1;
             }
         }
         if(found == 1) {
             fseek(mix,indexhead[i].offset,SEEK_SET);
             FILE *tga = fopen(filenames[i],"wb");
             if (tga != NULL) {
                 printf("now writing %s\n",filenames[i]);
                 LPDDSURFACEDESC2 ddsd = new DDSURFACEDESC2;
                 char c;
                 c = fgetc(mix);
                 c = fgetc(mix);
                 c = fgetc(mix);
                 c = fgetc(mix);
                 fread(ddsd,sizeof(DDSURFACEDESC2),1,mix);
                 long size = indexhead[i].size - 4;
                 size -= sizeof(DDSURFACEDESC2);
                 PTGAHeader t = new TGAHeader;
                 t->id_len=0;
                 t->map_t=0;
                 t->img_t=2;
                 t->map_first=0;
                 t->map_len=0;
                 t->map_entry=0;
                 t->x=0;
                 t->y=0;
                 t->width=ddsd->dwWidth;
                 t->height=ddsd->dwHeight;
                 t->depth=32;
                 t->alpha=0x2F;
                 byte *ddsdata = new byte[size];
                 fread(ddsdata,size,1,mix);
                 long decompsize = ddsd->dwWidth * ddsd->dwHeight * 4;
                 byte *decompdata = new byte[decompsize];
                 byte *outdata = new byte[decompsize];
                 byte *dt = decompdata;
                 byte *ot = outdata;
                 decompdata = Decompress(*ddsd,ddsdata);
                 byte r,g,b,a;
                 for (int i=0;i<decompsize;i+=4) {
                     r = *decompdata++;
                     g = *decompdata++;
                     b = *decompdata++;
                     a = *decompdata++;
                     *ot++ = b;
                     *ot++ = g;
                     *ot++ = r;
                     *ot++ = a;
                 }
                 fwrite(t,18,1,tga);
                 fwrite(outdata,decompsize,1,tga);
                 delete ddsdata;
                 delete dt;
                 delete outdata;
                 fclose(tga);
             }
         }
       }
   }
   fclose(mix);
   delete indexhead;
   delete filenames;
   delete texturenames;
}

