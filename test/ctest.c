
extern put_str();
extern fork();
extern wait0();
extern exit();

extern get_one();

void count_letter();

char str[] = "123456789";
char msg[] = "There are XX letters.";
int number_of_letters;


void test_main()
{
	int ch, pid;
	pid = fork();
	
	if (pid)
	{
		ch = wait0(); 
		msg[10] = number_of_letters/10+'0';
		msg[11] = number_of_letters%10+'0';
		put_str(msg, 21, 6, 256*5+10);
	}
	else
	{
		count_letter();
		exit(0);
	}
}

void count_letter()
{
	number_of_letters = 0;
	while (str[number_of_letters] != 0)
	{
		number_of_letters++;
	}
}