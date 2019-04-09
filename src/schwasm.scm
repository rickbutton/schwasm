(import (scheme base))
(import (scheme write))
(import (scheme read))
(import (scheme file))
(import (scheme repl))
(import (scheme process-context))
(import (util))

(import (pass1))
(import (pass2))
(import (pass97))
(import (pass98))
(import (pass99))

(import (srfi 159))
(import (chibi show pretty))

(define (print-help-and-exit) 
        (display "arguments: schwasm.scm [input.scm] [out.wat] [out.funcs]")
        (exit))

(if (not (eq? (length (command-line)) 4))
    (print-help-and-exit))

(define input-file (list-ref (command-line) 1))
(define output-file (list-ref (command-line) 2))
(define funcs-file (list-ref (command-line) 3))

(define (read-all)
    (let ((o (read)))
        (if (eof-object? o) '() (cons o (read-all)))))

(define (read-input-file)
    (with-input-from-file input-file read-all))

(define (write-file output file)
    (if (file-exists? file) (delete-file file))
    (let ((p (open-output-file file)))
        (display (show #f (pretty output)))
        (show p (pretty output))
        (close-output-port p)))

(define (main)
    (let* ((input (read-input-file))
        (pass1 (scheme->pass1 input))
        (pass2 (pass1->pass2 pass1))
        (flat  (flatten-cps pass2))
        (funcs (lift-closures flat #t)))

        (write-file funcs funcs-file)
        (let ((wat   (funcs->wat funcs)))
            (write-file wat output-file))))

(main)
(exit)