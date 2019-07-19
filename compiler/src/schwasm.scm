(import (scheme base))
(import (scheme write))
(import (scheme read))
(import (scheme file))
(import (scheme repl))
(import (scheme process-context))
(import (util))

(import (p00_string2tokens))
(import (p01_tokens2syntax))
(import (p02_attrs))
(import (p03_syntax2scheme))
(import (p04_scheme2cps))
(import (p05_flattencps))
(import (p06_closes2funcs))
(import (p07_lift_rodatas))
(import (p08_funcs2wat))

(import (srfi 159))
(import (chibi show pretty))

(define (print-help-and-exit) 
        (display "arguments: schwasm.scm [input.scm] [out.wat]")
        (exit))

(if (not (eq? (length (command-line)) 3))
    (print-help-and-exit))

(define input-file (list-ref (command-line) 1))
(define output-file (list-ref (command-line) 2))

(define (write-file output file)
    (if (file-exists? file) (delete-file file))
    (let ((p (open-output-file file)))
        (show p (pretty output))
        (close-output-port p)))

(define (compile prog)
    (let ((p00 (p00_string2tokens prog)))
    (let ((p01 (p01_tokens2syntax p00)))
    (let ((p02 (p02_attrs p01)))
    (let ((p03 (p03_syntax2scheme p02)))
    (let ((p04 (p04_scheme2cps p03)))
    (let ((p05 (p05_flattencps p04)))
    (let ((p06 (p06_closes2funcs p05)))
    (let ((p07 (p07_lift_rodatas p06)))
    (let ((p08 (p08_funcs2wat p07)))
    (display (show #f (pretty p08)))
        p08))))))))))

(define (main)
    (let* ((wat (compile (open-input-file input-file))))
            (write-file wat output-file)))

(main)
