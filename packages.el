;;; packages.el --- description -*- lexical-binding: t; -*-

;; Private
(package! tao-theme)
(package! color-identifiers-mode)

(unpin! doom-themes)

(package! org-roam
  :recipe (:host github :repo "org-roam/org-roam" :branch "v2")
  :pin "eef1ed287349122e92d965318a0849f650490a36")
(package! edit-server)
;; (package! package-lint)
(package! graphviz-dot-mode)
(package! jest)
(package! nextflow-mode :recipe (:local-repo "~/src/emacs/nextflow-mode" :build (:not compile)))
;; Experimental
(package! academic-phrases)
(package! mu4e-conversation)
(package! mu4e-patch :recipe (:host github :repo "seanfarley/mu4e-patch"))
(package! org-chef)
(package! ox-awesomecv :recipe (:host gitlab :repo "zzamboni/org-cv" :branch "awesomecv"))
(package! bibtex-actions
  :recipe (:host github :repo "bdarcus/bibtex-actions"))

(package! speed-type)

(provide 'packages)
;;; packages.el ends here
