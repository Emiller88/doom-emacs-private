;;; config-new.el -*- lexical-binding: t; -*-

(setq user-mail-address "Edmund.A.Miller@gmail.com"
      user-full-name "Edmund Miller"

      doom-scratch-initial-major-mode 'lisp-interaction-mode
      ;; doom-theme 'doom-one
      treemacs-width 32

      ;; Line numbers are pretty slow all around. The performance boost of
      ;; disabling them outweighs the utility of always keeping them on.
      display-line-numbers-type nil

      ;; This used to be off by default
      company-idle-delay nil

      ;; lsp-ui-sideline is redundant with eldoc and much more invasive, so
      ;; disable it by default.
      lsp-ui-sideline-enable nil
      lsp-enable-symbol-highlighting nil
      +lsp-prompt-to-install-server 'quiet

      ;; More common use-case
      evil-ex-substitute-global t)

(use-package! tao-theme
  :init
  (setq tao-theme-sepia-depth 3.38
        tao-theme-sepia-saturation 0.98)
  :config
  (load-theme 'tao-yang t)
  (custom-set-faces!
    '(default :background "#f7f3ee" :foreground "#605a52")
    '(+workspace-tab-selected-face :background "#67665F" :foreground "#FFFFF5")
    '(+org-todo-active :background "#67665F" :foreground "#FFFFF5")
    '(org-roam-link :foreground "blue")
    '(org-roam-link-invalid :foreground "red")))

;; (use-package! color-identifiers-mode
;;   :hook prog-mode)

;; Remove modeline in emacs-everywhere
(remove-hook 'emacs-everywhere-init-hooks #'hide-mode-line-mode)

(defadvice! center-emacs-everywhere-in-origin-window (frame window-info)
  :override #'emacs-everywhere-set-frame-position
  (cl-destructuring-bind (x y width height)
      (emacs-everywhere-window-geometry window-info)
    (set-frame-position frame
                        (+ x (/ width 2) (- (/ width 2)))
                        (+ y (/ height 2)))))


;;; UI

;; "monospace" means use the system default. However, the default is usually two
;; points larger than I'd like, so I specify size 12 here.
(setq doom-font (font-spec :family "JetBrainsMono" :size 13 :weight 'light)
      doom-variable-pitch-font (font-spec :family "Noto Serif" :size 14)
      ivy-posframe-font (font-spec :family "JetBrainsMono" :size 16))

;; Prevents some cases of Emacs flickering
(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))

;;
;;; Keybinds

(map! (:after evil-org
       :map evil-org-mode-map
       :n "gk" (cmd! (if (org-on-heading-p)
                         (org-backward-element)
                       (evil-previous-visual-line)))
       :n "gj" (cmd! (if (org-on-heading-p)
                         (org-forward-element)
                       (evil-next-visual-line))))
      :leader
      (:prefix "f"
       :desc "Find file in dotfiles" :n "o" #'+emiller/find-in-dotfiles
       :desc "Browse dotfiles" :n "O" #'+emiller/browse-dotfiles)
      (:prefix "i"
       :desc "Insert date" :n "d" #'insert-todays-date)
      (:prefix "o"
       :desc "Calc" :n "c" #'calc
       :desc "easy-hugo" :n "g" #'easy-hugo
       :desc "APP: IRC" :n "i" #'=irc
       ;; :desc "APP: notmuch" :n "m" #'=mu4e
       ;; :desc "dired-sidebar" :n "n" #'dired-sidebar-toggle-sidebar
       :desc "todo.org" :n "o" #'+emiller/visit-todo-org
       :desc "projects" :n "p" #'+emiller/visit-projects-org
       :desc "emms" :n "s" #'emms
       :desc "APP: rss" :n "," #'=rss))

;;
;;; Modules

;;; :completion ivy
(after! ivy
  ;; I prefer search matching to be ordered; it's more precise
  (add-to-list 'ivy-re-builders-alist '(counsel-projectile-find-file . ivy--regex-plus)))

;; Switch to the new window after splitting
(setq evil-split-window-below t
      evil-vsplit-window-right t)

;;; :editor evil
(after! evil
  (require 'evil-textobj-anyblock)
  (evil-define-text-object my-evil-textobj-anyblock-inner-quote
    (count &optional beg end type)
    "Select the closest outer quote."
    (let ((evil-textobj-anyblock-blocks
           '(("'" . "'")
             ("\"" . "\"")
             ("`" . "`")
             ("“" . "”"))))
      (evil-textobj-anyblock--make-textobj beg end type count nil)))

  (evil-define-text-object my-evil-textobj-anyblock-a-quote
    (count &optional beg end type)
    "Select the closest outer quote."
    (let ((evil-textobj-anyblock-blocks
           '(("'" . "'")
             ("\"" . "\"")
             ("`" . "`")
             ("“" . "”"))))
      (evil-textobj-anyblock--make-textobj beg end type count t)))

  (define-key evil-inner-text-objects-map "q" 'my-evil-textobj-anyblock-inner-quote)
  (define-key evil-outer-text-objects-map "q" 'my-evil-textobj-anyblock-a-quote))

;;; :emacs dired
;;Get rid of dired message when using "a"
(put 'dired-find-alternate-file 'disabled nil)

;;; :ui doom-dashboard
;; NARF
(setq fancy-splash-image (concat doom-private-dir "narf.png"))
;; Don't need the menu; I know them all by heart
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)

;;; :checks grammar
(after! langtool
  (setq langtool-bin "languagetool-commandline"))

;;; :tools biblio
(setq! +biblio-pdf-library-dir "~/sync/papers"
       +biblio-default-bibliography-files '("~/sync/reference/bibliography.bib"
                                            "~/sync/reference/biochemistry.bib"
                                            "~/sync/reference/genomics.bib"
                                            "~/sync/reference/molecular_biology.bib"
                                            "~/sync/reference/molecular_biology_project.bib"
                                            "~/sync/reference/books.bib")
       +biblio-notes-path "~/sync/org/roam/bib/")

;;; :tools direnv
(setq direnv-always-show-summary nil)

;;; :tools magit
(setq magit-repository-directories '(("~/src" . 3))
      magit-save-repository-buffers nil
      ;; Don't restore the wconf after quitting magit, it's jarring
      magit-inhibit-save-previous-winconf t
      transient-values '((magit-commit "--gpg-sign=BD387FF7BC10AA9D")
                         (magit-rebase "--autosquash" "--autostash" "--gpg-sign=BD387FF7BC10AA9D")
                         (magit-pull "--rebase" "--autostash" "--gpg-sign=BD387FF7BC10AA9D")))

;; Enable git gutter on tramp sessions
(defun +version-control|git-gutter-maybe ()
  (when buffer-file-name
    (require 'git-gutter-fringe)
    (git-gutter-mode +1)))

(setenv "EDITOR" "emacsclient")

;;; :lang clojure
(after! cider
  (set-popup-rules!
    '(("^\\*cider-error*" :ignore t)
      ("^\\*cider-repl" :quit nil)
      ("^\\*cider-repl-history" :vslot 2 :ttl nil))))

;;; :lang ledger
(add-to-list 'auto-mode-alist '("\\.\\(h?ledger\\|journal\\|j\\)$" . ledger-mode))

;;; :lang org
(setq org-directory "~/sync/org/"
      org-archive-location (concat org-directory "archive/%s::")
      org-roam-directory (concat org-directory "roam/")
      org-startup-folded 'overview
      org-ellipsis " [...] "
      org-export-with-toc nil
      org-log-done 'time
      +org-roam-open-buffer-on-find-file nil
      org-attach-id-dir (concat org-roam-directory "data/")
      ;; Fix org-id on SPC-l-s
      ;; org-id-link-to-org-use-id 'use-existing
      org-deadline-warning-days 5)

(use-package! org-roam
  :init
  (map! :leader
        (:prefix "n"
         (:prefix ("r" . "roam")
          :desc "org-roam" "l" #'org-roam-buffer-toggle
          :desc "org-roam-node-insert" "i" #'org-roam-node-insert
          :desc "org-roam-node-find" "f" #'org-roam-node-find
          :desc "org-roam-ref-find" "r" #'org-roam-ref-find
          :desc "org-roam-show-graph" "g" #'org-roam-show-graph
          :desc "org-roam-capture" "c" #'org-roam-capture
          :desc "org-roam-dailies-capture-today" "j" #'org-roam-dailies-capture-today)))
  (setq org-roam-db-gc-threshold most-positive-fixnum
        org-id-link-to-org-use-id t)
  (add-to-list 'display-buffer-alist
               '(("\\*org-roam\\*"
                  (display-buffer-in-direction)
                  (direction . right)
                  (window-width . 0.33)
                  (window-height . fit-window-to-buffer))))
  :config
  (setq org-roam-mode-sections
        (list #'org-roam-backlinks-insert-section
              #'org-roam-reflinks-insert-section))
  ;; #'org-roam-unlinked-references-insert-section

  (org-roam-setup)
  (setq org-roam-capture-templates
        '((:key "d"
           :desc "default"
           :body ""
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :immediate-finish t
           :unnarrowed t)))
  (setq org-roam-capture-ref-templates
        '((:key "r"
           :desc "ref"
           :body "%?"
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n")
           :unnarrowed t)))
  (add-to-list 'org-capture-templates `("c" "org-protocol-capture" entry (file+olp ,(expand-file-name "reading_and_writing_inbox.org" org-roam-directory) "The List")
                                        "* TO-READ [[%:link][%:description]] %^g"
                                        :immediate-finish t))
  (add-to-list 'org-agenda-custom-commands `("r" "Reading"
                                             ((todo "WRITING"
                                                    ((org-agenda-overriding-header "Writing")
                                                     (org-agenda-files '(,(expand-file-name "reading_and_writing_inbox.org" org-roam-directory)))))
                                              (todo "READING"
                                                    ((org-agenda-overriding-header "Reading")
                                                     (org-agenda-files '(,(expand-file-name "reading_and_writing_inbox.org" org-roam-directory)))))
                                              (todo "TO-READ"
                                                    ((org-agenda-overriding-header "To Read")
                                                     (org-agenda-files '(,(expand-file-name "reading_and_writing_inbox.org" org-roam-directory))))))))
  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '((:key "d"
           :desc "default"
           :body "* %?"
           :if-new (file+head "daily/%<%Y-%m-%d>.org"
                              "#+title: %<%Y-%m-%d>\n"))))
  (set-company-backend! 'org-mode '(company-capf)))

(use-package! org-roam-protocol
  :after org-protocol)

(defvar org-contacts-files '("~/sync/org/contacts.org"))

(after! org
  (setq org-capture-templates
        (append
         ;; TODO generalize these with org-directory
         '(("a" "Appointment" entry (file  "~/sync/org/schedule.org")
            "* %?\n\n%^T\n\n:PROPERTIES:\n\n:END:\n\n")
           ("e" "Lab Entry" entry
            (file+olp+datetree "~/sync/org/roam/lab/2021.org")
            "* %U %?\n%i\n%a")
           ("l" "Link" entry (file+headline "~/sync/org/links.org" "Links")
            "* %a %^g\n %?\n %i" :immediate-finish t))
         org-capture-templates)))



;; To make `org-latex-preview` work
(after! org
  (setq org-latex-default-packages-alist
        '(("AUTO" "inputenc" t
           ("pdflatex"))
          ("T1" "fontenc" t
           ("pdflatex"))
          ("" "graphicx" t)
          ("" "grffile" nil)
          ("" "longtable" nil)
          ("" "wrapfig" nil)
          ("" "rotating" nil)
          ("normalem" "ulem" t)
          ("" "amsmath" t)
          ("" "textcomp" t)
          ("" "amssymb" t)
          ("" "capt-of" nil)
          ("" "hyperref" nil))))


;; I like to cross things off my todo list
(custom-set-faces! '(org-headline-done :strike-through t))

;; Start in insert mode in org-capture
(add-hook 'org-capture-mode-hook 'evil-insert-state)

;; +journal
(after! org
  (setq org-journal-dir (concat org-roam-directory "journal/")
        org-journal-encrypt-journal t
        org-journal-file-format "%Y%m%d.org"))

;; +noter
(after! org-noter
  (setq org-noter-always-create-frame t
        org-noter-doc-split-fraction '(0.75 . 0.25)
        org-noter-separate-notes-from-heading t
        org-noter-default-heading-title "Page $p$"
        org-noter-auto-save-last-location t
        org-noter-notes-search-path '("~/sync/org/roam/lit/")
        org-noter-separate-notes-from-heading t
        org-noter-doc-property-in-notes t))

(after! org
  (setq org-beamer-theme "[progressbar=foot]metropolis"
        org-beamer-frame-level 2))


;;; :lang rust
(setq rustic-lsp-server 'rust-analyzer)

;;; :lang solidity
(setq flycheck-solidity-solium-soliumrcfile "/home/emiller/sync/.soliumrc.json"
      solidity-flycheck-solc-checker-active t)

;;; :lang web
;; Hook into vue-lsp
(add-hook 'web-mode-local-vars-hook #'lsp!)

;;; :email mu4e
;; Each path is relative to `+mu4e-mu4e-mail-path', which is ~/.mail by default
(after! mu4e
  (setq shr-use-colors nil)
  (set-email-account! "Gmail"
                      '((mu4e-sent-folder       . "/Gmail/[Gmail]/Sent Mail")
                        (mu4e-drafts-folder     . "/Gmail/[Gmail]/Drafts")
                        (mu4e-trash-folder      . "/Gmail/[Gmail]/Trash")
                        (mu4e-refile-folder     . "/Gmail/[Gmail]/Archive")
                        (smtpmail-smtp-user     . "edmund.a.miller@gmail.com")
                        (mu4e-compose-signature . "---\nEdmund Miller"))
                      t)

  (set-email-account! "Eman"
                      '((mu4e-sent-folder       . "/Eman/[Gmail]/Sent Mail")
                        (mu4e-drafts-folder     . "/Eman/[Gmail]/Drafts")
                        (mu4e-trash-folder      . "/Eman/[Gmail]/Trash")
                        (mu4e-refile-folder     . "/Eman/[Gmail]/Archive")
                        (mu4e-compose-signature . "---\nEdmund Miller"))
                      t)

  (set-email-account! "UTD"
                      '((mu4e-sent-folder       . "/UTD/Sent")
                        (mu4e-drafts-folder     . "/UTD/Drafts")
                        (mu4e-trash-folder      . "/UTD/Trash")
                        (mu4e-refile-folder     . "/UTD/Archive")
                        (smtpmail-smtp-user     . "Edmund.Miller@utdallas.edu")
                        (mu4e-compose-signature . "---\nEdmund Miller"))
                      t))

(use-package! mu4e-patch
  :hook (mu4e-view-mode . mu4e-patch-highlight))

;;; :app calendar
(use-package! org-gcal
  :config
  (setq org-gcal-client-id "119671856150-j6j4b8hjm1k8d1v2ar39c2g1ifdv8iq9.apps.googleusercontent.com"
        org-gcal-client-secret "KOa_aQ-SsyNkK_K4Y5ePk-k1"
        ;; TODO Generalize
        org-gcal-file-alist '(("Edmund.a.miller@gmail.com" .  "~/sync/org/schedule.org"))))

;;; :app irc
(after! circe
  (set-irc-server! "chat.freenode.net"
                   `(:tls t
                     :port 6697
                     :nick "emiller88"
                     :sasl-username ,(+pass-get-user "irc/freenode.net")
                     :sasl-password (lambda (&rest _) (+pass-get-secret "irc/freenode.net"))
                     :channels ("#bioinformatics" "#clojure" "#emacs" "#emacs-circe" "#guix" "#guile" "#home-manager" "#nixos" "#nixos-emacs" "#sway" "##rust" "#python" "#pine64"))))
;;; :app rss
(after! elfeed-search
  (map! :map elfeed-search-mode-map
        :localleader
        :n "m" #'my/elfeed-search-view-hydra/body
        :n "s" #'elfeed-toggle-star
        :n "v" #'elfeed-view-mpv
        :n "r" #'elfeed-update))
;; Set max width
(after! elfeed
  (setq elfeed-search-title-max-width 120))


;;
;;; Language customizations

(custom-theme-set-faces! 'doom-dracula
  `(markdown-code-face :background ,(doom-darken 'bg 0.075))
  `(font-lock-variable-name-face :foreground ,(doom-lighten 'magenta 0.6)))


;;
;;; Packages

(use-package! graphviz-dot-mode)
(use-package! jest)
(use-package! nextflow-mode
  :config
  (set-docsets! 'nextflow-mode "Groovy"))
(use-package! org-chef)
(use-package! academic-phrases)
(use-package! ox-awesomecv
  :init (require 'ox-awesomecv))
(use-package! bibtex-actions
  :after embark
  :config
  (setf (alist-get 'bibtex embark-keymap-alist) 'bibtex-actions-map))

;;
;;; Custom Variables
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(safe-local-variable-values
   '((ssh-deploy-async-with-threads . 1)
     (ssh-deploy-on-explicity-save . t)
     (ssh-deploy-async . 1))))

(setq enable-local-variables :all)
