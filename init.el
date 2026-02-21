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


;; package
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; auto-install missing packages
(defvar my-packages '(company pyvenv yasnippet web-mode go-mode typescript-mode))

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
(add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))
(add-hook 'python-mode-hook 'eglot-ensure)
(add-hook 'python-mode-hook (lambda ()
  (define-key python-mode-map (kbd "C-c g") 'xref-find-definitions)
  (define-key python-mode-map (kbd "C-c d") 'eldoc-doc-buffer)
  (define-key python-mode-map (kbd "C-c TAB") 'completion-at-point)
  (define-key python-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key python-mode-map (kbd "C-c C-a") 'eglot-code-actions)
  (define-key python-mode-map (kbd "C-c f") 'eglot-format-buffer)
))

;; ruff format on save
(setq python-check-command "ruff check")
(add-hook 'python-mode-hook (lambda ()
  (add-hook 'before-save-hook 'eglot-format-buffer nil t)))

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


;; ido
(require 'ido)
(ido-mode t)
(setq ido-enable-flex-matching t)


;; settings
(load-file "~/.emacs.d/settings.el")
