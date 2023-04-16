#+TITLE:     org-babel-sqsh.txt
#+AUTHOR:    Fabrice Niessen
#+EMAIL:     fni@missioncriticalit.com
#+DATE:      2010-09-20
#+DESCRIPTION: 
#+KEYWORDS: 
#+LANGUAGE:  en_US

* Adding support for sqsh engine

#+begin_src emacs-lisp
(defun org-babel-execute:sql (body params)
  "Execute a block of Sql code with Babel.
This function is called by `org-babel-execute-src-block'."
  (let* ((result-params (split-string (or (cdr (assoc :results params)) "")))
	 (processed-params (org-babel-process-params params))
         (cmdline (cdr (assoc :cmdline params)))
         (engine (cdr (assoc :engine params)))
         (in-file (org-babel-temp-file "sql-in-"))
         (out-file (or (cdr (assoc :out-file params))
                       (org-babel-temp-file "sql-out-")))
         (command (case (intern engine)
                    ('sqsh (format "sqsh %s -i \"%s\" -o \"%s\""
                                    (or cmdline "") in-file out-file))
                    (t (error "no support for the %s sql engine" engine)))))
    (with-temp-file in-file
      (insert (org-babel-expand-body:sql body params)))
    (message command)
    (shell-command command)
    (with-temp-buffer
      ;; (insert-file-contents out-file)
      (org-table-import out-file nil)
      (org-babel-reassemble-table
       (org-table-to-lisp)
       (org-babel-pick-name (nth 4 processed-params) (cdr (assoc :colnames params)))
       (org-babel-pick-name (nth 5 processed-params) (cdr (assoc :rownames params))))
      )))
#+end_src

* Point of attention

You need a =go= statement (in small caps).

* Multiple display styles

- =go -m vert=
- =go -m bcp=
- =go -m pretty=

#+begin_src sql :results output :cmdline -S 10.10.10.11 -D [pfi-paiestag] -U sa -P LpmdlP -w 256 :engine sqsh
SELECT TOP 10 pfiID, 
       stgNISS,
       etpSiegeExpNumBCE,
       frmArretDate,
       rolEngagDateFin
FROM dossier, stagiaire, entreprise, formation, rol
WHERE pfiID = stgPfiID_fk AND
      pfiID = etpPfiID_fk AND
      pfiID = frmPfiID_fk AND
      pfiID = rolPfiID_fk
go -m horiz
#+end_src

#+results:
| pfiID            | stgNISS     | etpSiegeExpNumBCE              | frmArretDate        | rolEngagDateFin     |      |         |         |    |      |         |
| ---------------- | ----------- | ------------------------------ | ------------------- | ------------------- |      |         |         |    |      |         |
| 00/200105/0001   | NULL        | NULL                           | NULL                | Jun                 |   11 |    2002 | 12:00AM |    |      |         |
| 00/200105/0002   | NULL        | NULL                           | NULL                | May                 |   29 |    2001 | 12:00AM |    |      |         |
| 52/200009/0023   | NULL        | NULL                           | NULL                | Sep                 |   23 |    2001 | 12:00AM |    |      |         |
| 52/200009/0024   | NULL        | NULL                           | Mar                 | 14                  | 2001 | 12:00AM | Sep     | 12 | 2001 | 12:00AM |
| 52/200009/0025   | NULL        | NULL                           | NULL                | Sep                 |   24 |    2001 | 12:00AM |    |      |         |
| 52/200009/0026   | NULL        | NULL                           | NULL                | Sep                 |   18 |    2001 | 12:00AM |    |      |         |
| 52/200009/0027   | NULL        | NULL                           | NULL                | Sep                 |    5 |    2001 | 12:00AM |    |      |         |
| 52/200009/0028   | NULL        | NULL                           | NULL                | Sep                 |    2 |    2001 | 12:00AM |    |      |         |
| 52/200009/0029   | NULL        | NULL                           | Mar                 | 28                  | 2001 | 12:00AM | Sep     | 26 | 2001 | 12:00AM |
| 52/200009/0030   | NULL        | NULL                           | Mar                 | 25                  | 2001 | 12:00AM | Oct     |  7 | 2001 | 12:00AM |
|                  |             |                                |                     |                     |      |         |         |    |      |         |
| (10              | rows        | affected)                      |                     |                     |      |         |         |    |      |         |

* Other

#+begin_src sql :results output :cmdline -S 10.10.10.11 -D [pfi-paiestag] -U sa -P LpmdlP -w 1024 :engine sqsh
sp_who
go -m bcp
#+end_src

#+results:
| /tmp/sql-out-10393QSu | 744 |

* Testbed (pass or fail?)

** There is no go

#+begin_src sql :results output :cmdline -S 10.10.10.11 -D [pfi-paiestag] -U sa -P LpmdlP -w 256 :engine sqsh
SELECT TOP 5 pfiID
FROM dossier
#+end_src

** Column does not exist

#+begin_src sql :results output :cmdline -S 10.10.10.11 -D [pfi-paiestag] -U sa -P LpmdlP -w 256 :engine sqsh
SELECT TOP 5 columnnotknown
FROM dossier
go
#+end_src
