CXX = g++ -std=c++20
CXXFLAGS = -Wall -g -MMD  # use -MMD to generate dependencies
SOURCES = $(wildcard *.cpp)   # list of all .cpp files in the current directory
OBJECTS = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(SOURCES))  # .o files in build directory
DEPENDS = $(OBJECTS:.o=.d)   # .d file is list of dependencies for corresponding .cpp file
EXEC = pq1
TEST_RUNNER = test_runner

BUILD_DIR = ./build

# Create build directory if it doesn't exist
$(shell mkdir -p $(BUILD_DIR))

# First target in the makefile is the default target.
$(EXEC): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(OBJECTS) -o $(BUILD_DIR)/$(EXEC) $(LIBFLAGS)

$(BUILD_DIR)/%.o: %.cpp
	$(CXX) -c -o $@ $< $(CXXFLAGS) $(LIBFLAGS)

-include $(DEPENDS)

.PHONY: clean run test debug valgrind

clean:
	rm -f $(BUILD_DIR)/*.o $(BUILD_DIR)/*.d $(BUILD_DIR)/$(EXEC)

run: $(EXEC)
	@echo "Running the executable..."
	./$(BUILD_DIR)/$(EXEC)

debug: $(EXEC)
	@echo "Running with gdb..."
	gdb ./$(BUILD_DIR)/$(EXEC)

valgrind: $(EXEC)
	@echo "Running with valgrind..."
	valgrind ./$(BUILD_DIR)/$(EXEC)


clean-tests:
	@./run_tests.sh clean

test:
	@./run_tests.sh run
