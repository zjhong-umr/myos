
#include "cprocess.h"

extern put_char();
extern put_str();
extern clear();
extern get_char();
extern get_time();

extern set_timer();

extern fopen();
extern run_file();

extern memcopy();

int curline=0;

char inputInfo[]="zos>                                                                             ";
#define INPUTLEN 80

char ch;
char ENDNOTE1[] = "ZOS now safely exit!";
char ENDNOTE2[] = "Thank you for using!";
char PROCESS[]  = "PRG1    COM";
char exec_name[]= "PRG1    COM";

int idx,status;
int i_cmd, j_cmd;

int Segment=0x2000;

commend()
{
	/*memcopy(0x9000, a, 0x9000, b, 6);
	put_str(b, 6, 15, 2560);*/
	Program_Num = 0;
	j_cmd = 5;
	while (j_cmd < INPUTLEN)
	{
		inputInfo[j_cmd] = ' ';
		j_cmd++;
	}
	j_cmd = 5;
	while (1)
	{
		init_pro();
		/* 输出 zos> */
		put_str(inputInfo, 5, 3, 256*curline);
		/* 输出已输入的字母 */
		put_str(inputInfo+5, j_cmd-5, 15, 256*curline+5);
		/* 处理光标位置 */
		put_str("", 0, j_cmd, 256*curline+j_cmd);			
		ch = get_char();
		if (ch == 13)
		{
			if (is_run())
			{
				if (out_of_run_length())
				{
					next_line();
					put_str("Program name too Long", 21, 6, 256*curline);
					reset();
					next_line();
				}
				else if (is_com())
				{
					i_cmd=9;
					translate_exec_name();
					next_line();
					reset();
					status = fopen(exec_name, 0x4000, 0x100);
					if (status == 0)
					{
						put_str("Program Not Found", 17, 6, 256*curline);
						reset();
						next_line();
					}
					else
					{
						curline = 21;
						reset();
						run_file(0x4000, 0x100);
					}
				}
				else
				{
					next_line();
					put_str("Program Format Not Supported", 28, 6, 256*curline);
					reset();
					next_line();
				}
			}
			else if (is_create())
			{
				i_cmd = inputInfo[12];
				next_line();
				if (i_cmd < '1' || i_cmd > '4')
				{
					put_str("Wrong Process Number", 21, 6, 256*curline);
				}
				else
				{
					if (Program_Num >= 4)
					{
						put_str("Create too many process!", 24, 6, 256*curline);
					}
					else
					{
						Program_Num++;
						PROCESS[3] = i_cmd;
						fopen(PROCESS, (Program_Num+1)*0x1000, 0x100);
						init(&pcb_list[Program_Num], (Program_Num+1)*0x1000, 0x100);
						put_str("Create a process Successfully", 29, 6, 256*curline);
					}
				}
				reset();
				next_line();
			}
			else if (is_start())
			{
				process_start();
			}
			else if (is_test())
			{
				Program_Num++;
				status = fopen("TEST    COM", (Program_Num+1)*0x1000, 0x100);
				init(&pcb_list[Program_Num], (Program_Num+1)*0x1000, 0x100);
				process_start();
			}
			else if (is_dir())
			{
				fopen("DIR     COM", 0x4000, 0x100);
				curline = 21;
				reset();
				run_file(0x4000, 0x100);
			}
			else if (is_help())
			{	
				next_line();
				show_guidence();
				reset();
			}
			else if (is_time())
			{
				next_line();
				show_time();
				next_line();
				reset();
			}
			else if (is_cls())
			{
				clear();
				reset();
				curline=0;
			}
			else if (j_cmd==5)
			{
				next_line();
			}
			else
			{
				next_line();
				put_str("Unrecognized Command", 20, 6, 256*curline);
				reset();
				curline++;
			}
		}
		else if (ch == 8)
		{
			j_cmd--;
			if (j_cmd < 5) j_cmd=5;
			inputInfo[j_cmd] = 0;
			put_str(0, 1, 15, 256*curline+j_cmd);
		}
		else
		{
			inputInfo[j_cmd]=ch;
			j_cmd++;
		}
	}
}

int is_run()
{
	return (j_cmd > 9 && inputInfo[5] == 'r' && inputInfo[6] == 'u'
				&& inputInfo[7] == 'n' && inputInfo[8] == ' ');
}

