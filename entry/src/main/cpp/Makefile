CC = gcc
AR = ar
CFLAGS = -Wextra -Wpedantic -D PRINTLOG #-Wall
LDFLAGS = -lm -lGLESv2 -lEGL -lpthread
LIBNAME = libglwrapper.a
OBJDIR = ./build
INCDIR = ./build/include
LIBDIR = ./build/lib

SRCS = $(wildcard *.cpp)
HDRS = $(wildcard *.h)
OBJS = $(patsubst %.cpp,$(OBJDIR)/%.o,$(SRCS))

all: $(OBJDIR)/$(LIBNAME)

$(OBJDIR)/$(LIBNAME): $(OBJS)
	$(AR) rcs $@ $^
	cp $(OBJDIR)/$(LIBNAME) $(LIBDIR)/
	cp $(HDRS) $(INCDIR)/

$(OBJDIR)/%.o: %.cpp $(HDRS)
	@mkdir -p $(OBJDIR)
	@mkdir -p $(INCDIR)
	@mkdir -p $(LIBDIR)
	$(CC) $(CFLAGS) -I. -c $< -o $@  $(LDFLAGS)

clean:
	rm -f $(OBJDIR)/*.o $(OBJDIR)/$(LIBNAME)
	rm -f $(OBJDIR)/lib/$(LIBNAME)
	rm -f $(INCDIR)/*.h