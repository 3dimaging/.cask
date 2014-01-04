;;; cask-steps.el --- Cask: Step definitions for Ecukes tests  -*- lexical-binding: t; -*-

;; Copyright (C) 2012, 2013 Johan Andersson

;; Author: Johan Andersson <johan.rejeep@gmail.com>
;; Maintainer: Johan Andersson <johan.rejeep@gmail.com>
;; URL: http://github.com/cask/cask

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Step definitions for Ecukes integration tests of Cask.

;;; Code:

(defun cask-test/elpa-dir ()
  (f-expand (format ".cask/%s/elpa" emacs-version) cask-current-project))

(defun cask-test/links-dir ()
  (f-expand (format ".cask/%s/links" emacs-version) cask-current-project))

(defun cask-test/create-project-file (filename content)
  (f-write content 'utf-8 (f-expand filename cask-current-project)))

(defun cask-test/template (command)
  (->> command
    (s-replace "{{EMACS-VERSION}}" emacs-version)
    (s-replace "{{EMACS}}" (getenv "EMACS"))
    (s-replace "{{PROJECTS-PATH}}" cask-sandbox-path)
    (s-replace "{{PROJECT-PATH}}" cask-current-project)
    (s-replace "{{LINK-FOO}}" cask-link-foo-path)
    (s-replace "{{LINK-NEW-FOO}}" cask-link-new-foo-path)
    (s-replace "{{LINK-BAR}}" cask-link-bar-path)))

(Given "^this Cask file:$"
  (lambda (content)
    (cask-test/create-project-file "Cask" content)))

(Given "^I create a file called \"\\([^\"]+\\)\" with content:$"
  (lambda (filename content)
    (cask-test/create-project-file filename content)))

(When "^I create a file called \"\\([^\"]+\\)\"$"
  (lambda (filename)
    (f-touch (f-expand filename cask-current-project))))

(And "^I create a directory called \"\\([^\"]+\\)\"$"
  (lambda (dirname)
    (f-mkdir (f-expand dirname cask-current-project))))

(When "^I run cask \"\\([^\"]*\\)\"$"
  (lambda (command)
    ;; Note: Since the Ecukes tests runs with Casks dependencies in
    ;; EMACSLOADPATH, these will also be available in the subprocess
    ;; created here. Removing all Cask dependencies here to solve it.
    (setenv "EMACSLOADPATH" (s-join path-separator (--reject (s-matches? ".cask" it) load-path)))
    (setq command (cask-test/template command))
    (let* ((buffer-name "*cask-output*")
           (buffer
            (progn
              (when (get-buffer buffer-name)
                (kill-buffer buffer-name))
              (get-buffer-create buffer-name)))
           (default-directory
             (if cask-current-project
                 (f-full cask-current-project)
               default-directory))
           (args
            (unless (equal command "")
              (s-split " " command)))
           (exit-code
            (apply
             'call-process
             (append (list cask-bin-command nil buffer nil) args))))
      (with-current-buffer buffer
        (let ((content (buffer-string)))
          (cond ((= exit-code 0)
                 (setq cask-output content))
                (t
                 (setq cask-error content))))))))

(Given "^I create a project called \"\\([^\"]+\\)\"$"
  (lambda (project-name)
    (f-mkdir (f-expand project-name cask-sandbox-path))))

(When "^I go to the project called \"\\([^\"]+\\)\"$"
  (lambda (project-name)
    (setq cask-current-project (f-expand project-name cask-sandbox-path))))

(Then "^I should see command output:$"
  (lambda (output)
    (should (s-contains? (cask-test/template output) cask-output))))

(Then "^I should see command error:$"
  (lambda (output)
    (should (s-contains? (cask-test/template output) cask-error))))

(Then "^I should not see command output:$"
  (lambda (output)
    (should-not (s-contains? (cask-test/template output) cask-output))))

(Then "^I should not see command error:$"
  (lambda (output)
    (should-not (s-contains? (cask-test/template output) cask-error))))

(Then "^I should see usage information$"
  (lambda ()
    (Then
      "I should see command output:"
      "USAGE: cask [COMMAND] [OPTIONS]")))

(Then "^there should exist a file called \"\\([^\"]+\\)\" with this content:$"
  (lambda (filename content)
    (let ((filepath (f-expand filename cask-current-project)))
      (with-temp-buffer
        (insert-file-contents filepath)
        (Then "I should see:" content)))))

(Then "^there should exist a file called \"\\([^\"]+\\)\"$"
  (lambda (filename)
    (should (f-file? (f-expand filename cask-current-project)))))

(Then "^there should not exist a file called \"\\([^\"]+\\)\"$"
  (lambda (filename)
    (should-not (f-file? (f-expand filename cask-current-project)))))

(Then "^there should exist a directory called \"\\([^\"]+\\)\"$"
  (lambda (dirname)
    (should (f-dir? (f-expand dirname cask-current-project)))))

(Then "^there should not exist a directory called \"\\([^\"]+\\)\"$"
  (lambda (dirname)
    (should-not (f-dir? (f-expand dirname cask-current-project)))))

(Then "^there should exist a package directory called \"\\([^\"]+\\)\"$"
  (lambda (dirname)
    (should (f-dir? (f-expand dirname (cask-test/elpa-dir))))))

(Then "^there should not exist a package directory called \"\\([^\"]+\\)\"$"
  (lambda (dirname)
    (should-not (f-dir? (f-expand dirname (cask-test/elpa-dir))))))

(Then "^package directory should not exist$"
  (lambda ()
    (should-not (f-dir? (cask-test/elpa-dir)))))

(When "^I move \"\\([^\"]+\\)\" to \"\\([^\"]+\\)\"$"
  (lambda (from to)
    (let ((default-directory cask-current-project))
      (f-move (cask-test/template from) (cask-test/template to)))))

(Then "^I should see cask version$"
  (lambda ()
    (should (s-matches? "^[0-9]+\.[0-9]+\.[0-9]+\n$" cask-output))))

(Then "^I should see a colon path$"
  (lambda ()
    (should (s-matches? ".:." cask-output))))

(Then "^I should see no cask file error$"
  (lambda ()
    (should (string= cask-error (concat "Cask file does not exist: \"" (f-expand "Cask" cask-current-project) "\"\n")))))

(Then "^I should not see any output$"
  (lambda ()
    (should (and (string= cask-output "")
                 (string= cask-error "")))))

(Then "^package \"\\([^\"]+\\)\" should be linked to \"\\([^\"]+\\)\"$"
  (lambda (name path)
    (should (f-same? (cask-test/template path)
                     (f-expand (concat name "-dev") (cask-test/links-dir))))))

(Then "^package \"\\([^\"]+\\)\" should not be linked$"
  (lambda (name)
    (should-not (f-symlink? (f-expand (concat name "-dev") (cask-test/elpa-dir))))))

(Then "^I should see links:$"
  (lambda (table)
    (let ((head (car table))
          (rows (cdr table))
          (lines (-reject 's-blank? (s-lines cask-output))))
      (-map-indexed
       (lambda (index line)
         (let ((row (nth index rows)))
           (s-matches? (concat (nth 0 row) "\\s-*" (cask-test/template (nth 1 row))) line)))
       lines))))

(provide 'cask-steps)

;;; cask-steps.el ends here
