;;; emacs-yqfk --- A command to fill the forms of dgut yqfk with ease.

;;; Code:
(require 'request)
(require 'url-cookie)

(message "Fetching data")

(setq yqfk-oauth-url
      "https://cas.dgut.edu.cn/home/Oauth/getToken/appid/illnessProtectionHome/state/home.html")
(setq cas-cookie-url "cas.dgut.edu.cn")
(setq yqfk-url "http://yqfk.dgut.edu.cn/auth/auth/login")
(setq yqfk-cookie-url "yqfk.dgut.edu.cn")
(setq cookie-str "")
(setq yqfk-username (read-string "yqfk username: "))
(setq yqfk-password (read-passwd "yqfk password: "))
(setq basic-info-url "http://yqfk.dgut.edu.cn/home/base_info/getBaseInfo")

;; Set the backend to url-retrieve because curl backend doesn't seem to have the
;; ability to delete cookies.
(setq request-backend 'url-retrieve)
(url-cookie-delete-cookies cas-cookie-url)
(request-cookie-string cas-cookie-url "/")

(request
  yqfk-oauth-url
  :type "GET"
  :parser (lambda() (buffer-string))
  :encoding 'utf-8
  :success (cl-function
            (lambda (&key data &allow-other-keys)
              (setq cookie-str (request-cookie-string cas-cookie-url "/"))
              (fetch-login-token data))))

(defun fetch-login-token (data) "Fetch token from DATA."
       (interactive)
       (setq key "var token = ")
       (setq token-len 34)
       (setq token-pos (string-match key data))
       (setq token (substring data (+ token-pos (length key))  (+ (+ token-pos
                                                                     (length key)) token-len)))
       (setq token (substring token 1 -1))
       (perform-cas-login token))

(defun perform-cas-login (token) "Perform login with TOKEN."
       (interactive)
       (message "Token received: %S. Logging in" token)
       (request
         yqfk-oauth-url
         :type "POST"
         :data `(("username" . ,yqfk-username)
                 ("password" . ,yqfk-password)
                 ("__token__" . ,token)
                 ("wechat_verify" . ""))
         :parser (lambda () (buffer-string))
         :headers `(("Cookie" . ,(concat "languageIndex=0; " cookie-str))
                    ("User-Agent" . "Mozilla/5.0")
                    ("Accept" . "application/json, text/javascript, */*; q=0.01")
                    ("DNT" . "1")
                    ("Referer"
                     . "https://cas.dgut.edu.cn/home/Oauth/getToken/appid/illnessProtectionHome/state/home.html")
                    ("X-Requested-With" . "XMLHttpRequest")
                    ("Host" . ,cas-cookie-url)
                    ("Origin" . ,(concat "https://" cas-cookie-url))
                    ("Connection" . "keep-alive"))
         :success (cl-function
                   (lambda (&key data &allow-other-keys)
                     (perform-yqfk-login data)))))

(defun perform-yqfk-login (data) "Login to yqfk with token from DATA."
       (setq tokens (split-string data "?"))
       (when (eq (length tokens) 1)
         (debug)
         (throw 'login-error "Unable to login to yqfk. Your credentials might be incorrect"))
       (setq token-raw (nth 1 tokens))
       (setq token (substring token-raw 0 (string-match "\\\\" token-raw)))
       (message "Login successful. Trying to obtain yqfk token")
       (request
         (concat yqfk-url "?" token)
         :type "GET"
         :parser (lambda () (buffer-string))
         :success (cl-function
                   (lambda (&key response &key data &allow-other-keys)
                     (setq bearer (nth 1 (split-string (nth 1 (split-string
                                                               (request-response-url response) "?")) "=")))
                     ;; (setq new-buffer (get-buffer-create "temp"))
                     ;; (switch-to-buffer new-buffer)
                     (fetch-basic-info bearer)
                     (setq cookie-str (request-cookie-string yqfk-cookie-url
                                                             "/"))))))

(defun fetch-basic-info (bearer) "Get basic info with BEARER."
       (request
         basic-info-url
         :type "GET"
         :headers `(("Authorization" . ,(concat "Bearer " bearer)))
         :parser '(lambda () (buffer-string))
         :success (cl-function
                   (lambda (&key data &allow-other-keys)
                     (setq decoded-data (decode-coding-string data 'utf-8))
                     (setq basic-info (json-read-from-string decoded-data))
                     (screen-dump decoded-data)))))

(defun screen-dump (msg) "Dump MSG to a new buffer."
       (setq temp-buffer (get-buffer-create "temp"))
       (switch-to-buffer temp-buffer)
       (insert msg))

(request-response-url r)
(provide 'init)
;;; init.el ends here
