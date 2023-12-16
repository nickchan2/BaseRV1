CC = gcc
CFLAGS = -Wall -I include -std=c11
LD = gcc
LDLIBS = -lpthread

SRC_DIR = src
BUILD_DIR = build

SRCS=$(wildcard ${SRC_DIR}/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

TARGET = BaseRV1E

all: ${TARGET}

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

${TARGET}: $(OBJS)
	$(LD) -o $@ $^ $(LDLIBS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	rm -r ${BUILD_DIR} $(TARGET)
