;;; Org batch export for Web
;;
;; Copyright (C) 2018, Tobias
;; Copyright (C) 2023, John32ma
;; Copyright (C) 2024, RnE
;;

(package-initialize)

(require 'treesit)

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (csharp "https://github.com/tree-sitter/tree-sitter-c-sharp")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (js . ("https://github.com/tree-sitter/tree-sitter-javascript" "master" "src"))
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
        (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))))

(setq treesit-auto-fallback-alist
      '((toml-ts-mode . conf-toml-mode)
        (html-ts-mode . mhtml-mode)
        (typescript-ts-mode . nil)
        (tsx-ts-mode . nil)))

(dolist (language-source treesit-language-source-alist)
  (let* ((name (car language-source))
         (name-ts-mode (intern (concat (symbol-name name) "-ts-mode")))
         (fallback-assoc (assq name-ts-mode treesit-auto-fallback-alist))
         (fallback-name (cdr fallback-assoc))
         (name-mode (or fallback-name
                        (intern (concat (symbol-name name) "-mode"))))
         (name-mode-bound-p (fboundp name-mode))
         (skip-remap-p (and fallback-assoc
                            (not (cdr fallback-assoc)))))
    (and (not skip-remap-p)
         (fboundp name-ts-mode)
         (if (treesit-ready-p name t)
             (add-to-list 'major-mode-remap-alist `(,name-mode . ,name-ts-mode))
           (when name-mode-bound-p
             (add-to-list 'major-mode-remap-alist `(,name-ts-mode . ,name-mode)))))))


(require 'font-lock)
(require 'cl-seq)
(require 'subr-x)

(unless (boundp 'maximal-integer)
  (defconst maximal-integer (lsh -1 -1)
    "Maximal integer value representable natively in emacs lisp."))

(defun face-spec-default (spec)
  "Get list containing at most the default entry of face SPEC.
Return nil if SPEC has no default entry."
  (let* ((first (car-safe spec))
         (display (car-safe first)))
    (when (eq display 'default)
      (list (car-safe spec)))))

(defun face-spec-min-color (display-atts)
  "Get min-color entry of DISPLAY-ATTS pair from face spec."
  (let* ((display (car-safe display-atts)))
    (or (car-safe (cdr (assoc 'min-colors display)))
        maximal-integer)))

(defun face-spec-highest-color (spec)
  "Search face SPEC for highest color.
That means the DISPLAY entry of SPEC
with class 'color and highest min-color value."
  (let ((color-list (cl-remove-if-not
                     (lambda (display-atts)
                       (when-let ((display (car-safe display-atts))
                                  (class (and (listp display)
                                              (assoc 'class display)))
                                  (background (assoc 'background display)))
                         (and (member 'light (cdr background))
                              (member 'color (cdr class)))))
                     spec)))
    (cl-reduce (lambda (display-atts1 display-atts2)
                 (if (> (face-spec-min-color display-atts1)
                        (face-spec-min-color display-atts2))
                     display-atts1
                   display-atts2))
               (cdr color-list)
               :initial-value (car color-list))))

(defun face-spec-t (spec)
  "Search face SPEC for fall back."
  (cl-find-if (lambda (display-atts)
                (eq (car-safe display-atts) t))
              spec))

(defun my-face-attribute (face attribute &optional frame inherit)
  "Get FACE ATTRIBUTE from `face-user-default-spec'.
And not from `face-attribute'.
FRAME and INHERIT are ignored."
  (ignore frame)
  (ignore inherit)
  (let* ((face-spec (face-user-default-spec face))
         (display-attr (or (face-spec-highest-color face-spec)
                           (face-spec-t face-spec)))
         (attr (cdr display-attr))
         (val (or (plist-get attr attribute) (car-safe (cdr (assoc attribute attr))))))
    (when (and (null (eq attribute :inherit))
               (null val))
      (let ((inherited-face (my-face-attribute face :inherit)))
        (when (and inherited-face
                   (null (eq inherited-face 'unspecified)))
          (setq val (my-face-attribute inherited-face attribute))))
      (when (null val)
        (while face-spec
          (let ((entry (car face-spec)))
            (if (and (= (length entry) 3)
                     (eq (car entry) 'default)
                     (eq (car (cdr entry)) :inherit))
                (progn
                  (setq val (my-face-attribute (car (cdr (cdr entry))) attribute))
                  (setq face-spec nil))
              (setq face-spec (cdr face-spec)))))))
    (or val 'unspecified)))

(advice-add 'face-attribute :override #'my-face-attribute)

(setq org-html-doctype "html5"
      org-html-html5-fancy t)

(setq org-emphasis-regexp-components
      (list (concat " \t('\"{" "[:nonascii:]")
            (concat "- \t.,:!?;'\")}\\[" "[:nonascii:]")
            " \t\r\n,\"'"
            "."
            1))

(defun cjk/org-element--parse-generic-emphasis (mark type)
  (save-excursion
    (let ((origin (point)))
      (unless (bolp) (forward-char -1))
      (let ((opening-re
             (rx-to-string
              `(seq (or line-start (any space ?- ?\( ?' ?\" ?\{ nonascii))
                    ,mark
                    (not space)))))
        (when (looking-at opening-re)
          (goto-char (1+ origin))
          (let ((closing-re
                 (rx-to-string
                  `(seq
                    (not space)
                    (group ,mark)
                    (or (any space ?- ?. ?, ?\; ?: ?! ?? ?' ?\" ?\) ?\} ?\\ ?\[
                             nonascii)
                        line-end)))))
            (when (re-search-forward closing-re nil t)
              (let ((closing (match-end 1)))
                (goto-char closing)
                (let* ((post-blank (skip-chars-forward " \t"))
                       (contents-begin (1+ origin))
                       (contents-end (1- closing)))
                  (list type
                        (append
                         (list :begin origin
                               :end (point)
                               :post-blank post-blank)
                         (if (memq type '(code verbatim))
                             (list :value
                                   (and (memq type '(code verbatim))
                                        (buffer-substring
                                         contents-begin contents-end)))
                           (list :contents-begin contents-begin
                                 :contents-end contents-end)))))))))))))
(advice-add #'org-element--parse-generic-emphasis :override #'cjk/org-element--parse-generic-emphasis)

(with-eval-after-load 'org
  (setq org-match-substring-regexp
        (concat
         "\\([0-9a-zA-Zα-γΑ-Ω]\\)\\([_^]\\)\\("
         "\\(?:" (org-create-multibrace-regexp "{" "}" org-match-sexp-depth) "\\)"
         "\\|"
         "\\(?:" (org-create-multibrace-regexp "(" ")" org-match-sexp-depth) "\\)"
         "\\|"
         "\\(?:\\*\\|[+-]?[[:alnum:].,\\]*[[:alnum:]]\\)\\)")))

(defadvice org-html-paragraph (before org-html-paragraph-advice
                                      (paragraph contents info) activate)
  (let* ((origin-contents (ad-get-arg 1))
         (fix-regexp "[[:multibyte:]]")
         (fixed-contents
          (replace-regexp-in-string
           (concat
            "\\(" fix-regexp "\\) *\n *\\(" fix-regexp "\\)") "\\1\\2" origin-contents)))
    (ad-set-arg 1 fixed-contents)))