int out_of_run_length()
{
	return j_cmd >= 21;
}

int is_com()
{
	return (inputInfo[j_cmd-3] == 'c' || inputInfo[j_cmd-3] == 'C')
			&& (inputInfo[j_cmd-2] == 'o' || inputInfo[j_cmd-2] == 'O')
			&& (inputInfo[j_cmd-1] == 'm' || inputInfo[j_cmd-1] == 'M')
			&& inputInfo[j_cmd-4] == '.';
}

int is_dir()
{
	return j_cmd==8 && inputInfo[5] == 'd' 
			&& inputInfo[6] == 'i' && inputInfo[7] == 'r';
}

int is_help()
{
	return j_cmd==9 && inputInfo[5] == 'h' && inputInfo[6] == 'e'
			&& inputInfo[7] == 'l' && inputInfo[8] == 'p';
}

int is_start()
{
	return j_cmd==10 && inputInfo[5] == 's' && inputInfo[6] == 't'
			&& inputInfo[7] == 'a' && inputInfo[8] == 'r' && inputInfo[9] == 't';
}

int is_time()
{
	return j_cmd==9 && inputInfo[5] == 't' && inputInfo[6] == 'i'
			&& inputInfo[7] == 'm' && inputInfo[8] == 'e';
}

int is_create()
{
	return j_cmd==13 && inputInfo[5] == 'c' && inputInfo[6] == 'r'
			&& inputInfo[7] == 'e' && inputInfo[8] == 'a' && inputInfo[9] == 't' 
			&& inputInfo[10] == 'e' && inputInfo[11] == ' ';
}

int is_cls()
{
	return j_cmd==8 && inputInfo[5] == 'c' && inputInfo[6] == 'l'
			&& inputInfo[7] == 's';
}

int is_test()
{
	return j_cmd==9 && inputInfo[5] == 't' && inputInfo[6] == 'e'
			&& inputInfo[7] == 's' && inputInfo[8] == 't';
}

translate_exec_name()
{
	while (i_cmd < j_cmd-4)
	{exec_name[i_cmd-9] = inputInfo[i_cmd];i_cmd++;}
	while (i_cmd < 17)
	{exec_name[i_cmd-9]=' ';i_cmd++;}
	to_upper();
}

next_line()
{
	curline++;
	if (curline > 23)
	{
		clear();
		curline=0;
	}
}

/* 换行后重新设置光标等 */
reset()
{
	while (j_cmd>=5)
	{
		inputInfo[j_cmd] = 0;
		j_cmd--;
	}
	j_cmd++;
}

int i_to;
to_upper()
{
	i_to = 0;
	while (i_to < 11)
	{
		if (exec_name[i_to] >= 'a' && exec_name[i_to] <= 'z')
		{
			exec_name[i_to] += 'A' - 'a';
		}
		i_to++;
	}
}

/* 显示时间 */
int time;
show_time()
{
	time = get_time();
	put_char(time%16 + '0', 3, 2*(80*curline+4));
	time /= 16;
	put_char(time%16 + '0', 12, 2*(80*curline+3));
	time /= 16;
	put_char(':', 13, 2*(80*curline+2));
	put_char(time%16 + '0', 14, 2*(80*curline+1));
	time /= 16;
	put_char(time + '0', 15, 2*(80*curline+0));
}

int color;
show_guidence()
{
	if (curline >= 17)
	{
		clear();
		curline=0;
	}
	
	color = 3;
	put_str("Command dir to show the root directory", 38, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("Command run+program name to run a program like run hello.com", 61, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("commend batch to batch-run pragrams like \"batch 1234\" to run prg1,2,3,4", 71, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("Command time to show the current time", 37, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("Command cls to clean the screen", 31, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("commend create to create processes like \"create 1\" to create process1", 69, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("commend start to run all the processes you create", 49, color, curline*256);
	curline++;
	color = 8-color;
	
	put_str("Press ESC to exit OS safely", 27, color, curline*256);
	curline++;
	color = 8-color;
}

process_start()
{
	clear();
	put_str("Now you can press arbitrary 3 keys to exit the processes", 56, 12, 256*12+5);
	set_timer();
	while (ch != 27)
	{
		ch = get_char();
	}
	reset();
	curline=0;
	clear();
}



