(import (p00_string2tokens.test))
(import (p01_tokens2syntax.test))
(import (p02_attrs.test))
(import (p03_syntax2scheme.test))
(import (p04_scheme2cps.test))
(import (chibi time))

(time (test_p00_string2tokens))
(time (test_p01_tokens2syntax))
(time (test_p02_attrs))
(time (test_p03_syntax2scheme))
(time (test_p04_scheme2cps))
