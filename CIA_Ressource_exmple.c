#include <exec/types.h>
#include <exec/exec.h>
#include <exec/interrupts.h>
#include <hardware/cia.h>
#include <resources/cia.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <dos/dostags.h>
#include <stdio.h>
#include <string.h>

//===========================================================================
// Application Constants
//===========================================================================

#define APP_NAME            "XMouse CIA Test"
#define APP_VERSION         "0.1-cia"
#define APP_AUTHOR          "ReddoC"

//===========================================================================
// CIA Timer Setup
//===========================================================================

#define COUNTDOWN           2000    // CIA countdown value (lower = faster ticks)
#define HICOUNT             (COUNTDOWN >> 8)
#define LOCOUNT             (COUNTDOWN & 0xFF)

// Stop masks for control registers
#define STOPA_AND           (CIACRAF_TODIN | CIACRAF_PBON | CIACRAF_OUTMODE | CIACRAF_SPMODE)
#define STOPB_AND           (CIACRBF_ALARM | CIACRBF_PBON | CIACRBF_OUTMODE)

// Start masks
#define STARTA_OR           CIACRAF_START
#define STARTB_OR           CIACRBF_START

//===========================================================================
// Global State
//===========================================================================

struct ExecBase *SysBase;
struct DosLibrary *DOSBase;
static struct Library *CIABase = NULL;
static struct Interrupt CIAInt;
static struct Task *MainTask = NULL;
static ULONG TickSignal = 0;
static volatile ULONG TickCount = 0;

static struct CIA *CIAChip = NULL;
static UBYTE *CIACr = NULL;
static UBYTE *CIALo = NULL;
static UBYTE *CIAHi = NULL;
static UBYTE StopMask = 0;
static UBYTE StartMask = 0;

//===========================================================================
// Interrupt Handler (Assembly-like in C)
//===========================================================================

/**
 * CIA interrupt handler - called when timer counts down.
 * A1 = pointer to TickCount
 */
static void __asm CIATickHandler(register __a1 volatile ULONG *tickptr)
{
    (*tickptr)++;
    Signal(MainTask, TickSignal);
    
    // Restart timer
    *CIALo = LOCOUNT;
    *CIAHi = HICOUNT;
}

//===========================================================================
// CIA Timer Functions
//===========================================================================

/**
 * Try to allocate a CIA timer (either A or B on given CIA).
 * Returns TRUE if successful.
 */
static BOOL AllocCIATimer(struct Library *ciabase, struct CIA *cia, 
                          ULONG timerbit, UBYTE *stopmask, UBYTE *startmask)
{
    // Try to allocate the timer
    if (!AddICRVector(ciabase, timerbit, &CIAInt))
    {
        // Success - now set up pointers based on which timer
        if (timerbit == CIAICRB_TA)
        {
            CIACr = &cia->ciacra;
            CIALo = &cia->ciatalo;
            CIAHi = &cia->ciatahi;
            *stopmask = STOPA_AND;
            *startmask = STARTA_OR;
        }
        else
        {
            CIACr = &cia->ciacrb;
            CIALo = &cia->ciatblo;
            CIAHi = &cia->ciatbhi;
            *stopmask = STOPB_AND;
            *startmask = STARTB_OR;
        }
        
        CIAChip = cia;
        CIABase = ciabase;
        
        Printf("CIA Timer allocated (bit 0x%lx)\n", timerbit);
        return TRUE;
    }
    
    return FALSE;
}

/**
 * Find and allocate a free CIA timer (tries CIA-A first, then CIA-B).
 */
