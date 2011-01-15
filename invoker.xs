#include "EXTERN.h"
#include "perl.h"
#include "embed.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"

#include "hook_op_check.h"

#if PERL_REVISION == 5 && PERL_VERSION >= 13

#else

#define op_append_elem(a,b,c) Perl_append_elem(aTHX_ a,b,c)

#if PERL_REVISION == 5 && PERL_VERSION >= 12

#else
#define pad_findmy(a,b,c) Perl_pad_findmy(aTHX_ a)
#endif
#endif

typedef struct userdata_St {
    hook_op_check_id eval_hook;
    SV *class;
} userdata_t;

static OP *
invoker_ck_gt(pTHX_ OP *o, void *ud) {
    OP *left = cBINOPo->op_first; /* $- */
    OP *right = left->op_sibling; /* the entersub */
    
    if (left->op_type == OP_RV2SV) {
        GV *gv;
        left = cUNOPx(left)->op_first;
        if (left->op_type == OP_GV &&
            (gv = cGVOPx_gv(left)) &&
            !strcmp(GvNAME_get(gv), "-")) {
	    const PADOFFSET tmp = pad_findmy("$self", 5, 0);
            if (tmp == -1) {
                croak("$self not found");
            }
            else {
                OP * const self = newOP(OP_PADSV, 0);
                self->op_targ = tmp;
                //warn("right: %p %s. self = %d", right, PL_op_name[right->op_type], tmp);
                if (right->op_type == OP_ENTERSUB) {
                    OP *f = ((cUNOPx(right)->op_first->op_sibling)
                           ? cUNOPx(right) : ((UNOP*)cUNOPx(right)->op_first))->op_first; // pushmark
                    OP *o2 = f->op_sibling; // the actual first argument
                    
                    // warn("right first: %p %s", f, PL_op_name[f->op_type]);
                    // warn("right 2: %p %s", o2, PL_op_name[o2->op_type]);

                    self->op_sibling = o2;
                    f->op_sibling = self;

                    OP *last_arg = o2->op_type == OP_NULL ? f : o2;
                    while(last_arg->op_sibling->op_sibling)
                        last_arg = last_arg->op_sibling;

                    // warn("last_arg: %p %s", last_arg, PL_op_name[last_arg->op_type]);

                    OP *apply = cUNOPx(last_arg->op_sibling)->op_first;
                    // warn("apply: %p %s", apply, PL_op_name[apply->op_type]);
                    if (apply->op_type == OP_GV) {
                        SV *sv = newSVpv(GvNAME_get(cGVOPx_gv(apply)), 0);
                        const char *foo = GvNAME_get(cGVOPx_gv(apply));
                        OP *cmop = newSVOP(OP_METHOD_NAMED, 0, sv);
                        last_arg->op_sibling = cmop;
                    }
                    else {
                        warn("unknown application: %s", PL_op_name[apply->op_type]);
                        return o;
                    }

                    // warn("self next = %p %s", self->op_next, PL_op_name[self->op_next->op_type]);

                    return right;
                }
                else if (right->op_type == OP_CONST) {
                    SV *name = ((SVOP*)right)->op_sv;
                    o = (OP *)newUNOP(OP_ENTERSUB, OPf_STACKED,
                                      op_append_elem(OP_LIST, self,
                                                  newSVOP(OP_METHOD_NAMED, 0, name)));
                    return o;
                }
                else {
                    SV *sv = ((SVOP*)right)->op_sv;
                    o = (OP *)newUNOP(OP_ENTERSUB, OPf_STACKED,
                                      op_append_elem(OP_LIST, self,
                                                  newUNOP(OP_METHOD, 0, right)));
                    return o;
                }
            }
        }
    }
    return o;
}


MODULE = invoker	PACKAGE = invoker
PROTOTYPES: ENABLE

hook_op_check_id
setup (class)
        SV *class;
    PREINIT:
        userdata_t *ud;
    INIT:
        Newx (ud, 1, userdata_t);
    CODE:
        ud->class = newSVsv (class);
        RETVAL = hook_op_check (OP_GT, invoker_ck_gt, ud);
    OUTPUT:
        RETVAL

void
teardown (class, hook)
        hook_op_check_id hook
    PREINIT:
        userdata_t *ud;
    CODE:
        ud = (userdata_t *)hook_op_check_remove (OP_GT, hook);
        if (ud) {
            SvREFCNT_dec (ud->class);
            Safefree (ud);
        }
