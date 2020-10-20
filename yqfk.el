;;; emacs-yqfk --- A command to fill the forms of dgut yqfk with ease.

;;; Code:
(require 'request)
(require 'url-cookie)

(setq yqfk-oauth-url
      "https://cas.dgut.edu.cn/home/Oauth/getToken/appid/illnessProtectionHome/state/home.html")
(setq cas-cookie-url "cas.dgut.edu.cn")
(setq yqfk-url "http://yqfk.dgut.edu.cn/auth/auth/login")
(setq yqfk-cookie-url "yqfk.dgut.edu.cn")
(setq yqfk-cookie-str "")
(setq yqfk-username nil)
(setq yqfk-password nil)
(setq basic-info-url "http://yqfk.dgut.edu.cn/home/base_info/getBaseInfo")
(setq yqfk-submit-url "http://yqfk.dgut.edu.cn/home/base_info/addBaseInfo")

;; Generated from sameKeys.js
(setq yqfk-exclude-keys '(id username name class_id class_name faculty_id
                             faculty_name jihuan huji family_address
                             current_area family_health_situation have_take_bus
                             family_is_specific_people have_gone_hubei
                             create_time current_country current_province
                             current_city current_district connect_card_type
                             connect_card_number huji_district jiguan_district
                             family_district connect_person_2
                             connect_card_type_2 connect_card_number_2
                             connect_tel_2 continue_days can_submit whitelist
                             msg importantAreaMsg))

;; Set the backend to url-retrieve because curl backend doesn't seem to have the
;; ability to delete cookies.
(setq request-backend 'url-retrieve)
(url-cookie-delete-cookies cas-cookie-url)
(request-cookie-string cas-cookie-url "/")

(defun yqfk-submit () "Start the yqfk submit procedure."
       (interactive)
       (setq yqfk-username (read-string "yqfk username: "))
       (setq yqfk-password (read-passwd "yqfk password: "))
       (request
         yqfk-oauth-url
         :type "GET"
         :parser (lambda() (buffer-string))
         :encoding 'utf-8
         :success (cl-function
                   (lambda (&key data &allow-other-keys)
                     (setq yqfk-cookie-str (request-cookie-string cas-cookie-url "/"))
                     (fetch-login-token data)))))

(defun fetch-login-token (data) "Fetch token from DATA."
       (setq key "var token = ")
       (setq token-len 34)
       (setq token-pos (string-match key data))
       (setq token (substring data (+ token-pos (length key))  (+ (+ token-pos
                                                                     (length key)) token-len)))
       (setq token (substring token 1 -1))
       (perform-cas-login token))

(defun perform-cas-login (token) "Perform login with TOKEN."
       (message "Token received: %S. Logging in" token)
       (request
         yqfk-oauth-url
         :type "POST"
         :data `(("username" . ,yqfk-username)
                 ("password" . ,yqfk-password)
                 ("__token__" . ,token)
                 ("wechat_verify" . ""))
         :parser (lambda () (buffer-string))
         :headers `(("Cookie" . ,(concat "languageIndex=0; " yqfk-cookie-str))
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
                     (setq yqfk-cookie-str (request-cookie-string yqfk-cookie-url
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
                     (setq basic-info (assoc 'info (json-read-from-string
                                                    decoded-data)))
                     (loop for key in yqfk-exclude-keys
                           do (assoc-delete-all key basic-info))
                     (submit-yqfk basic-info bearer)))))

(defun submit-yqfk (data bearer)
  "Submit to yqfk system with DATA.  BEARER is needed to authenticate."
  (message "Submitting to yqfk")
  (setq yqfk-submit-data (json-encode (cdr data)))
  (screen-dump (concat yqfk-submit-data "\n" bearer))
  (request
    yqfk-submit-url
    :type "POST"
    :headers `(("Authorization" . ,(concat "Bearer " bearer))
               ("Content-Type" . "application/json; charset=utf-8"))
    :data (encode-coding-string yqfk-submit-data 'utf-8)
    :parser '(lambda () (buffer-string))
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "SUCCESS! And the data is: %S" (decode-coding-string
                                                         data 'utf-8))))))

(defun screen-dump (msg) "Dump MSG to a new buffer."
       (setq temp-buffer (get-buffer-create "temp"))
       (switch-to-buffer temp-buffer)
       (insert msg))

(request-response-url r)
(provide 'init)
;;; init.el ends here