static BOOL FindFreeCIATimer(void)
{
    struct Library *ciaabase, *ciabbase;
    struct CIA *ciaa = (struct CIA *)0xbfe001;
    struct CIA *ciab = (struct CIA *)0xbfd000;
    UBYTE dummy_stop, dummy_start;
    
    // Open CIA resource bases
    ciaabase = OpenResource("ciaa.resource");
    ciabbase = OpenResource("ciab.resource");
    
    if (!ciaabase || !ciabbase)
    {
        Printf("Failed to open CIA resource\n");
        return FALSE;
    }
    
    // Try CIA-A Timer A
    if (AllocCIATimer(ciaabase, ciaa, CIAICRB_TA, &StopMask, &StartMask))
        return TRUE;
    
    // Try CIA-A Timer B
    if (AllocCIATimer(ciaabase, ciaa, CIAICRB_TB, &StopMask, &StartMask))
        return TRUE;
    
    // Try CIA-B Timer A
    if (AllocCIATimer(ciabbase, ciab, CIAICRB_TA, &StopMask, &StartMask))
        return TRUE;
    
    // Try CIA-B Timer B
    if (AllocCIATimer(ciabbase, ciab, CIAICRB_TB, &StopMask, &StartMask))
        return TRUE;
    
    Printf("No CIA timer available\n");
    return FALSE;
}

/**
 * Start the CIA timer.
 */
static void StartCIATimer(void)
{
    // Stop timer (clear START bit, set continuous mode)
    Disable();
    *CIACr &= StopMask;
    Enable();
    
    // Load countdown values
    *CIALo = LOCOUNT;
    *CIAHi = HICOUNT;
    
    // Start timer
    Disable();
    *CIACr |= StartMask;
    Enable();
    
    Printf("CIA Timer started (countdown=%ld)\n", COUNTDOWN);
}

/**
 * Stop the CIA timer.
 */
static void StopCIATimer(void)
{
    if (CIACr)
    {
        Disable();
        *CIACr &= StopMask;
        Enable();
    }
    
    if (CIABase)
        RemICRVector(CIABase, CIAICRB_TA, &CIAInt);
    
    Printf("CIA Timer stopped\n");
}

//===========================================================================
// Main
//===========================================================================

int main(int argc, char **argv)
{
    ULONG lastTick = 0;
    ULONG signals;
    int i;
    
    SysBase = *(struct ExecBase **)4L;
    DOSBase = (struct DosLibrary *)OpenLibrary("dos.library", 36);
    
    if (!DOSBase)
    {
        Printf("Failed to open dos.library\n");
        return RETURN_FAIL;
    }
    
    Printf("%s v%s\n", APP_NAME, APP_VERSION);
    Printf("Testing CIA interval timer for XMouse polling\n\n");
    
    // Set up main task for signal
    MainTask = FindTask(NULL);
    TickSignal = AllocSignal(-1);
    
    if (TickSignal == -1)
    {
        Printf("Failed to allocate signal\n");
        CloseLibrary((struct Library *)DOSBase);
        return RETURN_FAIL;
    }
    
    // Set up interrupt structure
    CIAInt.is_Node.ln_Type = NT_INTERRUPT;
    CIAInt.is_Node.ln_Pri = 0;
    CIAInt.is_Node.ln_Name = "xmouse_cia_test";
    CIAInt.is_Data = (APTR)&TickCount;
    CIAInt.is_Code = (APTR)CIATickHandler;
    
    // Find and allocate CIA timer
    if (!FindFreeCIATimer())
    {
        Printf("Failed to allocate CIA timer\n");
        FreeSignal(TickSignal);
        CloseLibrary((struct Library *)DOSBase);
        return RETURN_FAIL;
    }
    
    // Start timer
    StartCIATimer();
    
    Printf("Running for 10 ticks... Press CTRL+C to stop\n\n");
    
    // Wait for ticks
    for (i = 0; i < 10; i++)
    {
        signals = Wait(TickSignal | SIGBREAKF_CTRL_C);
        
        if (signals & SIGBREAKF_CTRL_C)
        {
            Printf("\nInterrupted\n");
            break;
        }
        
        if (signals & TickSignal)
        {
            Printf("Tick %lu (delta from last: %lu)\n", TickCount, TickCount - lastTick);
            lastTick = TickCount;
            SetSignal(0L, TickSignal);  // Clear signal for next tick
        }
    }
    
    Printf("\nTotal ticks: %lu\n", TickCount);
    
    // Cleanup
    StopCIATimer();
    FreeSignal(TickSignal);
    CloseLibrary((struct Library *)DOSBase);
    
    Printf("Done\n");
    return RETURN_OK;
}
