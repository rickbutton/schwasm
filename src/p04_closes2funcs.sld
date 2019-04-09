(define-library 
(p04_closes2funcs)
(import (scheme base))
(import (util))
(export p04_closes2funcs)
(begin

(define funcid (makeid "$$f"))

(define (close? x) (and (list? x) (eq? (car x) 'close)))

(define (slot? x) (and (list? x) (eq? (car x) 'slot)))
(define (param? x) (and (list? x) (eq? (car x) 'param)))
(define (bound? x) (or (slot? x) (param? x)))

(define (close->body x) (car (cdr x)))

(define (close->frees x) 
    (let* ((body (close->body x))
           (refers (filter refer-free? body))
           (bounds (filter bound? body))
           (mappings (map (lambda (p) (caddr p)) bounds))
           (closes (filter close? body))
           (refer-frees (map (lambda (r) (cons (refer->var r) (refer->mapping r))) refers))
           (close-frees (apply append (map (lambda (c) (close->frees c)) closes)))
           (without-bounds (filter (lambda (f) (not (member (cdr f) mappings))) close-frees)))
        ;refer-frees))
        (append refer-frees without-bounds)))

(define (mark-close x) 
    (let* ((body (close->body x)) (frees (close->frees x)))
        `(close ,(funcid) ,frees ,body)))
(define (mark-closes x)
    (let* ((mark-inst (lambda (inst) 
            (if (close? inst) (mark-close inst) inst))))
        (map mark-inst x)))

(define (refer-free? x) (and (list? x) (eq? (car x) 'refer) (eq? (cadr x) 'free)))
(define (refer->var x) (caddr x))
(define (refer->mapping x) (cadddr x))

(define (mclose->mapped x) (cadr x))
(define (mclose->frees x) (caddr x))
(define (mclose-frees->insts frees) 
    (map (lambda (f) `(free ,(car f) ,(cdr f))) frees))
(define (mclose->body x) (cadddr x))
(define (map-close x)
    `(referfunc ,(mclose->mapped x) ,(mclose->frees x)))
(define (map-inst x)
    (cond
        ((close? x) (map-close x))
        (else x)))
(define (map-insts x) (map map-inst x))

(define (close->func x)
    (let* ((lifted (lift-closures (mclose->body x) #f))
           (body (car lifted))
           (funcs (cdr lifted)))
    (cons `(func close ,(mclose->mapped x) ,@(mclose-frees->insts (mclose->frees x)) ,@body) funcs))) ; add frees from outer
(define (closes->funcs x) (apply append (map close->func x)))
(define (entry->func x) `(func open $$fentry ,@x))

(define (lift-closures x emit-outer-func)
    (let* ((marked   (mark-closes x))
           (closes   (filter close? marked))
           (mapped   (map-insts marked))
           (funcs    (closes->funcs closes))
           (entry    (entry->func mapped))
           (outer    `(,entry ,@(if (null? funcs) '() funcs))))
        (if emit-outer-func outer (cons mapped funcs))))

(define (p04_closes2funcs x)
        (lift-closures x #t))))