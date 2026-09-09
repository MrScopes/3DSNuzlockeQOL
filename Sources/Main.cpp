#include <3ds.h>
#include <cstring>

/*
 * 3DSNuzlockeQOL native plugin core.
 *
 * Game-specific addresses, title IDs, bag layout, item IDs, pocket addresses,
 * slot counts, and runtime timing are supplied automatically by Games/*.mk.
 *
 * Adding another game family normally only requires another Games/<NAME>.mk.
 */

#ifndef EXP_CALLSITE
    #error "Missing game configuration: EXP_CALLSITE"
#endif
#ifndef EXP_CODECAVE
    #error "Missing game configuration: EXP_CODECAVE"
#endif
#ifndef EXP_BRANCH
    #error "Missing game configuration: EXP_BRANCH"
#endif
#ifndef BAG_QUANTITY_SHIFT
    #error "Missing game configuration: BAG_QUANTITY_SHIFT"
#endif

static_assert(BAG_QUANTITY_SHIFT > 0 && BAG_QUANTITY_SHIFT < 32,
    "BAG_QUANTITY_SHIFT must be between 1 and 31");

alignas(8) static u8 g_threadStack[0x2000];
static Handle g_thread;

/*
 * EXP x0 hook used by XY/ORAS and SM/USUM:
 *   LDRH R0, [R0, #0x22]
 *   PUSH {R1, LR}
 *   MOV  R1, #0
 *   MUL  R0, R0, R1
 *   POP  {R1, PC}
 */
constexpr u32 EXP_ZERO_ROUTINE[] = {
    0xE1D002B2,
    0xE92D4002,
    0xE3A01000,
    0xE0000190,
    0xE8BD8002
};

constexpr u32 BAG_ITEM_MASK = (1u << BAG_QUANTITY_SHIFT) - 1u;

static void WriteCode(u32 address, const void *data, u32 size) {
    std::memcpy(reinterpret_cast<void *>(address), data, size);
    svcFlushProcessDataCache(CUR_PROCESS_HANDLE, address, size);
}

static void InstallExpZeroHook() {
    constexpr u32 branch = EXP_BRANCH;
    WriteCode(EXP_CODECAVE, EXP_ZERO_ROUTINE, sizeof(EXP_ZERO_ROUTINE));
    WriteCode(EXP_CALLSITE, &branch, sizeof(branch));
}

static constexpr u32 MakeBagEntry(u16 itemId) {
    return (static_cast<u32>(ITEM_QUANTITY) << BAG_QUANTITY_SHIFT) |
        (static_cast<u32>(itemId) & BAG_ITEM_MASK);
}

static constexpr u16 GetBagItemId(u32 entry) {
    return static_cast<u16>(entry & BAG_ITEM_MASK);
}

static constexpr u32 GetBagItemQuantity(u32 entry) {
    return entry >> BAG_QUANTITY_SHIFT;
}

static void EnsureBagItem(u32 pocketBase, u32 slotCount, u16 itemId) {
    volatile u32 *slots = reinterpret_cast<volatile u32 *>(pocketBase);
    s32 emptySlot = -1;

    for (u32 i = 0; i < slotCount; ++i) {
        const u32 entry = slots[i];
        const u16 id = GetBagItemId(entry);

        if (id == itemId) {
            if (GetBagItemQuantity(entry) != ITEM_QUANTITY)
                slots[i] = MakeBagEntry(itemId);
            return;
        }

        if (id == 0 && emptySlot < 0)
            emptySlot = static_cast<s32>(i);
    }

    if (emptySlot >= 0)
        slots[emptySlot] = MakeBagEntry(itemId);
}

static void MaintainItems() {
    EnsureBagItem(ITEM_RARE_CANDY_POCKET, ITEM_RARE_CANDY_SLOTS, ITEM_RARE_CANDY_ID);
    EnsureBagItem(ITEM_FULL_RESTORE_POCKET, ITEM_FULL_RESTORE_SLOTS, ITEM_FULL_RESTORE_ID);
    EnsureBagItem(ITEM_MAX_ELIXIR_POCKET, ITEM_MAX_ELIXIR_SLOTS, ITEM_MAX_ELIXIR_ID);
    EnsureBagItem(ITEM_MAX_REPEL_POCKET, ITEM_MAX_REPEL_SLOTS, ITEM_MAX_REPEL_ID);
    EnsureBagItem(ITEM_POKE_BALL_POCKET, ITEM_POKE_BALL_SLOTS, ITEM_POKE_BALL_ID);
}

static void PluginThread(void *arg) {
    (void)arg;

    svcSleepThread(STARTUP_DELAY_NS);
    InstallExpZeroHook();

    while (true) {
        MaintainItems();
        svcSleepThread(REFRESH_INTERVAL_NS);
    }
}

extern "C" int __entrypoint(int loaderArg) {
    (void)loaderArg;

    const Result rc = svcCreateThread(
        &g_thread,
        PluginThread,
        0,
        reinterpret_cast<u32 *>(g_threadStack + sizeof(g_threadStack)),
        0x30,
        0
    );

    (void)rc;
    return 0;
}
