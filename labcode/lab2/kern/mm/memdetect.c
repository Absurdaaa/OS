#include <memdetect.h>
#include <stdio.h>
#include <defs.h>
#include <riscv.h>
#include <memlayout.h>
#include <mmu.h>

// Memory test pattern
#define MEMORY_TEST_PATTERN  0x1234567890ABCDEF

// Simple memory test function
static int test_memory_access(uintptr_t phys_addr) {
    volatile uint64_t *test_addr;
    uint64_t original_value, read_value;

    // Basic sanity check
    if (phys_addr < DRAM_BASE) {
        return 0;
    }

    // Map physical address to virtual address using direct mapping
    test_addr = (volatile uint64_t *)(phys_addr + PHYSICAL_MEMORY_OFFSET);

    // Test read
    original_value = *test_addr;

    // Test write
    *test_addr = MEMORY_TEST_PATTERN;
    read_value = *test_addr;

    // Restore original value
    *test_addr = original_value;

    // Check if write was successful
    return (read_value == MEMORY_TEST_PATTERN);
}

// Detect physical memory range by iterative probing
void detect_physical_memory_range(void) {
    cprintf("=== Physical Memory Detection Start ===\n");

    // Start with minimum memory size and iteratively double it
    uintptr_t current_size = 8 * 1024 * 1024;  // Start with 8MB
    uintptr_t max_size = 1024 * 1024 * 1024;   // Upper limit: 1GB
    uintptr_t detected_size = 0;
    int iteration = 0;

    cprintf("Iterative memory detection (doubling approach)...\n");
    cprintf("Starting from %dMB, maximum test size: %dMB\n\n",
            current_size / (1024 * 1024), max_size / (1024 * 1024));

    while (current_size <= max_size && iteration < 10) {  // Limit iterations to prevent infinite loop
        uintptr_t test_addr = DRAM_BASE + current_size - PGSIZE;

        cprintf("Iteration %d: Testing %dMB at address 0x%016lx... ",
                iteration + 1, current_size / (1024 * 1024), test_addr);

        if (test_memory_access(test_addr)) {
            cprintf("OK\n");
            detected_size = current_size;

            // Try the next size boundary (double the current size)
            // Align to page size boundary for next test
            current_size = (current_size * 2);
            current_size = (current_size + PGSIZE - 1) & ~(PGSIZE - 1);  // Round up to page boundary
            iteration++;
        } else {
            cprintf("FAILED\n");
            cprintf("Memory boundary detected between %dMB and %dMB\n",
                    detected_size / (1024 * 1024), current_size / (1024 * 1024));
            break;
        }
    }

    // If no memory was detected at all, use conservative estimate
    if (detected_size == 0) {
        cprintf("No memory detected during iterative probing, using conservative estimate of 4MB\n");
        detected_size = 4 * 1024 * 1024;
    } else if (iteration >= 10) {
        cprintf("Maximum iteration limit reached, detected size may be incomplete\n");
    }

    // Perform binary search refinement for more accurate boundary detection
    if (detected_size > 8 * 1024 * 1024) {  // Only refine if we found more than 8MB
        cprintf("\nRefining memory boundary with binary search...\n");

        uintptr_t lower_bound = detected_size / 2;  // Last known good size
        uintptr_t upper_bound = detected_size;      // First known bad size

        while (upper_bound - lower_bound > PGSIZE) {
            uintptr_t mid_size = (lower_bound + upper_bound) / 2;
            uintptr_t test_addr = DRAM_BASE + mid_size - PGSIZE;

            cprintf("  Testing refined boundary: %dMB at 0x%016lx... ",
                    mid_size / (1024 * 1024), test_addr);

            if (test_memory_access(test_addr)) {
                cprintf("OK\n");
                lower_bound = mid_size;
            } else {
                cprintf("FAILED\n");
                upper_bound = mid_size;
            }
        }

        detected_size = lower_bound;
        cprintf("Refined memory size: %dMB\n", detected_size / (1024 * 1024));
    }

    // Output detected memory information
    cprintf("\n=== Physical Memory Detection Results ===\n");
    cprintf("Detection Method: Iterative probing with binary search refinement\n");
    cprintf("Detected Memory Base: 0x%016lx\n", DRAM_BASE);
    cprintf("Detected Memory End: 0x%016lx\n", DRAM_BASE + detected_size - 1);
    cprintf("Detected Memory Size: 0x%016lx (%d MB)\n",
            detected_size, detected_size / (1024 * 1024));
    cprintf("Total pages detected: %d\n", detected_size / PGSIZE);
    cprintf("Detection iterations completed: %d\n", iteration);
    cprintf("=== Physical Memory Detection Complete ===\n");
}