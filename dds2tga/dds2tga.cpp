#include "dds.h"
#include <stdio.h>

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
   if (argc < 2)
   {
      printf("dds2tga usage:\n");
      printf("dds2tga filename.dds filename.tga\n");
      printf("dds2tga converts a .dds file (currently supporting types 1,3 and 5)\n");
      printf("to a .tga file\n");
      exit(1);
   }
   FILE *dds = fopen(argv[1],"rb");
   FILE *tga = fopen(argv[2],"wb");
   LPDDSURFACEDESC2 ddsd = new DDSURFACEDESC2;
   char c;
   c = fgetc(dds);
   c = fgetc(dds);
   c = fgetc(dds);
   c = fgetc(dds);
   fread(ddsd,sizeof(DDSURFACEDESC2),1,dds);
   long pos = ftell(dds);
   fseek(dds,0,SEEK_END);
   long size = ftell(dds);
   size = size - pos;
   fseek(dds,pos,SEEK_SET);
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
   fread(ddsdata,size,1,dds);
   long decompsize = ddsd->dwWidth * ddsd->dwHeight * 4;
   byte *decompdata = new byte[decompsize];
   byte *outdata = new byte[decompsize];
   byte *dt = decompdata;
   byte *ot = outdata;
   decompdata = Decompress(*ddsd,ddsdata);
   byte r,g,b,a;
   for (int i=0;i<decompsize;i+=4)
   {
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
   return 0;
}

