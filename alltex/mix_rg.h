#define __int32 long
struct t_mix_rg_header
{
	__int32 id;
	__int32 index_offset;
	__int32 tailer_offset;
	__int32 zero;
};

struct t_mix_rg_index_entry
{
	__int32 id;
	__int32 offset;
	__int32 size;
};

const int mix_rg_id = 0x4D495831;
