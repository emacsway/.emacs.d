;; nvm path
(let ((nvm-node-dir (expand-file-name "~/.nvm/versions/node")))
  (when (file-directory-p nvm-node-dir)
    (let ((newest (car (last (directory-files nvm-node-dir t "^v")))))
      (when newest
        (let ((bin-dir (concat newest "/bin")))
          (setenv "PATH" (concat bin-dir ":" (getenv "PATH")))
          (add-to-list 'exec-path bin-dir))))))


;; go path
(let ((go-bin (expand-file-name "~/go/bin")))
  (when (file-directory-p go-bin)
    (setenv "PATH" (concat go-bin ":" (getenv "PATH")))
    (add-to-list 'exec-path go-bin)))


;; ~/.local/bin (pipx installs binaries here, e.g. ruff)
(let ((local-bin (expand-file-name "~/.local/bin")))
  (when (file-directory-p local-bin)
    (setenv "PATH" (concat local-bin ":" (getenv "PATH")))
    (add-to-list 'exec-path local-bin)))


;; package
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; auto-install missing packages
(defvar my-packages '(company pyvenv yasnippet web-mode go-mode typescript-mode tuareg dune treemacs xclip eat chess lichess flymake-ruff apheleia))

(defun my-install-packages ()
  (package-refresh-contents)
  (dolist (pkg my-packages)
    (unless (package-installed-p pkg)
      (package-install pkg))))

(unless (cl-every #'package-installed-p my-packages)
  (my-install-packages))


;; company (completion UI)
(require 'company)
(global-company-mode 1)
(setq company-dabbrev-ignore-case nil)
(setq company-minimum-prefix-length 1)
(setq company-tooltip-align-annotations t)


;; eglot + pyright (built-in in Emacs 30)
(require 'eglot)
(setq eglot-autoshutdown t)
(setq-default eglot-workspace-configuration
              '(:python.analysis (:autoImportCompletions t)))
(add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
(add-hook 'python-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook (lambda ()
  (define-key python-mode-map (kbd "C-c g") 'xref-find-definitions)
  (define-key python-mode-map (kbd "C-c d") 'eldoc-doc-buffer)
  (define-key python-mode-map (kbd "C-c TAB") 'completion-at-point)
  (define-key python-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key python-mode-map (kbd "C-c C-a") 'eglot-code-actions)
  ;; (define-key python-mode-map (kbd "C-c f") 'eglot-format-buffer)  ; pyright has no formatting capability
  (define-key python-mode-map (kbd "C-c f") 'apheleia-format-buffer)
))

(setq python-check-command "ruff check")

;; Python: ruff lint + format without a second LSP
;; ---------------------------------------------------------------------------
;; Eglot is architecturally one-server-per-buffer by design of its maintainer
;; (see https://github.com/joaotavora/eglot/discussions/1429), so we cannot
;; run `ruff server` alongside pyright the way the VSCode extension
;; charliermarsh.ruff does. Instead we split ruff's capabilities across two
;; non-LSP channels that coexist cleanly with pyright-via-eglot:
;;
;;   - linting:    flymake-ruff  — a flymake backend running `ruff check`.
;;                                 It coexists with eglot's own flymake
;;                                 backend; pyright contributes type errors,
;;                                 ruff contributes lint warnings.
;;   - formatting: apheleia      — async before-save runner of `ruff format`,
;;                                 applying changes via RCS-patch so point
;;                                 and undo history survive.
;;
;; Pyright has no formatting capability, so `eglot-format-buffer' is NOT
;; attached to before-save-hook for python-mode — it would error on every
;; save. The global `delete-trailing-whitespace' from settings.el handles the
;; whitespace side as a safety net; the local hook below keeps that working
;; even if apheleia's save chain aborts for any reason.
;;
;; Future option: when Rassumfrassum
;; (https://github.com/joaotavora/rassumfrassum), the LSP multiplexer written
;; by the eglot maintainer himself, stabilizes, we can collapse both channels
;; back into a single multiplexed LSP setup that gives ruff code actions and
;; hover on top of what we have now:
;;
;;   (add-to-list 'eglot-server-programs
;;                '((python-mode python-ts-mode)
;;                  . ("rass" "--"
;;                     "pyright-langserver" "--stdio" "--"
;;                     "ruff" "server")))
;;   ;; then: drop flymake-ruff and apheleia from python-mode,
;;   ;; re-add eglot-format-buffer to before-save-hook.
;;
;; As of 2026-04 Rassumfrassum is labeled "young project, will have bugs",
;; so we stay with the mature apheleia + flymake-ruff pair for now.

;; belt-and-braces: trailing whitespace cleanup as a local hook, independent
;; of apheleia's save chain and of the global hook in settings.el.
(add-hook 'python-mode-hook (lambda ()
  ;; (add-hook 'before-save-hook 'eglot-format-buffer nil t)  ; pyright has no formatting capability; apheleia handles formatting instead
  (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)))

;; ruff diagnostics via flymake-ruff.
;; Attach to eglot-managed-mode-hook so flymake-ruff is added *after* eglot
;; has set up its own flymake backend (otherwise eglot would clobber it).
(require 'flymake-ruff)
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (when (derived-mode-p 'python-mode)
              (flymake-ruff-load))))

;; ruff format on save via apheleia.
;; The chain `(ruff-isort ruff)` first runs `ruff check --select I --fix -`
;; (organize imports) and then `ruff format -` (the formatter proper). Both
;; presets ship with apheleia out of the box — see `apheleia-formatters'.
(require 'apheleia)
(setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff))
(add-hook 'python-mode-hook #'apheleia-mode)

;; ipython
(when (executable-find "ipython")
  (setq python-shell-interpreter "ipython"
        python-shell-interpreter-args "--simple-prompt --pprint -i"))

;; eglot + gopls
(add-hook 'go-mode-hook 'eglot-ensure)
(add-hook 'go-mode-hook (lambda ()
  (define-key go-mode-map (kbd "C-c g") 'xref-find-definitions)
  (define-key go-mode-map (kbd "C-c d") 'eldoc-doc-buffer)
  (define-key go-mode-map (kbd "C-c TAB") 'completion-at-point)
  (define-key go-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key go-mode-map (kbd "C-c C-a") 'eglot-code-actions)
  (define-key go-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)))


;; eglot + typescript-language-server
(add-hook 'typescript-mode-hook 'eglot-ensure)
(add-hook 'typescript-mode-hook (lambda ()
  (define-key typescript-mode-map (kbd "C-c g") 'xref-find-definitions)
  (define-key typescript-mode-map (kbd "C-c d") 'eldoc-doc-buffer)
  (define-key typescript-mode-map (kbd "C-c TAB") 'completion-at-point)
  (define-key typescript-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key typescript-mode-map (kbd "C-c C-a") 'eglot-code-actions)
  (define-key typescript-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)))

;; eglot + ocaml-lsp-server
(add-hook 'tuareg-mode-hook 'eglot-ensure)
(add-hook 'tuareg-mode-hook (lambda ()
  (define-key tuareg-mode-map (kbd "C-c g") 'xref-find-definitions)
  (define-key tuareg-mode-map (kbd "C-c d") 'eldoc-doc-buffer)
  (define-key tuareg-mode-map (kbd "C-c TAB") 'completion-at-point)
  (define-key tuareg-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key tuareg-mode-map (kbd "C-c C-a") 'eglot-code-actions)
  (define-key tuareg-mode-map (kbd "C-c f") 'eglot-format-buffer)
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)))


;; TSX через web-mode
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . web-mode))
(add-to-list 'eglot-server-programs '(web-mode . ("typescript-language-server" "--stdio")))
(add-hook 'web-mode-hook (lambda ()
  (when (and buffer-file-name (string-match-p "\\.tsx\\'" buffer-file-name))
    (eglot-ensure))))


;; pyvenv
(require 'pyvenv)
(setq pyvenv-default-virtual-env-name ".env")


;; yasnippet
(require 'yasnippet)
(yas-global-mode 1)


;; web-mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
(setq web-mode-engines-alist '(("django" . "\\.html\\'") ("django" . "\\.djhtml\\'")))
(add-hook 'web-mode-hook (lambda ()
  (setq web-mode-markup-indent-offset 4)
  (setq web-mode-css-indent-offset 4)
  (setq web-mode-code-indent-offset 4)
  (setq web-mode-style-padding 0)
  (setq web-mode-script-padding 0)
  (setq web-mode-block-padding 0)))


;; treemacs (file tree sidebar)
(require 'treemacs)
(global-set-key (kbd "C-c t t") 'treemacs)
(setq treemacs-width 30
      treemacs-position 'left
      treemacs-no-delete-other-windows t
      treemacs-collapse-dirs (if treemacs-python-executable 3 0)
      treemacs-sorting 'alphabetic-asc
      treemacs-litter-directories '("/node_modules" "/.venv" "/.env" "/.cask"))
(treemacs-follow-mode t)
(treemacs-filewatch-mode t)
(treemacs-fringe-indicator-mode 'always)
(pcase (cons (not (null (executable-find "git")))
             (not (null treemacs-python-executable)))
  (`(t . t) (treemacs-git-mode 'deferred))
  (`(t . _) (treemacs-git-mode 'simple)))
(add-hook 'emacs-startup-hook
          (lambda ()
            (let* ((dir (expand-file-name default-directory))
                   (name (file-name-nondirectory (directory-file-name dir)))
                   (persist-file (expand-file-name ".cache/treemacs-persist" user-emacs-directory)))
              ;; Write persist file with current directory before treemacs starts
              (with-temp-file persist-file
                (insert (format "* Default\n** %s\n - path :: %s\n" name dir)))
              (treemacs)
              (when (treemacs-get-local-window)
                (select-window (treemacs-get-local-window))))))

;; xclip (clipboard in terminal)
(require 'xclip)
(xclip-mode 1)

;; ido (buffers only) + fido (files)
(require 'ido)
(ido-mode 'buffers)
(setq ido-enable-flex-matching t)
(fido-mode t)


;; claude-code.el (Claude Code CLI in Emacs)
(unless (package-installed-p 'claude-code)
  (package-vc-install "https://github.com/stevemolitor/claude-code.el"))
(require 'claude-code)
(global-set-key (kbd "C-c a c") 'claude-code-transient)

;; claudemacs (Claude Code pair programming)
(unless (package-installed-p 'claudemacs)
  (package-vc-install "https://github.com/cpoile/claudemacs"))
(require 'claudemacs)
(global-set-key (kbd "C-c a m") 'claudemacs-transient)


;; settings
(load-file "~/.emacs.d/settings.el")
