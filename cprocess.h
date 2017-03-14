
int NEW = 0;
int READY = 1;
int RUNNING = 2;
int BLOCKED = 3;
int EXIT = 4;

#define MAXPROGRESS 8


int Program_Num;

typedef struct RegisterImage{
	int SS;
	int ES;
	int DS;
	int DI;
	int SI;
	int BP;
	int SP;
	int BX;
	int DX;
	int CX;
	int AX;
	int IP;
	int CS;
	int FLAGS;
}RegisterImage;

typedef struct PCB{
	RegisterImage regImg;
	int Process_Status;
	int FID;
}PCB;


PCB pcb_list[8];
int CurrentPCBno = 0; 


void check()
{
	put_char('0'+CurrentPCBno, 15, CurrentPCBno*2);
}

void init(PCB* pcb,int segement, int offset)
{
	pcb->regImg.SS = segement;
	pcb->regImg.ES = segement;
	pcb->regImg.DS = segement;
	pcb->regImg.CS = segement;
	pcb->regImg.IP = offset;
	pcb->regImg.SP = offset - 4;
	pcb->regImg.AX = 0;
	pcb->regImg.BX = 0;
	pcb->regImg.CX = 0;
	pcb->regImg.DX = 0;
	pcb->regImg.DI = 0;
	pcb->regImg.SI = 0;
	pcb->regImg.BP = 0;
	pcb->regImg.FLAGS = 512;
	pcb->Process_Status = NEW;
	pcb->FID = 0;
}


void init_pro()
{
	init(&pcb_list[0],0x1000,0x100);
	init(&pcb_list[1],0x2000,0x100);
	init(&pcb_list[2],0x3000,0x100);
	init(&pcb_list[3],0x4000,0x100);
	init(&pcb_list[4],0x5000,0x100);
	init(&pcb_list[5],0x6000,0x100);
}

void Save_Process(int es,int ds,int di,int si,int bp,
		int sp,int dx,int cx,int bx,int ax,int ss,int ip,int cs,int flags)
{
	pcb_list[CurrentPCBno].regImg.AX = ax;
	pcb_list[CurrentPCBno].regImg.BX = bx;
	pcb_list[CurrentPCBno].regImg.CX = cx;
	pcb_list[CurrentPCBno].regImg.DX = dx;

	pcb_list[CurrentPCBno].regImg.DS = ds;
	pcb_list[CurrentPCBno].regImg.ES = es;
	pcb_list[CurrentPCBno].regImg.SS = ss;

	pcb_list[CurrentPCBno].regImg.IP = ip;
	pcb_list[CurrentPCBno].regImg.CS = cs;
	pcb_list[CurrentPCBno].regImg.FLAGS = flags;
	
	pcb_list[CurrentPCBno].regImg.DI = di;
	pcb_list[CurrentPCBno].regImg.SI = si;
	pcb_list[CurrentPCBno].regImg.SP = sp;
	pcb_list[CurrentPCBno].regImg.BP = bp;
}

void Schedule()
{
	if (pcb_list[CurrentPCBno].Process_Status != BLOCKED)
		pcb_list[CurrentPCBno].Process_Status = READY;

	CurrentPCBno++;
	if( CurrentPCBno > Program_Num )
		CurrentPCBno = 1;
		
	while (pcb_list[CurrentPCBno].Process_Status != READY)
	{
		CurrentPCBno++;
		if( CurrentPCBno > Program_Num )
			CurrentPCBno = 1;
	}

	if( pcb_list[CurrentPCBno].Process_Status != NEW )
		pcb_list[CurrentPCBno].Process_Status = RUNNING;
	return;
}

PCB* Current_Process()
{
	return &pcb_list[CurrentPCBno];
}

void special()
{
	if(pcb_list[CurrentPCBno].Process_Status==NEW)
		pcb_list[CurrentPCBno].Process_Status=RUNNING;
}

void do_fork()
{
	int idx, new_stack;
	Program_Num++;
	idx = Program_Num;
	
	if (idx <= MAXPROGRESS)
		pcb_list[idx].regImg.AX = 0;
	else
		pcb_list[idx].regImg.AX = -1;
	pcb_list[idx].regImg.BX = pcb_list[CurrentPCBno].regImg.BX;
	pcb_list[idx].regImg.CX = pcb_list[CurrentPCBno].regImg.CX;
	pcb_list[idx].regImg.DX = pcb_list[CurrentPCBno].regImg.DX;

	pcb_list[idx].regImg.DS = pcb_list[CurrentPCBno].regImg.DS;
	pcb_list[idx].regImg.ES = pcb_list[CurrentPCBno].regImg.ES;
	
	new_stack = (0x1000)*(idx+1);
	pcb_list[idx].regImg.SS = new_stack;
	memcopy(pcb_list[CurrentPCBno].regImg.SS, 0, new_stack, 0, 0x100);

	pcb_list[idx].regImg.IP = pcb_list[CurrentPCBno].regImg.IP;
	pcb_list[idx].regImg.CS = pcb_list[CurrentPCBno].regImg.CS;
	pcb_list[idx].regImg.FLAGS = pcb_list[CurrentPCBno].regImg.FLAGS;
	
	pcb_list[idx].regImg.DI = pcb_list[CurrentPCBno].regImg.DI;
	pcb_list[idx].regImg.SI = pcb_list[CurrentPCBno].regImg.SI;
	pcb_list[idx].regImg.SP = pcb_list[CurrentPCBno].regImg.SP;
	pcb_list[idx].regImg.BP = pcb_list[CurrentPCBno].regImg.BP;
	
	pcb_list[idx].Process_Status = READY;
	pcb_list[idx].FID = CurrentPCBno;
	/*put_str("FORK", 4, 6, 256*10+12);*/
}

void do_wait()
{
	pcb_list[CurrentPCBno].Process_Status = BLOCKED;
	Schedule();
}

void do_exit()
{
	pcb_list[pcb_list[CurrentPCBno].FID].Process_Status = READY;
	pcb_list[CurrentPCBno].Process_Status = EXIT;
	Schedule();
}