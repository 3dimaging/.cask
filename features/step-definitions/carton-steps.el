(setq carton-current-project nil)
(setq carton-error nil)
(setq carton-output nil)

(Given "^this Carton file:$"
  (lambda (content)
    (with-temp-buffer
      (insert content)
      (let ((carton-file (expand-file-name "Carton" carton-current-project)))
        (write-file carton-file)))))

(When "^I run carton \"\\([^\"]+\\)\"$"
  (lambda (command)
    (let* ((buffer-output (get-buffer-create "*carton-output*"))
           (buffer-error  (get-buffer-create "*carton-error*"))
           (command
            (format "cd %s && %s %s" carton-current-project carton-bin-command command))
           (exit-code
            (shell-command
             command buffer-output buffer-error)))
      (cond ((= exit-code 0)
             (with-current-buffer buffer-output
               (setq carton-output (buffer-string))))
            (t
             (with-current-buffer buffer-error
               (setq carton-error (buffer-string))))))))

(Given "^I create a project called \"\\([^\"]+\\)\"$"
  (lambda (project-name)
    (let ((project-path (expand-file-name project-name carton-projects-path)))
      (make-directory project-path))))

(When "^I go to the project called \"\\([^\"]+\\)\"$"
  (lambda (project-name)
    (let ((project-path (expand-file-name project-name carton-projects-path)))
      (setq carton-current-project project-path))))

(Then "^I should see command output:$"
  (lambda (output)
    (should (s-contains? output carton-output))))

(Then "^I should see command error:$"
  (lambda (output)
    (should (s-contains? output carton-error))))
