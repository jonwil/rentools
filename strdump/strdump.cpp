#include <stdio.h>
#include "bittype.h"
enum {
TDB_CHUNK_STRINGHEADER = 0x6141108,
TDB_CHUNK_STRINGDATA = 0x614110A,
};
int main(int argc,char *argv[])
{
  chunk *c = new chunk;
  FILE *f;
  char d;
  char *text;
  int i,j,s;
  int fsize;
  uint16 x;
  uint32 u;
  if (argc < 2) {
    printf("usage:\nstrdump filename");
    exit(1);
  }
  f = fopen(argv[1],"rb");
  fseek(f,0,SEEK_END);
  fsize = ftell(f);
  fseek(f,0,SEEK_SET);
  s = 0;
  while(s<fsize) {
    fread(c,8,1,f);
    if (c->size < 1) {
      s += 8;
      continue;
    }
    s += c->size + 8;
    switch (c->type) {
    case 0x6141108:
      fread(&x,2,1,f);
      fread(&u,4,1,f);
      printf("%x ",u);
      fread(&x,2,1,f);
      fread(&u,4,1,f);
      fread(&x,2,1,f);
      fread(&u,4,1,f);
      fread(&d,1,1,f);
      fread(&d,1,1,f);
      text = new char[d];
      fread(text,d,1,f);
      printf("%s ",text);
      fread(&d,1,1,f);
      fread(&d,1,1,f);
      text = new char[d];
      fread(text,d,1,f);
      break;
    case 0x614110A:
      text = new char[c->size];
      for(j=0;j<c->size;j++) {
         text[j] = fgetc(f);
      }
      printf("%s\n",text);
      break;
    default:
      for(j=0;j<c->size;j++) {
         d = fgetc(f);
      }
      break;
    }
  }
}

