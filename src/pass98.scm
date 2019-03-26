(define-module (pass98)
    #:export (lift-closures))

(use-modules (util))

(define (close? x) (and (list? x) (eq? (car x) 'close)))
(define (close->body x) (car (cdr x)))
(define (mark-close x) `(close ,(gensym "$$f") ,(close->body x)))
(define (mark-closes x)
    (let* ((mark-inst (lambda (inst) 
            (if (close? inst) (mark-close inst) inst))))
        (map mark-inst x)))

(define (mclose->mapped x) (car (cdr x)))
(define (mclose->body x) (car (cdr (cdr x))))
(define (map-close x)
    `(referfunc ,(mclose->mapped x)))
(define (map-inst x)
    (cond
        ((close? x) (map-close x))
        (else x)))
(define (map-insts x) (map map-inst x))

(define (close->func x)
    (let* ((lifted (lift-closures (mclose->body x) #f))
           (body (car lifted))
           (funcs (cdr lifted)))
    (cons `(func ,(mclose->mapped x) ,@body) funcs)))
(define (closes->funcs x) (apply append (map close->func x)))
(define (entry->func x) `(func $$fentry ,@x))

(define (var? x) (and (list? x) (eq? (car x) 'var)))
(define (param? x) (and (list? x) (eq? (car x) 'params)))

(define (not-var-or-param? x) (and (not (var? x)) (not (param? x))))
(define (strip-var-and-param x) (filter not-var-or-param? x))

(define (lift-closures x emit-outer-func)
    (let* ((marked   (mark-closes x))
           (closes   (filter close? marked))
           (vars     (filter var? marked))
           (params   (filter param? marked))
           (mapped   (map-insts marked))
           (funcs    (closes->funcs closes))
           (entry    (entry->func mapped))
           (outer    `(,entry ,@(if (null? funcs) '() funcs))))
        (if emit-outer-func outer (cons mapped funcs))))