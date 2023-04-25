CC = gcc 
CFLAGS = -g 
OBJS =  myuname.o
INCLUDES =
LIBS = #-l seccomp


all: myuname

myuname: ${OBJS}
	${CC} ${CFLAGS} ${INCLUDES} -o $@ ${OBJS} ${LIBS}


clean:
	rm -f *.o core *.core myuname