(define-library 
    (p01_scheme2cps)
    (import (scheme base))
    (import (scheme write))
    (import (util))
    (export p01_scheme2cps)
(begin

(define (sfixnum? i) (integer? i))
(define (sboolean? b) (boolean? b))
(define (schar? c) (char? c))
(define (ssymbol? n) (symbol? n))
(define (snull? n) (null? n))

(define (satomic? x)
    (or
        (sfixnum? x)
        (sboolean? x)
        (schar? x)
        (ssymbol? x)
        (snull? x)))
(define (squote? x) (and (list? x) (eq? (car x) 'quote)))

(define prim-list '(add sub cons car cdr))
(define (sprim? x) (and (list? x) (contains? prim-list (car x))))

(define (spair? n) (pair? n))
(define (slet? x) (and (list? x) (eq? (car x) 'let)))
(define (sdefine? x) (and (list? x) (eq? (car x) 'define)))
(define (sbegin? x) (and (list? x) (eq? (car x) 'begin)))
(define (slambda? x) (and (list? x) (eq? (car x) 'lambda)))

(define (compile-sfixnum x next) `(constant ,x ,next))
(define (compile-sboolean x next) `(constant ,x ,next))
(define (compile-schar x next) `(constant ,x ,next))
(define (compile-snull x next) `(constant ,x ,next))
(define (compile-ssymbol x next) `(refer ,x ,next))
(define (compile-squote x next) (compile-constant (cadr x) next))

(define (sprim->op x) (car x))
(define (sprim->args x) (cdr x))
(define (sprim->argc x) (length (sprim->args x)))

(define (ensure-sprim-argc p name c inst)
    (if (eq? (sprim->argc p) c)
        inst
        (error (string-append 
            "invalid number of args to prim " 
            (symbol->string name)
            ", expected "
            (number->string c)
            ", received "
            (number->string (sprim->argc p))))))       

(define (compile-mathprim-rest args prim next)
    (fold-right (lambda (a r) (compile-expr a `(primcall ,prim ,r))) next args))

(define (compile-mathprim p next)
    (let ((op (sprim->op p)) (args (sprim->args p)) (argc (sprim->argc p)))
        (cond
            ((eq? argc 0) (compile-expr 0 next))
            ((eq? argc 1) (compile-expr (car args) next))
            ((eq? argc 2) (compile-expr (car args) (compile-expr (cadr args) `(primcall ,op ,next))))
            (else (compile-expr (car args) (compile-expr (cadr args) `(primcall ,op ,(compile-mathprim-rest (cddr args) op next))))))))

(define (compile-sprim p next)
    (let ((op (sprim->op p)))
        (cond
            ((eq? op 'add) (compile-mathprim p next))
            ((eq? op 'sub) (compile-mathprim p next))
            ((eq? op 'car) (ensure-sprim-argc p 'car 1 '(call $$car)))
            ((eq? op 'cdr) (ensure-sprim-argc p 'cdr 1 '(call $$cdr)))
            ((eq? op 'cons) (ensure-sprim-argc p 'cons 2 '(call $$alloc-pair)))
            (else (error (string-append "invalid primcall: " op))))))

(define (apply-fold x r) (compile-expr x r))
(define (apply-op x) (car x))
(define (apply-args x) (cdr x))
(define (compile-apply x next)
    (let ((op (apply-op x)) (args (apply-args x)))
        (compile-expr op (fold-right apply-fold `(apply ,(length args) ,next) args))))

(define (compile-spair x next)
    (let ((left (car x)) (right (cdr x)))
        (compile-expr left (compile-expr right `(pair ,next)))))


(define (let->bindings x) (car (cdr x)))
(define (let->body x ) (cdr (cdr x)))
(define (binding->var x) (car x))
(define (binding->val x) (car (cdr x)))
(define (compile-binding binding next)
    (compile-expr (binding->val binding) `(slot ,(binding->var binding) (store ,(binding->var binding) ,next))))
(define (compile-slet x next)
    (let ((bindings (let->bindings x)) (body (let->body x)))
        (fold-right compile-binding (compile-expr (cons 'begin body) next) bindings)))

(define (define->var x) (car (cdr x)))
(define (define->body x) (cdr (cdr x)))
(define (compile-sdefine x next)
    (let ((var (define->var x)))
        (cond
            ((list? var) (compile-sdefine `(define ,(car var) (lambda ,(cdr var) ,@(define->body x))) next))
            ((pair? var) (compile-sdefine `(define ,(car var) (lambda (,(cdr var)) ,@(define->body x))) next))
            (else (compile-expr (cons 'begin (define->body x)) `(slot ,(define->var x) (store ,(define->var x) ,next)))))))

(define (begin->body x) (cdr x))
(define (begin-fold x r) (compile-expr x r))
(define (compile-sbegin x next) (fold-right begin-fold next (begin->body x)))

(define (lambda->bindings x) (car (cdr x)))
(define (lambda->body x ) (cdr (cdr x)))
(define (compile-lambda-binding binding next)
    `(param ,binding ,next))
(define (compile-lambda-bindings bindings next)
    (fold-right compile-lambda-binding next bindings))
(define (compile-slambda x next)
    (let* ((body (compile-expr (cons 'begin (lambda->body x)) '(return)))
            (bindings (compile-lambda-bindings (lambda->bindings x) body)))
    `(close ,bindings ,next)))

(define (compile-constant x next)
    (cond
        ((sfixnum?  x) (compile-sfixnum x next))
        ((sboolean? x) (compile-sboolean x next))
        ((schar? x) (compile-schar x next))
        ((snull? x) (compile-snull x next))
        ((ssymbol? x) (compile-ssymbol x next))
        ((spair? x) (compile-spair x next))))

(define (compile-expr x next)
    (cond
        ((satomic? x) (compile-constant x next))
        ((squote? x) (compile-squote x next))
        ((sprim? x) (compile-sprim x next))
        ((slet? x) (compile-slet x next))
        ((sdefine? x) (compile-sdefine x next))
        ((sbegin? x) (compile-sbegin x next))
        ((slambda? x) (compile-slambda x next))

        ((spair? x) (compile-apply x next))
    ))

(define (p01_scheme2cps x) (compile-expr (cons 'begin x) '(return)))))