;;; email/mu4e/autoload/email.el -*- lexical-binding: t; -*-

;;;###autodef
(defun set-email-account! (label letvars &optional default-p)
  "Registers an email address for mu4e. The LABEL is a string. LETVARS are a
list of cons cells (VARIABLE . VALUE) -- you may want to modify:

 + `user-full-name' (this or the global `user-full-name' is required)
 + `user-mail-address' (required in mu4e < 1.4)
 + `smtpmail-smtp-user' (required for sending mail from Emacs)

OPTIONAL:
 + `mu4e-sent-folder'
 + `mu4e-drafts-folder'
 + `mu4e-trash-folder'
 + `mu4e-refile-folder'
 + `mu4e-compose-signature'
 + `+mu4e-personal-addresses'

DEFAULT-P is a boolean. If non-nil, it marks that email account as the
default/fallback account."
  (after! mu4e
    (when (version< mu4e-mu-version "1.4")
      (when-let (address (cdr (assq 'user-mail-address letvars)))
        (add-to-list 'mu4e-user-mail-address-list address)))
    (setq mu4e-contexts
          (cl-loop for context in mu4e-contexts
                   unless (string= (mu4e-context-name context) label)
                   collect context))
    (let ((context (make-mu4e-context
                    :name label
                    :enter-func (lambda () (mu4e-message "Switched to %s" label))
                    :leave-func #'mu4e-clear-caches
                    :match-func
                    (lambda (msg)
                      (when msg
                        (string-prefix-p (format "/%s" label)
                                         (mu4e-message-field msg :maildir))))
                    :vars letvars)))
      (push context mu4e-contexts)
      (when default-p
        (setq-default mu4e-context-current context))
      context)))


(defvar +mu4e-workspace-name "*mu4e*"
  "Name of the workspace created by `=mu4e', dedicated to mu4e.")
(defvar +mu4e--old-wconf nil)

(add-hook 'mu4e-main-mode-hook #'+mu4e-init-h)

;;;###autoload
(defun =mu4e ()
  "Start email client."
  (interactive)
  (require 'mu4e)
  (if (featurep! :ui workspaces)
      ;; delete current workspace if empty
      ;; this is useful when mu4e is in the daemon
      ;; as otherwise you can accumulate empty workspaces
      (progn
        (unless (+workspace-buffer-list)
          (+workspace-delete (+workspace-current-name)))
        (+workspace-switch +mu4e-workspace-name t))
    (setq +mu4e--old-wconf (current-window-configuration))
    (delete-other-windows)
    (switch-to-buffer (doom-fallback-buffer)))
  (mu4e~start 'mu4e~main-view)
  ;; (save-selected-window
  ;;   (prolusion-mail-show))
  )

;;;###autoload
(defun +mu4e/compose ()
  "Compose a new email."
  (interactive)
  ;; TODO Interactively select email account
  (call-interactively #'mu4e-compose-new))

;; Icons need a bit of work
;; Spacing needs to be determined and adjucted
;;;###autoload
(defun +mu4e--get-string-width (str)
  "Return the width in pixels of a string in the current
window's default font. If the font is mono-spaced, this
will also be the width of all other printable characters."
  (let ((window (selected-window))
        (remapping face-remapping-alist))
    (with-temp-buffer
      (make-local-variable 'face-remapping-alist)
      (setq face-remapping-alist remapping)
      (set-window-buffer window (current-buffer))
      (insert str)
      (car (window-text-pixel-size)))))

;;;###autoload
(cl-defun +mu4e-normalised-icon (name &key set color height v-adjust)
  "Convert :icon declaration to icon"
  (let* ((icon-set (intern (concat "all-the-icons-" (or set "faicon"))))
         (v-adjust (or v-adjust 0.02))
         (height (or height 0.8))
         (icon (if color
                   (apply icon-set `(,name :face ,(intern (concat "all-the-icons-" color)) :height ,height :v-adjust ,v-adjust))
                 (apply icon-set `(,name  :height ,height :v-adjust ,v-adjust))))
         (icon-width (+mu4e--get-string-width icon))
         (space-width (+mu4e--get-string-width " "))
         (space-factor (- 2 (/ (float icon-width) space-width))))
    (concat (propertize " " 'display `(space . (:width ,space-factor))) icon)))

;; Set up all the fancy icons
;;;###autoload
(defun +mu4e-initialise-icons ()
  (setq mu4e-use-fancy-chars t
        mu4e-headers-draft-mark      (cons "D" (+mu4e-normalised-icon "pencil"))
        mu4e-headers-flagged-mark    (cons "F" (+mu4e-normalised-icon "flag"))
        mu4e-headers-new-mark        (cons "N" (+mu4e-normalised-icon "sync" :set "material" :height 0.8 :v-adjust -0.10))
        mu4e-headers-passed-mark     (cons "P" (+mu4e-normalised-icon "arrow-right"))
        mu4e-headers-replied-mark    (cons "R" (+mu4e-normalised-icon "arrow-right"))
        mu4e-headers-seen-mark       (cons "S" "") ;(+mu4e-normalised-icon "eye" :height 0.6 :v-adjust 0.07 :color "dsilver"))
        mu4e-headers-trashed-mark    (cons "T" (+mu4e-normalised-icon "trash"))
        mu4e-headers-attach-mark     (cons "a" (+mu4e-normalised-icon "file-text-o" :color "silver"))
        mu4e-headers-encrypted-mark  (cons "x" (+mu4e-normalised-icon "lock"))
        mu4e-headers-signed-mark     (cons "s" (+mu4e-normalised-icon "certificate" :height 0.7 :color "dpurple"))
        mu4e-headers-unread-mark     (cons "u" (+mu4e-normalised-icon "eye-slash" :v-adjust 0.05))))

;;;###autoload
(defun +mu4e-colorize-str (str &optional unique herring)
  "Apply a face from `+mu4e-header-colorized-faces' to STR.
If HERRING is set, it will be used to determine the face instead of STR.
Will try to make unique when non-nil UNIQUE,
a quoted symbol for a alist of current strings and faces provided."
  (unless herring
    (setq herring str))
  (put-text-property
   0 (length str)
   'face
   (if (not unique)
       (+mu4e--str-color-face herring str)
     (let ((unique-alist (eval unique)))
       (unless (assoc herring unique-alist)
         (if (> (length unique-alist) (length +mu4e-header-colorized-faces))
             (push (cons herring (+mu4e--str-color-face herring)) unique-alist)
           (let ((offset 0) color color?)
             (while (not color)
               (setq color? (+mu4e--str-color-face herring offset))
               (if (not (rassoc color? unique-alist))
                   (setq color color?)
                 (setq offset (1+ offset))
                 (when (> offset (length +mu4e-header-colorized-faces))
                   (message "Warning: +mu4e-colorize-str was called with non-unique-alist UNIQUE-alist alist.")
                   (setq color (+mu4e--str-color-face herring)))))
             (push (cons herring color) unique-alist)))
         (set unique unique-alist))
       (cdr (assoc herring unique-alist))))
   str)
  str)

;;;###autoload
(defun +mu4e--str-color-face (str &optional offset)
  "Select a face from `+mu4e-header-colorized-faces' based on
STR and any integer OFFSET."
  (let* ((str-sum (apply #'+ (mapcar (lambda (c) (% c 3)) str)))
         (color (nth (% (+ str-sum (if offset offset 0))
                        (length +mu4e-header-colorized-faces))
                     +mu4e-header-colorized-faces)))
    color))

;; Adding emails to the agenda
;; Perfect for when you see an email you want to reply to
;; later, but don't want to forget about
;;;###autoload
(defun +mu4e/refile-msg-to-agenda (arg)
  "Refile a message and add a entry in the agenda file with a
deadline.  Default deadline is today.  With one prefix, deadline
is tomorrow.  With two prefixes, select the deadline."
  (interactive "p")
  (let ((file (car org-agenda-files))
        (sec  "^* Email")
        (msg  (mu4e-message-at-point)))
    (when msg
      ;; put the message in the agenda
      (with-current-buffer (find-file-noselect file)
        (save-excursion
          ;; find header section
          (goto-char (point-min))
          (when (re-search-forward sec nil t)
            (let (org-M-RET-may-split-line
                  (lev (org-outline-level))
                  (folded-p (invisible-p (point-at-eol))))
              ;; place the subheader
              (when folded-p (show-branches))    ; unfold if necessary
              (org-end-of-meta-data) ; skip property drawer
              (org-insert-todo-heading 1)        ; insert a todo heading
              (when (= (org-outline-level) lev)  ; demote if necessary
                (org-do-demote))
              ;; insert message and add deadline
              (insert (concat " Respond to "
                              "[[mu4e:msgid:"
                              (plist-get msg :message-id) "]["
                              (truncate-string-to-width
                               (caar (plist-get msg :from)) 25 nil nil t)
                              " - "
                              (truncate-string-to-width
                               (plist-get msg :subject) 40 nil nil t)
                              "]] "))
              (org-deadline nil
                            (cond ((= arg 1) (format-time-string "%Y-%m-%d"))
                                  ((= arg 4) "+1d")))

              (org-update-parent-todo-statistics)

              ;; refold as necessary
              (if folded-p
                  (progn
                    (org-up-heading-safe)
                    (hide-subtree))
                (hide-entry))))))
      ;; refile the message and update
      ;; (cond ((eq major-mode 'mu4e-view-mode)
      ;;        (mu4e-view-mark-for-refile))
      ;;       ((eq major-mode 'mu4e-headers-mode)
      ;;        (mu4e-headers-mark-for-refile)))
      (message "Refiled \"%s\" and added to the agenda for %s"
               (truncate-string-to-width
                (plist-get msg :subject) 40 nil nil t)
               (cond ((= arg 1) "today")
                     ((= arg 4) "tomorrow")
                     (t         "later"))))))

;;
;; Hooks

(defun +mu4e-init-h ()
  (add-hook 'kill-buffer-hook #'+mu4e-kill-mu4e-h nil t))

(defun +mu4e-kill-mu4e-h ()
  ;; (prolusion-mail-hide)
  (cond
   ((and (featurep! :ui workspaces) (+workspace-exists-p +mu4e-workspace-name))
    (+workspace/delete +mu4e-workspace-name))

   (+mu4e--old-wconf
    (set-window-configuration +mu4e--old-wconf)
    (setq +mu4e--old-wconf nil))))

;;;###autoload
(defun +mu4e-set-from-address-h ()
  "Set the account for composing a message. If a 'To' header is present,
and correspands to an email address, this address will be selected.
Otherwise, the user is prompted for the address they wish to use. Possible
selections come from the mu database or a list of email addresses associated
with the current context."
  (unless (and mu4e-compose-parent-message
               (let ((to (cdr (car (mu4e-message-field mu4e-compose-parent-message :to))))
                     (from (cdr (car (mu4e-message-field mu4e-compose-parent-message :from)))))
                 (if (member to (mu4e-personal-addresses))
                     (setq user-mail-address to)
                   (if (member from (mu4e-personal-addresses))
                       (setq user-mail-address from)
                     nil))))
    (setq user-mail-address
          (completing-read
           "From: "
           (if-let ((context-addresses
                     (when mu4e~context-current
                       (alist-get '+mu4e-personal-addresses (mu4e-context-vars mu4e~context-current)))))
               context-addresses
             (mu4e-personal-addresses))))))