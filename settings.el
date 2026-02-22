;; M-x load-file /path-to-this-file/settings.el
;; Simple include it from any environment.

(defconst my-emacs-root
  (file-name-directory (or load-file-name
                           (when (boundp 'bytecomp-filename) bytecomp-filename)
                           buffer-file-name))
  "Installation directory of my-emacs"
)

(setq auto-save-default nil)
(setq case-fold-search nil)
(setq column-number-mode t)
(setq delete-auto-save-files nil)
(setq global-hl-line-mode t)
(global-display-line-numbers-mode t)
(setq indent-tabs-mode nil)
(setq make-backup-files nil)
(mouse-wheel-mode t)
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)
(setq show-paren-mode t)
(setq tab-width 4)
(setq sgml-basic-offset 4)
(setq global-subword-mode t)
(setq tags-case-fold-search nil)
(setq xterm-mouse-mode t)
;; (setq ido-mode t)

;; (xterm-mouse-mode)
;; (gpm-mouse-mode)
;; (mouse-wheel-mode)
;; (ecb-activate)
;; (tmm-menubar)

(setq file-name-coding-system 'utf-8)
(setq scroll-step 1)
;; (setq ac-ignore-case nil) ;; auto-complete removed
(setq require-final-newline t)
(setq grep-find-command '("find . -name \"*.py\" -type f -print0 | xargs -0 -e grep -nH -e \"\"" . 93))
(setq grep-find-ignored-directories '("SCCS" "RCS" "CVS" "MCVS" ".svn" ".git" ".hg" ".bzr" "_MTN" "_darcs" "{arch}"))
(global-set-key (kbd "C-c m f") 'rgrep)
;; (setq grep-find-command "find . ! -name \"*~\" ! -name \"#*#\" -type f -print0 | xargs -0 -e grep -nH -e ")

;; occur
(defun quick-occur-at-point ()
  "look for word at point in buffer"
  (interactive)
  (occur (thing-at-point 'symbol)))

(global-set-key (kbd "C-c m o") 'quick-occur-at-point)

;; search
(define-key isearch-mode-map (kbd "C-d")
  'fc/isearch-yank-symbol)
(defun fc/isearch-yank-symbol ()
  "Yank the symbol at point into the isearch minibuffer.

C-w does something similar in isearch, but it only looks for
the rest of the word. I want to look for the whole string. And
symbol, not word, as I need this for programming the most."
  (interactive)
  (isearch-yank-string
   (save-excursion
     (when (and (not isearch-forward)
                isearch-other-end)
       (goto-char isearch-other-end))
     (thing-at-point 'symbol))))

;; (set-face-attribute 'default nil :height 100)

;; Buffers
 (defun prev-window ()
   (interactive)
   (other-window -1))

(define-key global-map (kbd "C-x O") 'prev-window) ;; C-x p is now project.el prefix in Emacs 28+
