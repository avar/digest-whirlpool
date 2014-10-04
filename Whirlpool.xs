#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include "upstream/Whirlpool.c"

typedef struct whirlpool {
    NESSIEstruct state;
}* Digest__Whirlpool;

MODULE = Digest::Whirlpool		PACKAGE = Digest::Whirlpool
PROTOTYPES: DISABLE

SV *
new(SV * class)
CODE:
    Digest__Whirlpool self;
    SV * self_ref;
    const char * pkg;

    /* Figure out what class we're supposed to bless into, handle
       $obj->new (for completeness) and Class->new  */
    if (SvROK(class)) {
        /* An object, get is type */
        pkg = sv_reftype(SvRV(class), TRUE);
    } else {
        /* If this function gets called as Pkg->new the value being passed is
         * a READONLY SV so we'll need a copy
         */
        pkg = SvPV(class, PL_na);
    }

    /* Allocate memory for Whirlpool's store and create an IV ref
       containing its memory location */
    Newz(0, self, 1, struct whirlpool);
    NESSIEinit(&self->state);
    self_ref = newRV_noinc((SV *) self);

    RETVAL = newSV(0); /* This gets mortalized automagically */
    sv_setref_pv(RETVAL, pkg, (void*)self);
OUTPUT:
    RETVAL

Digest::Whirlpool
clone(self)
    Digest::Whirlpool self
    CODE:
        Newz(0, RETVAL, 1, struct whirlpool);
        Copy(&self->state, &RETVAL->state, 1, struct whirlpool);
    OUTPUT:
        RETVAL

int
hashsize(...)
    CODE:
        RETVAL = 512;
    OUTPUT:
        RETVAL

Digest::Whirlpool
reset(self)
    Digest::Whirlpool self
    CODE:
        NESSIEinit(&self->state);
        
Digest::Whirlpool
add(self, ...)
    Digest::Whirlpool self
    CODE:
    {
        STRLEN len;
        unsigned char* data;
        unsigned int i;

        for (i = 1; i < items; i++) {
            data = (unsigned char*)(SvPV(ST(i), len));
            NESSIEadd(data, len << 3, &self->state);
        }
    }

SV*
digest(self)
    Digest::Whirlpool self
    CODE:
    {
        /* A bit (tr)?icky, makes sure the SvPV is 64 bytes then grabs
           its char* part and writes directly to it */
        RETVAL = newSVpvn("", 64);
        NESSIEfinalize(&self->state, SvPVX(RETVAL));
        NESSIEinit(&self->state);
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Digest::Whirlpool self
    CODE:
        Safefree(self);

