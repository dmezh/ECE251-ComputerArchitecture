/*	ECE251-Computer Architecture
            Daniel Mezhiborsky
	       Prof. Billoo
		Calculator

filename: calc.c - Generic C implementation of 5-function PEMDAS calculator (+,-,*,/,^)

*/

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

void badInputExit();
void eval_single();
void parensexit();
void tooManyOpsExit();

double operands[5] = {0.0,0.0,0.0,0.0,0.0};	//operands stack
char operators[5];	//operators stack
int operand_count=-1;
int operator_count=-1;
int offset;
int lastType=-1;
int next_negative=0;
int operations_count=0;

int main(int argc, char *argv[]) {
	char *input = argv[1];

//	printf("%c\n", *argv[1]);
	if (argc!=2) {
		printf("Error! Invalid number of arguments. Please put your expression in quotes!");
		exit(9);
	}
	while(1) {
		//COND 1
		if (*input==0) break;
		//COND 2
		if (*input==' ') {
			input++;
			continue;
		}
		//COND 3
		else if (*input=='.' || (*input>='0' && *input<='9')) {
			operand_count++;
			if ((sscanf(input, "%lf%n", &operands[operand_count], &offset) != 1)) {
				printf("oof\n");
			}
			if (next_negative==1) {
				operands[operand_count]=-operands[operand_count];
				next_negative=0;
			}
			lastType=1;
			input += offset;
			continue;
		}
		//COND 4
		else if (*input=='(') {
			input++;
			operator_count++;
			operators[operator_count]='(';
			lastType=0;
			continue;
		}
		//COND 5
		else if (*input==')') {
			while (operators[operator_count] != '(') {
				if (operator_count==-1) parensexit();
				eval_single();
			}
			operator_count--;
			input++;
		}
		//COND 6
		else if (*input=='-' && lastType<1 && next_negative==0) {
			next_negative=1;
			input++;
			continue;
		}
		//COND 7
		else if (operations_count==4) {
			printf("Max 4 operations allowed, stopping early at %d\n", (int)(input-argv[1]));
			break;
		}
		//COND 8
		else if (lastType<1) badInputExit(argv[1], input);

		//COND 9
		else if (*input=='+'||*input=='-') {
			while(operator_count!=-1 && operators[operator_count]!='(') {
				eval_single();
			}
			operator_count++;
			operations_count++;
			operators[operator_count]=*input;
			input++;
			lastType=0;
			continue;
		}
		else if (*input=='/'||*input=='*') {
			while(operator_count!=-1 && (operators[operator_count]!='+' && operators[operator_count]!='-') && operators[operator_count]!='(') {
			eval_single();
			}
			operator_count++;
			operations_count++;
			operators[operator_count]=*input;
			input++;
			lastType=0;
			continue;
		}
		else if (*input=='^') {
			operator_count++;
			operations_count++;
			operators[operator_count]='^';
			input++;
			lastType=0;
			continue;
		}
		else badInputExit(argv[1], input);		//means the input is unrecognized
	}
	if (lastType<1 /*operators[operator_count]!='('*/) badInputExit(argv[1], input-1);
	while(operator_count!=-1) eval_single();
	printf("%lf\n", operands[0]);
}

void badInputExit(char* full, char* input) {
	printf("Error! Invalid input: %s\n", full);
	printf("%*c\n", input-full+23, '^');
	exit(1);
}

void parensexit() {
	printf("Error: mismatched parentheses!\n");
	exit(2);
}

void tooManyOpsExit() {
	printf("Error: Input too long; too many operations (max 4).\n");
	exit(3);
}

void eval_single() {
	char op = operators[operator_count];
	if (op=='(') parensexit();
	double op1 = operands[operand_count-1];
	double op2 = operands[operand_count];
	operands[operand_count] = 0.0;
	switch (op) {
		case '+':
			operands[operand_count-1] = op1 + op2; break;
		case '-':
			operands[operand_count-1] = op1 - op2; break;
		case '/':
			operands[operand_count-1] = op1 / op2; break;
		case '*':
			operands[operand_count-1] = op1 * op2; break;
		case '^':
			operands[operand_count-1] = pow(op1, op2); break;
		default:
			break;
	}
	operand_count--;
	operator_count--;
}
