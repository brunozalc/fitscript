CC = gcc
CFLAGS = -Wall -g

SRC_DIR = src
BUILD_DIR = build
OUTPUT_DIR = output

all: $(BUILD_DIR)/fitscript

$(BUILD_DIR)/fitscript.tab.c $(BUILD_DIR)/fitscript.tab.h: $(SRC_DIR)/fitscript.y
	bison -d $(SRC_DIR)/fitscript.y -o $(BUILD_DIR)/fitscript.tab.c

$(BUILD_DIR)/lex.yy.c: $(SRC_DIR)/fitscript.l $(BUILD_DIR)/fitscript.tab.h
	flex -o $(BUILD_DIR)/lex.yy.c $(SRC_DIR)/fitscript.l

$(BUILD_DIR)/fitscript: $(BUILD_DIR)/lex.yy.c $(BUILD_DIR)/fitscript.tab.c $(BUILD_DIR)/fitscript.tab.h
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/fitscript $(BUILD_DIR)/lex.yy.c $(BUILD_DIR)/fitscript.tab.c

clean:
	rm -rf $(BUILD_DIR)/* $(OUTPUT_DIR)/*

test: $(BUILD_DIR)/fitscript
	bash tests/test_vm.sh

.PHONY: all clean test
