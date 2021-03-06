(require 's)
(require 'lab-util)

(defun labmode--markdown-cell (source)
  (list (cons 'mode "markdown") (cons 'source source))
  )


;; Can also supply 'input' (i.e HTML) from emacs. No longer used.
(defun labmode--code-cell (source &optional prompt)
  (list (cons 'mode "code")
        (cons 'source source)
        (cons 'prompt prompt)
        )
  )

(defun labmode--split-newlines (string)
  (mapcar (lambda (x) (concat x "\n")) (split-string string "\n"))
  )

;;=====================================;;
;; Parsing cells from .ipynb JSON file ;;
;;=====================================;;

(defun labmode-parse-notebook-file (filename)
  "Given an .ipynb file return the parsed list of cells"
  (let* ((extracted)
         (data (json-read-file filename))
         (cells (assoc-value 'cells data))
         (metadata (assoc-value 'metadata data))
         (nbformat (assoc-value 'nbformat data))
         (nbformat-minor (assoc-value 'nbformat_minor data)))
    (dolist (cell (append cells nil) extracted)

      (let* ((mode (assoc-value 'cell_type cell))
             (source  (s-join "" (assoc-value 'source cell)))
             (prompt (assoc-value 'execution_count cell))
             (labcell (if (string= mode "code")
                         (labmode--code-cell source prompt)
                       (labmode--markdown-cell source))))
        (setq extracted (push labcell extracted))
        )
      )
    (reverse extracted)
    )
)

;;==============================;;
;; Rendering cells back to text ;;
;;==============================;;

(defun labmode--code-cell-to-text (cell)
  "Given a code cell return the textual equivalent"
  (let* ((source (assoc-value 'source cell))
        (prompt (assoc-value 'prompt cell))
        (prompt-line (if (null prompt)
                         "# In[ ]\n"
                       (s-concat "# In[" (format "%s" prompt) "]\n"))))
    (s-concat prompt-line  source "\n")
    )
)

(defun labmode--markdown-cell-to-text (cell)
  "Given a markdown cell return the textual equivalent"
  (s-concat "\"\"\"\n" (assoc-value 'source cell) "\n\"\"\"\n")
)


(defun labmode--cells-to-text (cells)
  "Given a list of cells return the textual equivalent"
  (let ((lines nil))
    (dolist (cell cells lines)
      (if (string= (assoc-value 'mode cell) "code")
          (setq lines (push (labmode--code-cell-to-text cell) lines))
        (setq lines (push (labmode--markdown-cell-to-text cell) lines))
        )
      )
    (s-join "\n\n" (reverse lines))
    )
)
(provide 'lab-parse)
